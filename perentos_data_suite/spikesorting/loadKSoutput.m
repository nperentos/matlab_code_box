%% loading the most necessary elements of kilosort output
global KSpath;

% spike times
spike_times = double(readNPY('spike_times.npy'));

% spike clusters
spike_clusters = double(readNPY('spike_clusters.npy'));

% spike 
similar_templates = double(readNPY('similar_templates.npy'));

% plot all ISIHs
nClu = length(unique(spike_clusters));
nsp = sqrt(nClu);
if nsp - floor(nsp) > 0;  a = ceil(nsp); b = a; end
for i = 1:nClu
    subplot(a,b,i);
    hist(diff(spike_times(spike_clusters == i)),50);
end
    
    