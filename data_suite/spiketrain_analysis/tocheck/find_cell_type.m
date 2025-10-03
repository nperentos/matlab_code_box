function [type,meanfreq] = find_cell_type(spikes, threshold, time)
if nargin<2 || isempty(threshold) || threshold == 0; threshold=10; end;
if nargin<3 || isempty(time); time=[]; end;

meanfreq = spike_mean_frequency(spikes,time);
if meanfreq >= threshold; 
    type = 'in';
else
    type = 'pyr';
end;
