% To write
% Ideally lfps provided should be short in duration otherwise it will take
% forever.

function find_bad_channels(lfps,samplingfrequency)
coherences = calculate_coherence(lfps,[],samplingfrequency,'windowsize',1,'overlap',80,'nw',2,'whiten',0);

figure; 
imagesc(squeeze(sum(coherences,1))); 
set(gca,'XTick',1:size(lfps,1),'YTick',1:size(lfps,1)); 
box off;