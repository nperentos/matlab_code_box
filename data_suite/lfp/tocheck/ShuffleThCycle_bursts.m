function out = ShuffleThCycle_bursts(T, ThPhase, varargin)
%ShuffleThCycle is a function which randomizes theta cycles for a time series (spikes, gamma bursts) preserving original spike theta phases.
%Inidivdual theta cycles are extracted from a hilbert theta phase. Spikes within individual theta cycles are always moved together.
%If provided, shuffle wihtin individual clusters.
%
%USAGE:  out = ShuffleThCycle_bursts(T, G, ThPhase, <Periods>, <GSubset>, <ShuffleType>, <nShuffles>)
%
%INPUT:
% T  is a vector with timestamps of the events (at the ame sampling rate as ThPhase).
% G  is a vector which says which event is in which group (spike cluster, burst group).
% ThPhase     is a vector with continuous unwraped phase.
% <Periods> is a Nx2 matrix with start/end timestamps of periods, in which shuffling must be done.
% <GSubset> list of groups, event from which must be shuffled. Default=[] (all).
% <ShuffleType> if 1- shift spikes to any theta cycle; if 2 - shift spikes to spike-free cycles
% <nShuffles>  is the number of shuffles. Default=100;
%                     
%OUTPUT:
% out   is a matrix where each column is a single-run shuffled event timestamps.
%
%EXAMPLE:   out = ShuffleThCycle(spk.Tlfp, ThPh, Periods, spk.clust, [2 5],  1, 5);
%
% Evgeny Resnik
% version 30.09.2013


FileBase = 'ER02-20110901';
SignalTypeLFP = 'lfpinterp';
SignalTypeCSD = 'csdsm5';
PeriodTitle = 'RUNTHETA';
ThChan = LoadMyPar(FileBase, 'CA1pyrChannel');
ProbeTitle = 'Buz32';
lfpSamplingRate = 1250;

%Load gamma burst refined timestamps (with LFP-refined burst times!)
InputTimeFile = sprintf(['%s.%s.%s.%s.%s'], FileBase, 'GammaBurstSpan3', SignalTypeLFP, PeriodTitle, ProbeTitle);
fprintf(['Loading refined burst timestamps from %s.mat ...'], InputTimeFile)
load([InputTimeFile '.mat'], 'RefinedBurstTime', 'Params');
BurstTime = RefinedBurstTime; clear RefinedBurstTime
fprintf('DONE\n')
%Convert burst times from sec to lfp samples
BurstTime = round(BurstTime*lfpSamplingRate);
T=BurstTime; clear BurstTime

%Load indices of bursts from different groups
InputGroupFile = sprintf(['%s.%s.%s.%s.%s.%s'], FileBase, 'SortBurstsIntoGroups', SignalTypeLFP, SignalTypeCSD, PeriodTitle, ProbeTitle);
fprintf(['Loading indices of bursts from different freq/phase groups from %s.mat ...'], InputGroupFile)
load([InputGroupFile '.mat'],'BurstGroup');
fprintf('DONE\n')


%Load hilbert theta phase on CA1 pyr channel
InputPhFile = sprintf(['%s.thpar'], FileBase);
fprintf(['Loading theta phase on CA1pyr channel from %s.mat ...'], InputPhFile)
load([InputPhFile '.mat'], 'ThPh','Params');
if Params.Channel~=ThChan
    error(sprintf('Theta phase from %s was computed for a different channel!', InputPhFile))
end
ThPhase=ThPh; clear ThPh
fprintf('DONE\n')

% %Load LFP for the entire signal for the selected channels
% fprintf(['Loading %s for channel-%1.0d ...'], upper(SignalType),  ThChan  )
% lfp = LoadBinary([FileBase '.' SignalTypeLFP], ThChan)';
% fprintf('DONE\n')

%Load theta periods
Periods = loadrangefiles([FileBase '.sts.' PeriodTitle]);


%Create a vector, which says which burst is in which group
nGr = length(BurstGroup);
G = ones(size(BurstTime)) * (nGr+1);
for g=1:nGr
    G( BurstGroup(g).Index ) = g;
end
clear g

GSubset = [];
nShuffles = 1000;
ShuffleType=1;


%------------------------------------------------------------------
if nargin<1
    error(['USAGE:  out =  ShuffleThCycle(T, G, ThPhase, <Periods>, <GSubset>, <ShuffleType>, <nShuffles>)'])
