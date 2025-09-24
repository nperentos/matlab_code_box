% input: a timeseries
% output: out: the relative power of each peak of the timeseries
% t: the timepoints of each peak

function [out, t] = relative_peak_power(x)
[maxindex, minindex]=minimamaxima(x,0);

if minindex(1,1)>maxindex(1,1);
    maxindex(1,:) = [];
end;

if length(minindex)~=length(maxindex);
    minindex = minindex(1:min(length(minindex),length(maxindex)),:);
    maxindex = maxindex(1:min(length(minindex),length(maxindex)),:);
end;

t = maxindex(:,1);

out = ((maxindex(:,2) - minindex(:,2)) + (maxindex(:,2) - [minindex(2:end,2) ; minindex(end,2)]))/2 ;