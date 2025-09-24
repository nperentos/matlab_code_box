% Runs xcorr on two point-processes
% Steps:
% 1. Histogram
% 2. xcorr

% Note: The xcorr is ran intentionally with the reverse order than the
% default xcorr, so that if y follows x (is delayed), the output will be
% positive correlation (same as run_ccg), not negative as is with xcorr.

% Time t is in milliseconds.


function [out,t]=run_xcorr(x,y,binsize, halfwindow, sr, scaling)

if (isempty(x) | isempty(y)); out = []; t=[]; return; end;
if nargin<6; scaling = 'coeff'; end;
if nargin<5; sr = 1000; end;
if nargin<4; halfwindow = 0.5; end;
if nargin<3; binsize = 0.001; end;
x = double(x(:));
y = double(y(:));

maxt = max(max(x), max(y));
bins = 0:binsize*sr:(maxt+binsize*sr);
tmp1 = histc(x,bins);
tmp2 = histc(y,bins);

tmp1 = tmp1(:); 
tmp2 = tmp2(:);

out = [];
[out,t] = xcorr(tmp2,tmp1,halfwindow/binsize,scaling);

t = t*binsize*1000;

% In case of autocorrelation, remove the 0 lag bin
if isequal(tmp1,tmp2); 
    out((length(out)-1)/2+1) = 0;
end
% coeff option does the following normalization:
% coeffscale = (@(a,b) sqrt(sum(abs(a).^2)*sum(abs(b).^2)));
% out = out/coeffscale(x,y);