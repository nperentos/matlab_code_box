function [ShuffledTimes, Diagnostic] = ShuffleThCycles(T, G, ThPhase, varargin)
%ShuffleThCycle is a function which randomizes theta cycles for a time series (spikes, gamma bursts) preserving original spike theta phases.
%Inidivdual theta cycles are extracted from a hilbert theta phase. Spikes within individual theta cycles are always moved together.
%If provided, shuffle wihtin individual clusters.
%
%USAGE:  [ShuffledTimes, Diagnostic] = ShuffleThCycles(T, G, ThPhase,  <lfpSamplingRate>, <Periods>, <GSubset>, <ShuffleType>, <nShuffles>)
%
%INPUT:
% T  is a vector with timestamps of the events (at the ame sampling rate as ThPhase).
% G  is a vector which says which event is in which group (spike cluster, burst group).
% ThPhase     is a vector with continuous unwraped phase.
% <Periods> is a Nx2 matrix with start/end timestamps of periods, in which shuffling must be done.
% <GSubset> list of groups, events from which must be shuffled. Default=[] (all).
% <nShuffles>  is the number of shuffles. Default=100;
% <ShuffleType> if 1- shift bursts to any theta cycle; if 2 - shift bursts to burst-free cycles.
%                     
%OUTPUT:
% ShuffledTimes   is a matrix where each column is a single-run shuffled event timestamps.
% Diagnostic is a structure with some diagnostic parameters.
%
%EXAMPLE:    [ShuffledTimes, Diagnostic] = ShuffleThCycles(T, G, ThPhase, 1250, Periods, [], 2,  500);
%
% Evgeny Resnik
% version 30.09.2013



if nargin<1
    error(['USAGE:  [ShuffledTimes, Diagnostic] =  ShuffleThCycles(T, G, ThPhase,  <lfpSamplingRate>, <Periods>, <GSubset>, <ShuffleType>, <nShuffles>)'])
end

% Parse input parameters
[ lfpSamplingRate, Periods, GSubset, ShuffleType, nShuffles] = DefaultArgs(varargin,{ 1250,  [], [], 2, 500});


%-----------------------------------------------------------------------------%
%Initialize a vector which says which event is in which group
if isempty(G)
    G = ones(size(T));
end
    

%List of groups, events from which must be shuffled
if isempty(GSubset)
    GSubset = unique(G);
end

%The number of groups, events from which must be shuffled
nSubset = length(GSubset);


%Initialize a string title of the shuffling type (just for typing messages)
switch  ShuffleType
    case 1 %shuffle events to any other available cycles
        ShuffleTitle = 'any cycles';
    case 2 %shuffle events to only cycles without events from the same group
        ShuffleTitle = 'empty cycles only';
    otherwise
        error('Unknown ShuffleType value (must be either 1 or 2) !')
end 


%Initialize output matrix (values for the groups from GSubset will be replaced with shuffled values)
ShuffledTimes = repmat(T, 1, nShuffles);
%ShuffledTimes = zeros( length(T), nShuffles);


%-----------------------------------------------------------------------------%
%Compute a vector of continuous index of the corresponding theta cycle 
[CycleInd CyclePeriods] = CycleIndex(ThPhase, [4 12], lfpSamplingRate, 'trough');

%Unwrapped theta phase
ThPhase2 = unwrap(ThPhase);

%Crear a list of cycles with at least one border in Periods 
%(cycles outside the periods must no be discarded to keep concistency with the cycle index vector) 
%(the condition was relaxed to take into account events from the cycles which only partially lie within Periods)
if ~isempty(Periods)
    ind(:,1) = WithinRanges(CyclePeriods(:,1), Periods);
    ind(:,2) = WithinRanges(CyclePeriods(:,2), Periods);
    InPeriodsCycles = find(sum(ind,2)>0);
    %InPeriodsCycles = find(prod(ind,2)); %cycles with both borders within Periods
    clear ind
else
    InPeriodsCycles = [1:size(CyclePeriods,1)]';
end


