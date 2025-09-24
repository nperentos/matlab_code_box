% Description : Creates a gauss kernel
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
% Dependencies : none
%
% Updates : 
%

function y = gausskernel(duration,samplerate,sigma,scale)
% y = gaussKernel(duration, samplerate, sigma, scale) creates a vector that 
% contains a Gaussian in its center:
%
% 'duration' defines the total duration (e.g. in second) of the window.
% 'samplerate' defines the temporal resolution of the trace (e.g. in Hz).
% 'sigma' defines the standard deviation of the gaussian.
% 'scale' boolean flag that indicates whether or not the window should be
% scaled to a surface of 1.
%
% The Gaussian is centered in this trace. Except for situations in which
% mod(duration*samplerate,2) is 0. Then the kernel is shifted by one
% sample to the left.
%
% by Jan Grewe, no warrenty!

x = (-duration/2):1/samplerate:(duration/2);


y=(1/(sqrt(2*pi)*sigma))* exp(-(x.^2/(2*sigma^2)));
if(length(y) > round(duration*samplerate)) %assuming that there will be at maximum a difference of 1
    y(1) = [];
end;

if(scale)
    y = y./sum(y);
end