% *** To incorporate in filter_lfp ***

%This will return a frequency band in the time domain.
%All data will be demeaned.  Method is take fft, set unwanted freqs to zero,
%Take ifft, and return the data to you.
function filtlfp = fftfilter_lfp(lfp,samplingfrequency,frequency_band, stopband) 

if frequency_band(2)==0
    frequency_band(2)=samplingfrequency/2;
end;

lfp=lfp(:);
lfp  = lfp-mean(lfp);
lfp=lfp.*boxcar(length(lfp));


%Take fourier transform
fy     = fft(lfp);
Plfp = sum(fy.*conj(fy));

%Make frequency axis, accomodating for the way Matlab outputs fft
long = fix(length(fy)/2);
df   = 1/(length(lfp)/samplingfrequency);
if length(lfp)/2==long,          %Different freq axis if length is even or odd
freq = [0 df:df:df*long (df*long-df):-df:df];
else   freq = [0 df:df:df*long df*long:-df:df]; 
end;


%Find data not in the band, take ifft of the rest
if nargin<4 || stopband == 0
    place = [find(freq<=frequency_band(1)) find(freq>=frequency_band(2))];
else
    place = find(freq>frequency_band(1) & freq<frequency_band(2));
end;
fy(place) = 0;

filtlfp = real(ifft(fy));
