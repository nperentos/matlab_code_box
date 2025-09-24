% Description : Returns 
%
% Algorithm : 
%
% Input :  
%
% Output : 
%
% Author : Nikolas Karalis
% Date : April 2013
%
% Dependencies : None
%
% Updates : 
%

function window = get_window(windowname,windowsize,samplingfrequency)

if strcmp(windowname,'hamming')
    window = hamming(windowsize * samplingfrequency);
elseif strcmp(windowname,'hanning')
    window = hanning(windowsize * samplingfrequency);
elseif strcmp(windowname,'blackmanharris')
    window = blackmanharris(windowsize * samplingfrequency); 
elseif strcmp(windowname,'gauss')
    window = gausswin(windowsize * samplingfrequency); 
elseif strcmp(windowname,'hann')
    window = hann(windowsize * samplingfrequency); 
elseif strcmp(windowname,'kaiser')
    window = kaiser(windowsize * samplingfrequency); 
elseif strcmp(windowname,'rect')
    window = rectwin(windowsize * samplingfrequency); 
elseif strcmp(windowname,'cheb')
    window = chebwin(windowsize * samplingfrequency);                 
end;