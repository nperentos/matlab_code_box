function spiketrain_period = raster_plot_period_allneurons(spiketrains,periods,color)
if nargin<3 || isempty(color); color = 'k'; end;
neurons = size(spiketrains,1);
spiketrain_period = zeros(neurons,1);
for r=1:neurons;
    temp = [];
    for p=1:size(periods,1)
        temp = cat(2,temp,spikes_in_period(spiketrains{r,:},periods(p,:))); 
    end;
    spiketrain_period(r,1:length(temp)) = temp;
end;

raster_plot(spiketrain_period,color);