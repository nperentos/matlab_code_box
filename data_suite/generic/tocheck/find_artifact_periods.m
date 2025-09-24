% Input : 
%  - sig :  The signal to be cleaned
%  - thr :  The threshold (it is a multiplier N, by which the RMS of the
%  signal is being multiplied).
%  - tthr : Defined in datapoints and is the minimum distance so that two
% artifact periods are considered different
%  - thr2 :  The 2nd (lower) threshold for the removal of the power dropoff of the artifacts
%          (it is a multiplier N, by which the original threshold is multiplied).
%  - tthr2 : Defined in datapoints and is the minimum distance so that two
% artifact periods are considered different
%  - wings : extra datapoints to be cut-off on the left/right of the
%  periods. Essentially it works synergistically with the thr2 but is a stronger measure.
% 
% Output : 
%  - The periods with artifacts
%  - The cleaned signal (artifact values replaced with NaN

% Dependencies : inputparser, slider
%
% Author : Nikolas Karalis 
% Date : 21/06/2015

function varargout = find_artifact_periods(sig,thr, tthr,thr2,tthr2,wings)
if nargin<2 || isempty(thr); thr = 5; end
if nargin<3 || isempty(tthr); tthr = 500; end 
if nargin<4 || isempty(thr2); thr2 = 0.3; end;
if nargin<5 || isempty(tthr2); tthr2 = tthr; end;
if nargin<6 || isempty(wings); wings = 500; end;

thr = thr*rms(sig);
sig1 = abs(sig);
% prctile(sig,99.5) % potentially I can define the threshold using the
% percentile of the values

disp(['Threshold used: ' num2str(thr) '.']);

tmp = find(sig1>thr);
tmp1 = abs(diff([-10000 tmp -10000])); % I put -10000 instead of 0 to catch the possibility that the edges are inside a period

jump_points = find(tmp1>=tthr); 

periods = [tmp(jump_points(1:end-1)) ; tmp(jump_points(2:end)-1)]';

% The remaining problem now is that after the end of the artifact (and
% potentially before the beginning, there is a period of still high power.
% I cannot capture it using lower threshold, because this would potentially
% cut out normal signal. So I should define a second lower threshold and
% only use it on periods just before and after the original episodes


thr2 = thr2*thr;

tmp = [periods(:,1)-tthr2 periods(:,2)+tthr2];
tmp(tmp<1) = 1;
tmp(tmp>length(sig1)) = length(sig1);

for k=1:size(tmp,1)
    tmp1 = find(sig1(tmp(k,1):tmp(k,2))>thr2);
    periods(k,:) = [tmp(k,1) + min(tmp1)  tmp(k,1)+ max(tmp1)];
end

overl = find(periods(2:end,1) - periods(1:end-1,2)<tthr);
while ~isempty(overl);
    tmp = overl(1);
    periods(tmp,2) = periods(tmp+1,2);
    periods(tmp+1,:) = [];
    overl = find(periods(2:end,1) - periods(1:end-1,2)<tthr);
end

% 
periods(:,1) = periods(:,1) - wings;
periods(:,2) = periods(:,2) + wings;

periods(periods(:,1)<1,1)=1;

varargout(1) = {periods};

if nargout>1;
    sig1 = sig; 
    for k=1:size(periods,1); sig1(periods(k,1):periods(k,2)) = NaN; end;
    varargout(2) = {sig1};
end;