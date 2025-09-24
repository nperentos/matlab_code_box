% This function permutes (i.e. randomizes) the amplitude of the lfp signal
% while preserving the phase (and the amplitude distribution).

function lfp = permute_lfp_amplitude(lfp)
orig_dim = size(lfp);
if orig_dim(2)>orig_dim(1); lfp=transpose(lfp); end;

lfp = fft(lfp); 

lfp=ifft(abs(lfp(randperm(length(lfp)))) .* exp(1i*angle(lfp)),'symmetric'); % I NEED TO CHECK THIS ONE

% Without the symmetric option, it is returning a complex valued signal
% I am not sure which one is the correct, I keep the real values version
% with the symmetric option because the complex values will complicate
% things down the road, but I have to control for this.
if size(lfp)~=orig_dim; lfp = transpose(lfp); end;