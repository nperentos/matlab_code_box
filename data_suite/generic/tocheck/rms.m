% Description : 
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
% Dependencies : 
%
% Updates : 
%

% sliding window in seconds
function y = rms(x)
y = sqrt(nanmean(x.^2));