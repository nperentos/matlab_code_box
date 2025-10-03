% Author : Nikolas Karalis
% neurons here is a cell containing the neurons' spiketrains
function raster_plot_allneurons(neurons,periods,color)
period_color='r';
if nargin<2 || isempty(periods); periods = []; end;
if nargin<3 || isempty(color); color = 'k'; end;
if isvector(neurons); neurons = neurons(:)'; end;
%plot(spiketrain, trial*ones(1,1),'d','Markersize',2.5); hold on;
num_neurons = size(neurons,2);
for r=1:num_neurons;
    spiketrain = neurons{1,r};
    spiketrain = spiketrain(:)';
    for s=1:size(spiketrain,2)
        line([spiketrain(1,s) spiketrain(1,s)], [r r+0.5],'Color',color)
    end;
    if ~isempty(periods)
        temp = [];
        for p=1:size(periods,1)
            temp = cat(2,temp,spikes_in_period(spiketrain,periods(p,:))); 
        end;
        size(temp)
        spiketrain_period = temp;
        for s=1:size(spiketrain_period,2)
            line([spiketrain_period(1,s) spiketrain_period(1,s)], [r r+0.5],'Color',period_color)
        end;  
    end;
end;
ylim([0.5 num_neurons+1])
set(gca,'FontName','Times New Roman','Fontsize', 14,'TickDir','out','YTick',1:num_neurons);
xlabel('Time s'); ylabel('Neurons');
title('Rasterplot');
plot_events(periods,'r',10,'min')