%Loop across event subsets
for k=1:nSubset
    SubsetEvt = find(G==GSubset(k));
    %unwrapped phase and cycle index of individual events
    evtcycle  = CycleInd(T(SubsetEvt));
    %create a list of unique original ('source') cycles, e.g. cycles with events
    SourceCycles = unique(evtcycle);
    
    %create a list of unique cycles available for shuffling
    switch  ShuffleType
        case 1 %shuffle events to any other available cycles
            AvailableCycles = InPeriodsCycles;
        case 2 %shuffle events to only cycles without events from the same group
            AvailableCycles = setdiff(InPeriodsCycles, SourceCycles);
    end
    
    %Loop across shuffles
    for n=1:nShuffles
        fprintf('Shuffling (%s), subset-%d / run-%d ...', ShuffleTitle, GSubset(k), n )
        rng('shuffle');
        
        %use random permutation without repeatitions to generate a list of target cycles
        if length(AvailableCycles) < length(SourceCycles)
            Diagnostic.TargetCycleWithEventsFraction(k,n) = (length(SourceCycles)  - length(AvailableCycles))/length(SourceCycles)*100;
            fprintf('\n')
            fprintf('WARNING: Number of source cycles exceeds the number of available cycles!  %1.0f%% of target cycles have events! \n', Diagnostic.TargetCycleWithEventsFraction(k,n)  )
            ind1 = randperm(length(AvailableCycles));
            ind2 = randperm(length(SourceCycles), length(SourceCycles)  - length(AvailableCycles) );
            TargetCycles =  [AvailableCycles(ind1) ; SourceCycles(ind2) ];
        else
            Diagnostic.TargetCycleWithEventsFraction(k,n) = 0;
            ind1 = randperm(length(AvailableCycles), length(SourceCycles));
            TargetCycles = AvailableCycles(ind1);
        end
        clear ind1 ind2
        
        %replace indices of original 'source' cycles with indices of the new 'target' cycles
        evtcycle2 =  replace(evtcycle, SourceCycles, TargetCycles);
        %phase values for events in [-pi pi]
        evtphase = ThPhase(T(SubsetEvt));
        %new phases of the shuffled events = original phases + unwrapped phase accumulated to the beginning of the corresponding new cycle
        evtphase2 = evtphase + ThPhase2(CyclePeriods(evtcycle2, 1));
        %calculate new timestamps of shuffled events using new phase values
        T2 = nearestpoint(evtphase2 , ThPhase2);
        ShuffledTimes(SubsetEvt,n)  = T2;
        
        %----------------------- Keep some diagnostic parameters -------------------------------%
        %Check that old and new phase values of the events are same (using timestamps)
        clear ph nOutliers
        ph(:,1)  = ThPhase(T(SubsetEvt));
        ph(:,2)  = ThPhase(T2);        
        Diagnostic.PhaseDiffPercentileFormat = '[Subset x ShuffleRun x [Percentile25 Percentile50 Percentile75]]';
        Diagnostic.PhaseDiffPercentile(k,n,:) = prctile( diff(ph,1,2), [25 50 75] );        
        %Check that new timestamps lie within the new cycle periods
        for t=1:length(T2)
            if T(SubsetEvt(t)) < CyclePeriods( CycleInd(T(SubsetEvt(t))) ,1)   |    T(SubsetEvt(t)) > CyclePeriods( CycleInd(T(SubsetEvt(t))) ,2)
                fprintf('OUTSIDE ORIGINAL PERIOD: Event=%d, Time=%d, CycleIndex=%d, CyclePeriod=[%d %d], ThPh=%1.2f \n', ...
                    SubsetEvt(t), T(SubsetEvt(t)) ,  CycleInd(T(SubsetEvt(t))) , CyclePeriods( CycleInd(T(SubsetEvt(t))) ,:) , ThPhase(T(SubsetEvt(t)))  )
                Diagnostic.OldTimeOutOfCycleIndex = SubsetEvt(t);
            end
            if T2(t) < CyclePeriods( CycleInd(T2(t)) ,1)   |    T2(t) > CyclePeriods( CycleInd(T2(t)) ,2)
                fprintf('OUTSIDE NEW PERIOD: Event=%d, Time=%d, CycleIndex=%d, CyclePeriod=[%d %d], ThPh=%1.2f \n', ...
                    SubsetEvt(t), T2(t) ,  CycleInd(T2(t)) , CyclePeriods( CycleInd(T2(t)) ,:) , ThPhase(T2(t))  )
                Diagnostic.NewTimeOutOfCycleIndex = SubsetEvt(t);
            end
        end
        %Type a warning message
        nOutliers = sum(diff(ph,1,2)<-1);
        if  Diagnostic.PhaseDiffPercentile(k,n,2)> 0.05; error('Mean difference between old and new phases > 0.05!'); end
        if nOutliers/length(T2)> 0.02; 
            error(sprintf('The fraction of events with too large difference between old and new phases = %1.2f !', nOutliers/length(T2) )); 
        end        
        clear  ph nOutliers t
        %------------------------------------------------------------------------------%
        
        clear  evtphase2 evtcycle2  TargetCycles  T2
        fprintf('DONE\n')
    end %loop nShuffles
    
    clear SubsetEvt AvailableCycles evtphase evtcycle SourceCycles