end


% Parse input parameters
[ Periods, G, GSubset, ShuffleType, nShuffles] = DefaultArgs(varargin,{ [], [], [], 1, 100});

if isempty(G)
    G = ones(size(T));
end
    
if isempty(GSubset)
    GSubset = unique(G);
end

%Initialize output matrix (values for clusters from GSubset will be replaced with shuffled values)
out = repmat(T, 1, nShuffles);

%-----------------------------------------------------------------------------%

%Compute for all samples an index of the  corresponding theta cycle 
[CycleInd, CyclePeriods] = CycleIndex(ThPhase, [4 12], lfpSamplingRate, 'trough');


%Unwrapped theta phase
ThPhase2 = unwrap(ThPhase);


%Discard spikes which are not in Periods if provided
if ~isempty(Periods)
    [T, GoodSpks] = SelectPeriods(T, Periods,'d', 1, 0);   
    if ~isempty(G)
        G = G(GoodSpks);
    end
    clear GoodSpks
end


%List of cycles which are in Periods 
if ~isempty(Periods)
    ind(:,1) = WithinRanges(CyclePeriods(:,1), Periods);
    ind(:,2) = WithinRanges(CyclePeriods(:,2), Periods);
    InPeriodsCycles = find(prod(ind,2));
    clear ind1 ind2
else
    InPeriodsCycles = [1:size(CyclePeriods,1)]';
end


%Initialize output matrix (values for clusters from GSubset will be replaced with shuffled values)
out = repmat(T, 1, nShuffles);


