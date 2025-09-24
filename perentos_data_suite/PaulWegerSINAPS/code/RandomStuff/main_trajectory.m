function [] = main_trajectory(path_input, path_output)
%MAIN_TRAJECTORY takes the folder of kilosort/phy output files to create a
%folder containing all "good" labled units trajectory as figure



% Importing Data and preprocessing 
% https://phy.readthedocs.io/en/latest/sorting_user_guide/

% Spike Information
fs = 20000;
spike_times = readNPY(fullfile(path_input, 'spike_times.npy'));             % time (sample) of spike
spike_clusters = readNPY(fullfile(path_input, 'spike_clusters.npy'));        % cluster number to each spike
fid = fopen(fullfile(path_input,'cluster_group.tsv'), 'r');    
cluster_group_cell = textscan(fid, '%s %s', 'HeaderLines', 1, 'Delimiter', '\t');   % Contains mua, good, noise labels
fclose(fid);
% Probe layout
channel_map = readNPY(fullfile(path_input,'channel_map.npy'));                % Numbers channels
channel_positions = readNPY(fullfile(path_input,'channel_positions.npy'));    % X, Y coordinates

% Find good clusters
cluster_group = cluster_group_cell{2};
index_good = find(strcmp(cluster_group, 'good'));
cluster_id = str2double(cluster_group_cell{1});
cluster_id_good = cluster_id(index_good);

% Sort the clusters according to their size
for i = 1:length(cluster_id_good)
    cluster_length(i) = length(find(spike_clusters == cluster_id_good(i)));
end
[~, sortingIndices] = sort(cluster_length,'descend');
n_spikes = cluster_length(sortingIndices)';
id_good = cluster_id_good(sortingIndices);

for j = 1:length(id_good)
    % Put Loop over all things here
    % Extract dendrite position from single cluster & Plot
    load_cluster = true;
    if load_cluster == true
        id_show = id_good(j);  % 73 is nice
        % Set up the parameters
        gwfparams.dataDir = path_input;     
        gwfparams.fileName =  'temp_wh.dat';
        gwfparams.dataType = 'int16';
        gwfparams.nCh = 1024;
        gwfparams.wfWin = [-40 41];     % samples to include before / after spiketime
        gwfparams.nWf = 1000;
        gwfparams.spikeTimes = spike_times(spike_clusters==id_show);             % vector of cluster spike times (in samples)
        gwfparams.spikeClusters = spike_clusters(spike_clusters==id_show);       % vector of cluster IDs
        wf = getWaveForms(gwfparams);
    end
    
    wf.path_output = path_output;
    [~, ~] = plotAmplitudePropagation(wf);        % Add 2nd parameter cutoffSig and 3rd parameter ampCutOff
    fprintf("Results for cluster number # %d saved \n", id_show);

end



end

% /storage3/paul/data/1950_2/KS/