end %loop across subsets



%------------------- OPTIONAL -----------------------------------------------------%
% %Add new parameters before saving into a file
% clear Params
% Params.ScriptName = mfilename;
% Params.PeriodTitle  = PeriodTitle;
% Params.ShuffleType  = ShuffleType;
% Params.nShuffles  = nShuffles;
% Params.GSubset  = GSubset;
% Params.G  = G;
% 
% %Save data into a file
% FileOut = sprintf(['%s.%s.%s.mat'], FileBase, mfilename, PeriodTitle);
% fprintf(['Saving shuffled timestamps of events into a file %s ...'], FileOut)
% save(FileOut,'ShuffledTimes', 'Params', 'Diagnostic', '-v7.3');
% fprintf('DONE\n')






%------------------------- Plot diagnostic figure ------------------------------------------%

% %1. Distribution of theta phase deviations
% ph0 = repmat(ThPhase(T), 1, nShuffles);
% ph1 = ThPhase(ShuffledTimes);
% PhaseDiff = abs(ph0-ph1);
% PhaseDiff = PhaseDiff(:);
% %downsample to speed up
% PhaseDiff2 = PhaseDiff(1:100:end);
% 
% hist(PhaseDiff,100)
% 
% clear b MeanDeviation nOutliers
% b(:,1)  = ThPhase(T(SubsetEvt));
% b(:,2)  = ThPhase(T2);
% MeanDeviation = median( diff(b,1,2) );
% nOutliers = sum(diff(b,1,2)<-1);
% %figure; subplot(221); hist(diff(b,1,2),100)
% if MeanDeviation> 0.05; error('Mean deviation between old and new phases > 0.05!'); end
% if nOutliers/length(T2)> 0.01; error('The fraction of events with too large difference between old and new phases > 1%!'); end



% mfilename = 'ShuffleThCycles';
% FileBase = 'ER02-20110901';
% SignalTypeLFP = 'lfpinterp';
% SignalTypeCSD = 'csdsm5';
% PeriodTitle = 'RUNTHETA';
% ThChan = LoadMyPar(FileBase, 'CA1pyrChannel');
% ProbeTitle = 'Buz32';
% lfpSamplingRate = 1250;
% 
% %Load gamma burst refined timestamps (with LFP-refined burst times!)
% InputTimeFile = sprintf(['%s.%s.%s.%s.%s'], FileBase, 'GammaBurstSpan3', SignalTypeLFP, PeriodTitle, ProbeTitle);
% fprintf(['Loading refined burst timestamps from %s.mat ...'], InputTimeFile)
% load([InputTimeFile '.mat'], 'RefinedBurstTime');
% BurstTime = RefinedBurstTime; clear RefinedBurstTime
% fprintf('DONE\n')
% %Convert burst times from sec to lfp samples
% BurstTime = round(BurstTime*lfpSamplingRate);
% T=BurstTime; clear BurstTime
% 
% %Load indices of bursts from different groups
% InputGroupFile = sprintf(['%s.%s.%s.%s.%s.%s'], FileBase, 'SortBurstsIntoGroups', SignalTypeLFP, SignalTypeCSD, PeriodTitle, ProbeTitle);
% fprintf(['Loading indices of bursts from different freq/phase groups from %s.mat ...'], InputGroupFile)
% load([InputGroupFile '.mat'],'BurstGroup');
% fprintf('DONE\n')
% 
% 
% %Load hilbert theta phase on CA1 pyr channel
% InputPhFile = sprintf(['%s.thpar'], FileBase);
% fprintf(['Loading theta phase on CA1pyr channel from %s.mat ...'], InputPhFile)
% load([InputPhFile '.mat'], 'ThPh','Params');
% if Params.Channel~=ThChan
%     error(sprintf('Theta phase from %s was computed for a different channel!', InputPhFile))
% end
% ThPhase=ThPh; clear ThPh
% fprintf('DONE\n')
% 
% % %Load LFP for the entire signal for the selected channels
% % fprintf(['Loading %s for channel-%1.0d ...'], upper(SignalType),  ThChan  )
% % lfp = LoadBinary([FileBase '.' SignalTypeLFP], ThChan)';
% % fprintf('DONE\n')
% 
% %Load theta periods
% Periods = loadrangefiles([FileBase '.sts.' PeriodTitle]);
% 
% 
% %Create a vector, which says which burst is in which group
% nGr = length(BurstGroup);
% G = ones(size(T)) * (nGr+1);
% for g=1:nGr
%     G( BurstGroup(g).Index ) = g;
% end
% clear g
% 
% GSubset = [];
% nShuffles = 500;
% ShuffleType=2;