%Create a list of target cycles for each original cycle
switch  ShuffleType    
    
    case 1 %----- shuffle spikes to any other cycles ------%           
        AvailableCycles = InPeriodsCycles;
        
        nClust = length(GSubset);
        for k=1:nClust
            ClustSpk = G==GSubset(k);
            %phase/cycle index for individual spikes
            spkphase = ThPhase2(T(ClustSpk));
            spkcycle = CycleInd(T(ClustSpk));
            %create a list of original ('source') cycles, e.g. cycles with spikes
            SourceCycles = unique(spkcycle);
            
            %Multiple shuffling in a loop
            for n=1:nShuffles
                fprintf('Shuffling across spike-free theta cycles, cluster-%d / run-%d ...', GSubset(k), n )
                rng('shuffle')
                %use random permutation with repeatitions to generate a list of target cycles
                ind = randperm(length(AvailableCycles), length(SourceCycles));
                TargetCycles = AvailableCycles(ind);
                clear ind
                
                %indices of target cycles for cluster spikes (different across shuffling trials)
                spkcycle2 = zeros(size(spkcycle));
                for c=1:length(SourceCycles)
                    spkcycle2(spkcycle==SourceCycles(c)) = TargetCycles(c);
                end
                
                %Calculate 'theoretical' new unwrapped phase values for spikes in their target cycles
                % (cycle index difference must be 'double' otherwise mod doesn't work properly!)
                spkphase2 = spkphase+2*pi*double(spkcycle2-spkcycle);
                %find closest actual phase values in ThPhase2 to the theoretically computed ones
                out(ClustSpk,n)  = nearestpoint(spkphase2 , ThPhase2);
                %mod([ThPhase2(T(ClustSpk))    ThPhase2(out(ClustSpk))  ], 2*pi)
                clear c spkcycle2 spkphase2
                fprintf('DONE\n')
            end %loop nShuffles
            clear ClustSpk spkphase spkcycle SourceCycles 
        end %loop across clusters
        
                    
        
    case 2 %----- shuffle spikes to only cycles without spikes ------%         
        nClust = length(GSubset);
        for k=1:nClust
            ClustSpk = G==GSubset(k);
            %original phase/cycle index for cluster spikes
            spkphase = ThPhase2(T(ClustSpk));            
            spkcycle = CycleInd(T(ClustSpk));
            %create a list of original ('source') cycles, e.g. cycles with spikes
            SourceCycles = unique(spkcycle);            
            %create a list of  available cycles, e.g. cycles without spikes of the given cluster
            AvailableCycles = setdiff(InPeriodsCycles, SourceCycles);
            
            %Multiple shuffling in a loop
            for n=1:nShuffles
                fprintf('Shuffling across spike-free theta cycles, cluster-%d / run-%d ...', GSubset(k), n )
                rng('shuffle')
                if length(AvailableCycles) >= length(SourceCycles)
                    %use random permutation without repeatitions to generate a list of target cycles
                    ind = randperm(length(AvailableCycles), length(SourceCycles));
                    TargetCycles = AvailableCycles(ind);
                    clear ind
                else
                    %use a missing fraction of cycles with spikes to generate a list of target cycles
                    fprintf('WARNING: nAvailableCycles < nSourceCycles! %1.0f%% of target cycles had spikes!  ', (length(SourceCycles)  - length(AvailableCycles))/length(SourceCycles)*100   )
                    ind1 = randperm(length(AvailableCycles));
                    ind2 = randperm(length(SourceCycles), length(SourceCycles)  - length(AvailableCycles) );
                    TargetCycles =  [AvailableCycles(ind1) ; SourceCycles(ind2) ];
                    clear ind1 ind2
                end
                
                %indices of target cycles for cluster spikes (different across shuffling trials)
                spkcycle2 = zeros(size(spkcycle));
                for c=1:length(SourceCycles)
                    spkcycle2(spkcycle==SourceCycles(c)) = TargetCycles(c);
                end
                
                %Calculate 'theoretical' new unwrapped phase values for spikes in their target cycles
                % (cycle index difference must be 'double' otherwise mod doesn't work properly!)
                spkphase2 = spkphase+2*pi*double(spkcycle2-spkcycle);
                %find closest actual phase values in ThPhase2 to the theoretically computed ones
                out(ClustSpk,n)  = nearestpoint(spkphase2 , ThPhase2);
                %mod([ThPhase2(T(ClustSpk))    ThPhase2(out(ClustSpk))  ], 2*pi)
                clear c spkcycle2 spkphase2
                fprintf('DONE\n')
            end %loop nShuffles
            clear ClustSpk spkphase spkcycle SourceCycles AvailableCycles             
        end %loop across clusters
        
    otherwise
        error('Unknown ShuffleType value (must be either 1 or 2) !')         
end %ShuffleType




%DEBUGGING PLOT
id = 1:lfpSamplingRate*10;
flfp = ButFilter(lfp(id), 4, [4 12]/lfpSamplingRate*2, 'bandpass');

figure;
cla
% plot(id, ThPhase(id),'k');
% plot(id, lfp(id),'k');
plot(id, flfp,'k');
axis tight; hold on
% plot(id, CycleInd(id),'r');
id2 = find(CyclePeriods(:,1)>=id(1) & CyclePeriods(:,1)<=id(end));
Lines(CyclePeriods(id2,1), ylim, 'r');
% Lines(CyclePeriods(id2,2), ylim, 'r');
% ylim([-5 5])




if nargout==0
    nClust = length(unique(G));
    
    %----------------------------- Plotting settings ----------------------------------------%  
    FntSize = 10;
    sbp =[5 7];
    nSbp = prod(sbp);
    nFig = fix(nClust/nSbp);
    nFigRest = ceil(nClust/nSbp - nFig);
    
    %-----------------------------------------------------------------------------------%
    for p=1:nFig
        hfig(p)=figure('Name',[mfilename ': ' num2str([nSbp*(p-1)+1 nSbp*p])]); orient landscape; redimscreen
        h = tight_subplot(sbp(1), sbp(2),[.05 .02], [.04 .03], [0.03 0.03]);  set(h, 'visible','off')
        for a=1:nSbp
            u = nSbp*(p-1)+a;
            axes(h(a)); set(h(a), 'visible','on'); cla; hold on
            %---------------------------- Plot ----------------------------------------------%
            ClustSpk = G==u;
            nSpikes = sum(ClustSpk);
            if nSpikes~=0
%                 hist(T(ClustSpk), 50);       hist(out(ClustSpk,1), 50);     
                plot(T(ClustSpk), ThPhase(T(ClustSpk)), 'color','k','marker','.','markersize',8,'linestyle','none')
                plot(out(ClustSpk), ThPhase(out(ClustSpk)), 'color','r','marker','x','markersize',5,'linestyle','none')    
                set(gca,'ylim', [-pi pi], 'ytick', [-pi 0 pi], 'yticklabel', {'-pi','0','pi'},'FontSize', FntSize)
                title(sprintf('clust-%1.0f (%1.0d spks)',u, nSpikes), 'FontSize', FntSize);
                clear tmp minmax
            else
                title(sprintf('clust-%1.0f (0 spks)',u),'FontSize', FntSize);
                set(gca,'xtick',[],'ytick',[],'FontSize', FntSize);
            end
            if ismember(a,1:sbp(2):nSbp)  ; ylabel('Theta phase', 'FontSize', FntSize); end
            if ismember(a, nSbp-sbp(2)+1: nSbp)  ; xlabel('Time, (s)', 'FontSize', FntSize); end
            clear ClustSpk nSpikes
        end %loop across units(subplots)
        %---------------------------- Suptitle ---------------------------------------------%
        titlestr{1} = ['Shuffling theta cycles preserving phase' ];
        suptitle2(titlestr, .96)
        clear titlestr nSpikes
    end %loop across figures
    
    
    %-------------------------- Last incomplete figure ------------------------------------%
    if nFigRest~=0
        p=nFig+1;
        hfig(p)=figure('Name',[mfilename ': ' num2str([nSbp*(p-1)+1 nSbp*p])]); orient landscape; redimscreen
        h = tight_subplot(sbp(1), sbp(2),[.05 .02], [.04 .03], [0.03 0.03]); set(h, 'visible','off')
        for a=1:nClust-nSbp*nFig
            u = nSbp*(p-1)+a;
            axes(h(a)); set(h(a), 'visible','on'); hold on
            %---------------------------- Plot ---------------------------------------------%
            ClustSpk = G==u;
            nSpikes = sum(ClustSpk);
            if nSpikes~=0
                plot(T(ClustSpk), ThPhase(T(ClustSpk)), 'color','k','marker','.','markersize',8,'linestyle','none')
                plot(out(ClustSpk), ThPhase(out(ClustSpk)), 'color','r','marker','x','markersize',5,'linestyle','none')
                %                 hist(ThPhase(T(ClustSpk)));    hist(T(ClustSpk));                
                set(gca,'ylim', [-pi pi], 'ytick', [-pi 0 pi], 'yticklabel', {'-pi','0','pi'},'FontSize', FntSize)
                title(sprintf('clust-%1.0f (%1.0d spks)',u, nSpikes), 'FontSize', FntSize);
                clear tmp minmax
            else
                title(sprintf('clust-%1.0f (0 spks)',u),'FontSize', FntSize);
                set(gca,'xtick',[],'ytick',[],'FontSize', FntSize);
            end
            if ismember(a,1:sbp(2):nSbp)  ; ylabel('Theta phase', 'FontSize', FntSize); end
            if ismember(a, nSbp-sbp(2)+1: nSbp)  ; xlabel('Time, (s)', 'FontSize', FntSize); end
        end %loop across units(subplots)
        %---------------------------- Suptitle ---------------------------------------------%
        titlestr{1} = ['Shuffling theta cycles preserving phase' ];
        suptitle2(titlestr, .96)
        clear titlestr
    end %if nFigRest~=0
    
    
    
%     %Save figures into files
%     for p=1:length(hfig)
%         FileOut = sprintf(['%s.%s.%s.%s.%1d-%1d.%d.jpg'], FileBase, mfilename, SignalType , PeriodTitle,  Channels(1),  Channels(end), p);
%         fprintf(['Saving figure into a figure %s ...'], FileOut)
%         figure(hfig(p))
%         print('-djpeg','-r300', FileOut)
%         fprintf('DONE\n')
%     end
    
    % close(hfig)
    
    
    
end


%     %DEBUGGING PLOT within a loop over theta cycles:
%     %old cycle
%     subplot(221); cla; hold on
%     x =  CyclePeriods(SourceCycles(c),1)-10 : CyclePeriods(SourceCycles(c),2) +20;    
%     plot(x, ThPhase(x),'k.-'); axis tight
%     Lines(T(ToShift), ylim,'r');    
%     %new cycle
%     subplot(223); cla; hold on
%     x =  CyclePeriods(TargetCycles(c),1) : CyclePeriods(TargetCycles(c),2) ;    
%     plot(x, ThPhase(x),'k.-'); axis tight
%     Lines(out(ToShift), ylim,'r');
%     clear x     
%     pause; 
