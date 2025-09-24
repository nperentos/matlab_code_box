function [] = main_getAllFeatures(path_input)
% GETALLPOSITIONS takes the path of all Kilosort output files
% (spike_times.npy, ..) and runs through all good clusters to extract their
% dendrite position and features. These values will be saved as
% "xyzfeatures.mat" file to be loaded by the main.m function. This function
% should be run first through all the data so individual elements can be
% plotted lateron on top of the full probe layout with all clusters.
%
% For questions, please ask paul.weger@tum.de
path_input = '/storage2/perentos/data/SINAPS_2024__sorting/1950_2/';
% Import Data
fs = 20000;
spike_times = readNPY(fullfile(path_input, 'spike_times.npy'));             % time (sample) of spike
spike_clusters = readNPY(fullfile(path_input, 'spike_clusters.npy'));        % cluster number to each spike
fid = fopen(fullfile(path_input,'cluster_group.tsv'), 'r');    
cluster_group_cell = textscan(fid, '%s %s', 'HeaderLines', 1, 'Delimiter', '\t');   % Contains mua, good, noise labels
fclose(fid);
channel_map = readNPY(fullfile(path_input,'channel_map.npy'));                % Numbers channels
channel_positions = readNPY(fullfile(path_input,'channel_positions.npy'));    % X, Y coordinates


% this readjusts the coordinates to the correct intershank spacing of 250
% we have to examine if this does not disagree with previous computations
% in main_getAllFeatures.m
ofs = 310;
correction = [zeros(128,1);ofs.*ones(128,1);2*ofs.*ones(128,1);3*ofs.*ones(128,1);4*ofs.*ones(128,1);5*ofs.*ones(128,1);6*ofs.*ones(128,1);7*ofs.*ones(128,1)];
channel_positions(:,1) = channel_positions(:,1)-correction;
channel_positions(:,2) = repmat(channel_positions(1:128,2),8,1);


% Find good clusters
cluster_group = cluster_group_cell{2};
index_good = find(strcmp(cluster_group, 'good'));
cluster_id = str2double(cluster_group_cell{1});
cluster_id_good = cluster_id(index_good);

% added by NP cause it was missing
id_show_till = length(cluster_id_good); % we will assume this to be the number of clusters

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
gwfparams.fileName = 'temp_wh.dat';
gwfparams.dataType = 'int16';
gwfparams.nCh = 1024;
gwfparams.wfWin = [-40 41];     % samples to include before / after spiketime
gwfparams.nWf = 1000;

% Initialization
x_dendrite = cell(1, id_show_till);
y_dendrite = cell(1, id_show_till);
z_time_dendrite = cell(1, id_show_till);
z_ampl_dendrite = cell(1, id_show_till);
features = cell(1, length(id_good));

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
save(fullfile(path_input,'xyzfeatures.mat'), 'x_dendrite', 'y_dendrite','z_ampl_dendrite', 'z_time_dendrite', 'features','feat','featNorm','featureNameNice');

end

