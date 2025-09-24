function ShuffleBurstThCycles(FileBase, varargin)
%ShuffleBurstThCycles is a function which shuffles timestamps of gamma bursts
%between theta cycles, preserving original theta phases of the bursts.
%This version moves gamma bursts to both empty and gamma-containing new theta
%cycles.
%
%USAGE:  ShuffleBurstThCycles(FileBase, <SignalType>, <PeriodTitle>, <Channels>, <nShuffles>, <ShuffleType>)
%
%INPUT:
% FileBase        is a name of the session (AnimalID-YYYMMDD).
% <SignalType>    is a type of signal used for spectrogram calculation ('lfp' or 'csd'). Default='lfp.'
% <Channels>      is a vector with numbers of channels from Buz32 probe. Default = 65:96.
% <PeriodTitle>   is a name of the behavioral state  in which burst must be detected. Default = 'RUN'
% <nShuffles>     is the number of shuffles. Default=500;
% <ShuffleType>   if 1- shift bursts to any theta cycle; if 2 - shift bursts to burst-free cycles. Default=2;
%                     
%OUTPUT:
%
%EXAMPLE:   ShuffleBurstThCycles(CurrentFileBase, 'lfpinterp', 'RUN', 65:96, 1000)
%           ShuffleBurstThCycles(CurrentFileBase)
%
% Evgeny Resnik
% version 16.01.2014




% FileBase = CurrentFileBase
% Channels = 65:96;
% SignalType = 'lfpinterp';
% PeriodTitle = 'RUN';
% nShuffles = 500;
% ShuffleType = 1;
% mfilename = 'ShuffleBurstThCycles';


if nargin<1
    error(['USAGE:  ShuffleBurstThCycles(FileBase, <SignalType>, <PeriodTitle>, <Channels>, <nShuffles>, <ShuffleType> )'])
end

% Parse input parameters
[SignalType, PeriodTitle, Channels, nShuffles, ShuffleType] = DefaultArgs(varargin,{ 'lfpinterp', 'RUN', [65:96], 1000, 1 });


fprintf('=======================================================================================================\n')
fprintf(['                   %s - %s \n'], FileBase, mfilename )
fprintf('=======================================================================================================\n')


%-----------------------------------------------------------------------------%
%Load gamma burst refined timestamps (with LFP-refined burst times!)
InputTimeFile = sprintf(['%s.%s.%s.%s.%d-%d'], FileBase, 'GammaBurstSpan3', SignalType, PeriodTitle,  Channels([1 end]) );
fprintf(['Loading refined burst timestamps from %s.mat ...'], InputTimeFile)
load([InputTimeFile '.mat'], 'RefinedBurstTime');
BurstTime = RefinedBurstTime; 
clear RefinedBurstTime
fprintf('DONE\n')


%Load hilbert theta phase on CA1 pyr channel
InputPhFile = sprintf('%s.%s', FileBase, 'thpar.mat');
fprintf(['Loading theta phase on CA1pyr channel from %s ...'], InputPhFile)
InputPhFile = ResolvePath(InputPhFile, 0);
load(InputPhFile, 'ThPh', 'Params');
ThPhase = ThPh; 
ThChan = Params.Channel;
clear ThPh Params
fprintf('DONE\n')


%Load start/end timestamps (.lfp samples at 1250Hz) of episodes that must be included/excluded
stsFilesIn = ResolvePath([FileBase '.sts.' PeriodTitle],0);
if exist(stsFilesIn,'file')
    Periods = loadrangefiles(stsFilesIn);
else
    Periods = [];
end

%-----------------------------------------------------------------------------%
%Load LFP sampling rates from .xml file
par = LoadXml([FileBase '.xml']);
nChan = par.nChannels;
lfpSamplingRate = par.lfpSampleRate;


%Convert burst times from sec to lfp samples
BurstTime = round(BurstTime*lfpSamplingRate);

%Shuffle all bursts together (single group)
G = ones(size(BurstTime));


%-----------------------------------------------------------------------------%

%Shuffle theta cycles of gamma bursts within individual groups
[BurstTimeShuffled, Diagnostic] =  ShuffleThCycles(BurstTime, G, ThPhase, lfpSamplingRate, Periods, [], ShuffleType, nShuffles);
% FileIn = sprintf(['%s.%s.%s.%s.%s.%s.mat'], FileBase, 'ShuffleBurstThCycles', SignalType, SignalTypeCSD, PeriodTitle, ProbeTitle);
% load(FileIn,'BurstTimeShuffled', 'Params');


%Convert burst times back from lfp samples to sec
BurstTimeShuffled = BurstTimeShuffled/lfpSamplingRate;


%-----------------------------------------------------------------------------%
%Add new parameters before saving into a file
Params = struct('InputTimeFile', InputTimeFile,  'InputPhFile', InputPhFile, 'SignalTypeLFP',SignalType, ...
    'PeriodTitle', PeriodTitle, 'lfpSamplingRate',lfpSamplingRate, 'Channels',Channels, ...
    'ThChan',ThChan, 'ShuffleType', ShuffleType, 'nShuffles', nShuffles);

%Save data into a file
FileOut = sprintf(['%s.%s.%s.%s.%d-%d.mat'], FileBase, mfilename, SignalType, PeriodTitle, Channels([1 end]) );
fprintf(['Saving data into a file %s ...'], FileOut)
save(FileOut,'BurstTimeShuffled', 'Diagnostic', 'Params', '-v7.3');
fprintf('DONE\n') 






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




