function amp=lfp_amplitude(lfp, samplingfrequency, windowsize,method)

if nargin<4; method='abs'; end;

windowed_lfp=window_data(lfp,samplingfrequency,windowsize);

amp = zeros(size(windowed_lfp,1),1);
if strcmp(method,'abs')
    for c=1:size(windowed_lfp,1)
        amp(c) = sum(abs(windowed_lfp(c,:)));
    end;
end;