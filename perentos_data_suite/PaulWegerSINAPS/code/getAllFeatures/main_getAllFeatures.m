function [] = main_getAllFeatures(path_input)
% GETALLPOSITIONS takes the path of all Kilosort output files
% (spike_times.npy, ..) and runs through all good clusters to extract their
% dendrite position and features. These values will be saved as
% 'xyzfeatures.mat' file to be loaded by the main.m function. This function
% should be run first through all the data so individual elements can be
% plotted lateron on top of the full probe layout with all clusters.
%
% For questions, please ask paul.weger@tum.de


% Define path if no input is defined
if nargin < 1 || isempty(path_input)
    path_input = '/storage2/perentos/data/SINAPS_2024__sorting/1950_2/';
end

% Import Data
fs = 20000;
spike_times = readNPY(fullfile(path_input, 'spike_times.npy'));             % time (sample) of spike
spike_clusters = readNPY(fullfile(path_input, 'spike_clusters.npy'));        % cluster number to each spike
fid = fopen(fullfile(path_input,'cluster_group.tsv'), 'r');    
cluster_group_cell = textscan(fid, '%s %s', 'HeaderLines', 1, 'Delimiter', '\t');   % Contains mua, good, noise labels
fclose(fid);
channel_map = readNPY(fullfile(path_input,'channel_map.npy'));                % Numbers channels
%channel_positions = readNPY(fullfile(path_input,'channel_positions.npy'));    % X, Y coordinates
load(fullfile(path_input,'channel_positions.mat'));%np 21/04/2024


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

% Reshape coordinates into shanks & electrodes
coordinates_original = reshape(channel_positions', 2, 128, 8);
y_coordinates_true = coordinates_original(2,:,1);
coordinates_reshaped = coordinates_original;
for i = 1:8
    coordinates_reshaped(2,:,i) = y_coordinates_true;
end

% Set up the parameters
gwfparams.dataDir = path_input;
gwfparams.fileName = 'temp_wh.dat';%'1950_2.dat';
gwfparams.dataType = 'int16';
gwfparams.nCh = 1024;
gwfparams.wfWin = [-40 41];     % samples to include before / after spiketime
gwfparams.nWf = 1000;

% Initialization
x_dendrite = cell(1, length(id_good));
y_dendrite = cell(1, length(id_good));
z_time_dendrite = cell(1, length(id_good));
z_ampl_dendrite = cell(1, length(id_good));
features = cell(1, length(id_good));
fprintf('Setup complete, lets load the clusters 1 by 1 (largest -> smallest) \n');

for i = 1:length(id_good)
    gwfparams.spikeTimes = spike_times(spike_clusters==id_good(i));             % vector of cluster spike times (in samples)
    gwfparams.spikeClusters = spike_clusters(spike_clusters==id_good(i));       % vector of cluster IDs
    wf = getWaveForms(gwfparams);

    [x_dendrite{i}, y_dendrite{i}, z_time_dendrite{i}, z_ampl_dendrite{i}, features{i}] = getDendritePosition(wf, coordinates_reshaped);     

    fprintf('Loop %d completed. \n', i);
end

% Loop through all data to create matrix with all features
feat = zeros(numel(fieldnames(features{1})),length(x_dendrite));
featureNames = fieldnames(features{1});
featureNameNice = ['Direction', 'Spread', '1/vAbove', '1/vBelow', 'Amplitude', 'Duration', 'PTratio', 'RepoSlope', 'RecoSlope'];
unitID = id_good;
for i = 1:length(x_dendrite)
    fields = fieldnames(features{1});
    sampleFeatures = features{i};
    for j = 1:numel(fieldnames(features{1}))
        featureNameTemp = string(fields{j});
        featureValue = sampleFeatures.(char(featureNameTemp));
        feat(j,i) = featureValue;
    end
end

% Normalize features
featMax = max(abs(feat),[],2);
featNorm = feat ./ featMax;

% Save data 
outfile = fullfile('/storage2/perentos/data/SINAPS_2024__sorting/1950_2/','xyzfeatures.mat');
save(outfile, 'x_dendrite', 'y_dendrite','z_ampl_dendrite', 'z_time_dendrite', 'features','feat','featNorm','featureNameNice', 'id_good');


end

