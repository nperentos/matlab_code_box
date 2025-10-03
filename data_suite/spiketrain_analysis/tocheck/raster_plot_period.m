function spiketrain_period = raster_plot_period(spiketrain,periods,color)
if nargin<3 || isempty(color); color = 'k'; end;
trials = size(spiketrain,1);
spiketrain_period = zeros(trials,1);
for r=1:trials;
    temp = [];
    for p=1:size(periods,1)
        temp = cat(2,temp,spikes_in_period(spiketrain(r,:),periods(p,:))); 
    end;
    spiketrain_period(r,1:length(temp)) = temp;
end;

raster_plot(spiketrain_period,color);