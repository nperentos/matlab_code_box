function [x, gaussFilter] = smooth_gauss(x, windowlength, sigma3)
x = x(:);
if nargin<3; sigma3 = windowlength * 0.995 /6; end;
if nargin<2; windowlength = length(x)/20; end; % 5% of the length

alpha = (windowlength - 1 )/ (2*sigma3); % σ = (N – 1)/(2α)

gaussFilter = gausswin(windowlength,alpha);
gaussFilter = gaussFilter / sum(gaussFilter); % Normalize.
%fig; jplot(gaussFilter);
x = conv(x, gaussFilter,'same');