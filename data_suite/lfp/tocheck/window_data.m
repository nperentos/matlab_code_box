% Returns the windowed version of the signal
% Each row is one part of the signal
% If the pad flag is 1, it will not cut the end of the signal 
% (which doesn't fit in the last window), but will pad it with zero.

function y=window_data(lfp,samplingfrequency,windowsize, overlap, windowtype, pad)
if nargin<4 || isempty(overlap); 
    overlap=0;
else
    overlap = overlap*windowsize*samplingfrequency/100; % overlap should be given as percentage
end;
if nargin<5 || isempty(windowtype); windowtype = 'hamming'; end;
if nargin<6; pad=0; end;

windowsize = windowsize*samplingfrequency;
len  = length(lfp);

if overlap == 0;
    numwindows = floor(len/windowsize);

    if  pad==1 && mod(len,windowsize)~=0
        numwindows=numwindows+1;
        temp = zeros(numwindows*windowsize);
        temp(1:length(lfp))=lfp;
        lfp=temp;    
    end;
else
    window = get_window(windowtype,windowsize,samplingfrequency);
    jump = windowsize - overlap;
    % TO WRITE
    % numwindows
    % lfp = conv(lfp,window,'same');
    % 
    
end;

y=reshape(lfp(1:windowsize*numwindows),windowsize, numwindows)';
