function lfp = remove_line_noise(lfp, samplingfrequency, mode)

if nargin<3
    mode = 'elliptic';
end;

% Defaults
nyquist = samplingfrequency/2;

if strcmp(mode,'iir')
    Wo = 50/nyquist;  BW = Wo/35;
    [b,a] = iirnotch(Wo,BW);
    lfp =  filtfilt(b,a,lfp);
    
elseif strcmp(mode,'elliptic')
    [b a] = ellip(2,0.5,20,[49,51]/nyquist,'stop');
    %[b a] = ellip(4,3, 40,[49,51]/nyquist,'stop');
    lfp =  filtfilt(b,a,lfp);

elseif strcmp(mode,'fft')
    lfp = fftfilter_lfp(lfp,samplingfrequency,[49 51],1);
    
elseif strcmp(mode,'chronux')
    params.tapers = [3 5];
    params.pad = 3;
    params.Fs = samplingfrequency;
    lfp = rmlinesc(lfp,params,[],'y',50);
end;


