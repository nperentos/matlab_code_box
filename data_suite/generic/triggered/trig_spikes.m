function [out,bins] = trig_spikes(spikes,events, dur, binsize)

bins = -dur:binsize:dur;
out = spikes_in_periods(spikes(:),[events(:) - dur events(:) + dur],1);
for c=1:length(out)
    out{c} = out{c} - events(c);
end


out = cellfun(@(x) histc(x(:),bins),out,'un',0);
%out = cell2mat(cellfun(@(x) x(:)',out,'un',0)');
out = cell2mat(cellfun(@(x) x(:)',out','un',0)');

out(:,end-1) = out(:,end-1)+out(:,end);
out = out(:,1:end-1);

bins = bins(1:end-1) + mean(diff(bins))/2; % bin centers