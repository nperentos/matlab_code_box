% Takes as input peaks of a signal and returns a phase interpolated signal.
% The peaks are -pi... that is a problem - NEED TO FIX
function out = phase_from_peaks(peaks,sig)
%%
tmp = cell2mat(arrayfun(@(x) linspace(-pi,pi,x)', diff(peaks),'un',0))';
out = nan(size(sig));
out(min(peaks):max(peaks)-1) = tmp;
