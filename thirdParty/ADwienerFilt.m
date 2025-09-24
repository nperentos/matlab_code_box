
function [xest,W,Nblocks] = ADwienerFilt(x,r,Lw)
%
% Wiener filter based on STFT
%   This function takes as inputs a noisy signal, x, and a reference signal, r,
%   in order to compute a bank of linear filters that provides an estimate of y
%   from x. This kind of Wiener filter based on short-time Fourier
%   transform so it can deal with non-stationary signals.
%
%   Note 1: window length (Lw) must be even
%   Note 2: overlap is fixed at 50%
%   Note 3: the filtered signal can be shortened
%
% INPUTS
% x = noisy signal
% r = reference signal
% Nw = window length
% Nblocks = total number of segments
%
% OUTPUTS
% xest = estimated signal
% W = matrix of Wiener filters
% M. Buzzoni
% Feb 2020
% window length must be even
if mod(Lw,2)~=0
    Lw = Lw - 1;
    disp('Window length must be an even number. Lw has been changed accordingly.')
end
L = length(x);
win = hanning(Lw);
overlap = Lw/2;
Nblocks = floor((L / (Lw/2) ) - 1);
Sxx = zeros(Nblocks,Lw);
Sxr = zeros(Nblocks,Lw);
W  = zeros(Nblocks,Lw);
xest = zeros(size(r));
ind = 1:Lw;
for j = 1:Nblocks
    
    temp = zeros(size(r));
        
    X = 1/Lw .* fft(x(ind));
    R = 1/Lw .* fft(r(ind));
    Sxx(j,:) = X .* conj(X);
    Sxr(j,:) = X .* conj(R);
    W(j,:) = Sxr(j,:) ./ Sxx(j,:);
        
    temp(ind) = Lw/2 * ifft(W(j,:) .* X);  
    xest = xest + temp;
        
    ind = ind + Lw/2;
    
end
ind = ind - Lw/2;
if L ~= ind(end)
    disp('Note that the length of the recovered signal has been shortened!')
end
xest((ind(end)+1):L)=[];


%{
% Example of time varying Wiener filter function
% Need spectrogram matlab function!
clear all
clc
close all
% Synthetized signal
% Sampling frequency 1 kHz
% Chirp: start at 50 Hz and cross 450 Hz at 10 s with strong Gussian background noise (SNR -18 dB)
fs = 1000;
T = 10;
t=0:1/fs:T;
r=chirp(t,50,T,450);
L = length(r);
wnoise = 6 .* randn(size(r));
x = wnoise + r;
figure
spectrogram(r,256,250,256,1E3);
view(-45,65)
colormap bone
title('Reference signal')
figure
subplot(1,2,1)
spectrogram(x,256,250,256,1E3);
view(-45,65)
colormap bone
title('Noisy signal')
Lw = 256;
[xest,B,Nblocks] = ADwienerFilt(x,r,Lw);
subplot(1,2,2)
spectrogram(xest,256,250,256,1E3);
view(-45,65)
colormap bone
title('Estimated signal')
%}