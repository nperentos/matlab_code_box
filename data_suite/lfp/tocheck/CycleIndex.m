function [Index, Periods] = CycleIndex(phase, FreqRange, SamplingRate, CycleType)
%CycleIndex is a function which takes a vector with continuous unwrapped phase of a signal and
%calculates a vector with the corresponding  cycle indices (period number).
%Note: Zero phase values corresponds to signal peaks, while -pi/pi values - signal troughs.
%Hence, by default, the function returns indices and periods of cycles
%containing signal peaks. If cycles containing signal trough are needed,
%shift phase values into [0 2pi] range by ph=mod(ph, 2*pi).
%
%USAGE:   [Index, Periods] = CycleIndex(phase, FreqRange, SamplingRate, CycleType)
%
%INPUT:
% Phase         is a vector with continuous (hilbert) unwrapped phase of a signal.
% FreqRange  is a frequency range of the oscillation which cycles must be detected (Hz).
% SamplingRate  is the sampling rate of the phase vector (Hz).
% CycleType is a string with a type of the cycles to be detected ('peak' - cycles containing signal peaks; 'trough' - cycles containing signal troughs).
%
%EXAMPLE:    [ThCycleIndex, ThCyclePeriods] = CycleIndex(ThPh, [4 12], 1250, 'trough'')
%
% Evgeny Resnik
% version 02.10.2013




if nargin<2
    error(['USAGE:  [Index, Periods] = CycleIndex(phase, FreqRange, SamplingRate, CycleType)' ])
end

switch lower(CycleType)
    case 'peak'
        %do nothing.
    case 'trough'
        phase = mod(phase, 2*pi);
    otherwise
        error('CycleType must be either "peak" or "trough".')
end


%Detect mins in the first derivative of phase
dph = diff(phase);
LessThan = 0.9*min(dph);
NotCloserThan = round(1/max(FreqRange)*SamplingRate*1.1);
mins = LocalMinima(dph, NotCloserThan, LessThan) +1;


%Calculate a vector with markers showing to which theta cycle belongs a given sample (for further analysis)
Index = zeros(size(phase),'single');
%all samples before the first detected phase minimum - mark as the first cycle
Index(1:mins(1)-1) = 1;
%mark all intermediate cycles
for c=1:length(mins)-1
    Index([mins(c) : mins(c+1)-1]) = c+1;
end
%all samples after the last detected phase minimum - mark as the last cycle
Index(mins(end):end) = length(mins)+1;


if nargout>1
    %Convert a vector with times of consecutive peaks into Nx2 matrix of time ranges of individual cycles
    Periods(:,1) = [1; mins(1:end-1)];
    Periods(:,2) = mins-1;
end



%DEBUGGING PLOT
% figure;
% cla
% id = 1:SamplingRate*3;
% plot(id, phase(id),'k');
% axis tight; hold on
% % plot(id, Index(id),'r');
% id2 = Periods(:,1)>=id(1) & Periods(:,1)<=id(end);
% Lines(Periods(id2,1), ylim, 'b');
% Lines(Periods(id2,2), ylim, 'r');
% ylim([-5 5])





