% Continuous wavelet transform. 
% Wavelets (hanning-windowed complex sinusoids) 

% The output is the continuous wavelet transform, a matrix of complex
% numbers at each frequency f and timepoint t, whose angle represents the
% phase and whose length represents power at that frequency. 

% The wavelets at different frequencies are aligned at their centers. Thus,
% for example, if q = 2 and fs=1000, the cwt at 1Hz will give the spectral
% estimate for a time period +/- 1s around each point, at 2Hz +/- 0.5s ...

% Author : Nikolas Karalis
% Date : 27/11/2013
%
% Updates :

function [S,t,freqs]=lfp_wavelet(lfp,samplingfrequency,q,freqs)

S=nan(length(freqs),length(lfp));%create a matrix to hold the cwt

lfp=lfp(:)';

% For all frequencies
for n = 1:length(freqs)
    timewidth= q/freqs(n); %kernel timewidth
    t=[0:1/samplingfrequency:timewidth];
    wavelet=exp(2*i*pi*t*freqs(n)).*hann(length(t))';%hann-windowed wavelet
    if(length(wavelet)<length(lfp))  
    start=round(length(wavelet)/2);%align windows at different frequencies to their center
    S_f=conv2(lfp,wavelet,'valid');%calculate cwt at frequency f
    S(n,start:start+length(S_f)-1)=S_f/length(wavelet);%scale by wavelet length and add to cwt matrix
    end
end

    