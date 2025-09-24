% Description : 
%
% Algorithm : 
%
% It calls the findpeaks_DSP which is just a local copy of the findpeaks
% function included with the signal processing toolbox.
% There is another findpeaks included with chronux, that is why the local
% copy is used to avoid the overlap.
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
% 17/05/2013 - Added line 25 so that it can work with row and vector arrays
%


function [maxindex, minindex]=minimamaxima(x,plot_flag)
x=x(:)';
[maxima,maximalocations]=findpeaks_DSP(x);
[minima,minimalocations]=findpeaks_DSP(-x);
maxindex = [maximalocations;maxima]';
minindex = [minimalocations;-minima]';
if nargin>1 && plot_flag==1
    %figure; 
    plot(x); hold on; 
    plot(maxindex(:,1),maxindex(:,2),'r*'); 
    plot(minindex(:,1),minindex(:,2),'m*'); 
    hold off;
end;