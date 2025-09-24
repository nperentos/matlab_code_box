% Reference : Adhikari, ... , Gordon 
% J Neuroscience Method, 2010

% Nikolas Karalis
function [t,x,inst_amp1,inst_amp2]=find_lfp_lag(lfp1,lfp2,samplingrate, freqband, maxlag)
if nargin<5 || isempty(maxlag); maxlag = 0.1; end;
%inst_amp1 = lfp_envelope(filter_lfp(lfp1,samplingfrequency,freqband));
%inst_amp2 = lfp_envelope(filter_lfp(lfp2,samplingfrequency,freqband));
inst_amp1 = abs(hilbert(filter_lfp(lfp1,samplingrate,freqband)));
inst_amp2 = abs(hilbert(filter_lfp(lfp2,samplingrate,freqband)));

x=xcorr(demean(inst_amp1),demean(inst_amp2),maxlag*samplingrate,'coeff');
[m,idx] = max(x);
t=(idx-(length(x)-1)/2)/samplingrate;
