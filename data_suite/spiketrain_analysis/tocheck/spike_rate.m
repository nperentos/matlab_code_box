function [h,time]=spike_rate(spikes, num_bins,plotflag)
if nargin<3; plotflag=0; end;
if isempty(spikes); h=spikes; return; end;
order = @(x) 10^floor(log10(x)); % calculates the order of magnitude of a number
floorn = @(x) floor(x/order(x))*order(x); % calculates the floor of a number as a power of 10 e.g. 121 --> 100
ceiln = @(x) ceil(x/order(x))*order(x); % calculates the ceil of a number as a power of 10 e.g. 121 --> 200

start = floor(min(spikes));
stop = ceil(max(spikes));
time = linspace(start,stop,num_bins);
[h, x] = hist(spikes, time);

if plotflag;
    bar(x,h/(x(2)-x(1)));
    set(gca, 'FontName', 'Times New Roman', 'Fontsize', 16)
    xlim([start ceil(max(spikes))]);
    xlabel('time s'); ylabel('Rate Hz');
end