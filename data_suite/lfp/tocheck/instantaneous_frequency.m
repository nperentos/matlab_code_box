% If the input is matrix, it should be given in a way that the lfp is in
% the columns and trials are in rows.
% If smoothing option is enabled and set to a number of points, a Savitzky-Golay filter of that many points is used to smooth
% the unwrapped phase angle.
%
% Reference : Synchronization, 2003, Arkady Pikovsky, Appendix A

function [freq] = instantaneous_frequency(lfp,smoothing)

if nargin<2; smoothing = 0; end;

if smoothing>0
    % Need to fix this part
    angles = unwrap(angle(hilbert(lfp)));
    freq=diff(sgolayfilt(angles,4,smoothing));
else
    freq = diff(unwrap(angle(hilbert(lfp))));
end;