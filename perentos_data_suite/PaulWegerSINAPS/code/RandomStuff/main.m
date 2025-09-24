function [] = main(path_input, path_output)
% MAIN_takes the files of kilosort/phy output files to create a
% folder containing all "good" labled units information
%
% Inputs:
% - path_input = path to Kilosort files (spike_times.npy, ...)
% - path_output = path where you want the three output folders with figures
%                 to be placed
% Outputs:
% - No variables, just places the figures in path_output
%
% For questions, ask paul.weger@tum.de 



% Some setups to get relevant functions
currentFolder = fileparts(which("main.m"));
addpath(fullfile(currentFolder, 'functions'));
addpath(fullfile(currentFolder, 'getAllFeatures'));

% Import Data
fs = 20000;
spike_times = readNPY(fullfile(path_input, 'spike_times.npy'));             % time (sample) of spike
spike_clusters = readNPY(fullfile(path_input, 'spike_clusters.npy'));        % cluster number to each spike
fid = fopen(fullfile(path_input,'cluster_group.tsv'), 'r');    
cluster_group_cell = textscan(fid, '%s %s', 'HeaderLines', 1, 'Delimiter', '\t');   % Contains mua, good, noise labels
fclose(fid);
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

% Reshape coordinates into shanks & electrodes
coordinates_original = reshape(channel_positions', 2, 128, 8);
y_coordinates_true = coordinates_original(2,:,1);
coordinates_reshaped = coordinates_original;
for i = 1:8
    coordinates_reshaped(2,:,i) = y_coordinates_true;
end

% Load data of all dendrite positions (! change if not the same dataset)
loadedData = load(fullfile(currentFolder,'getAllFeatures','xyzfeatures.mat'));
x_dendrite = loadedData.x_dendrite;
y_dendrite = loadedData.y_dendrite;
featNorm = loadedData.featNorm;
featureNames = loadedData.featureNameNice;
z_ampl = loadedData.z_ampl_dendrite;
maxCoordinates = zeros(2, length(z_ampl));

% Downsampel remaining dendrites to have fewer data
x_dendrite_resample = cell(1, length(x_dendrite));
y_dendrite_resample = cell(1, length(y_dendrite));
for i = 1:length(x_dendrite)
    selectedXValues = [];
    selectedYValues = [];
    selectedXValues(1) = x_dendrite{i}(1);
    selectedYValues(1) = y_dendrite{i}(1);
    lengthTemp = length(x_dendrite{i}) / 22 +1;
    if lengthTemp >= 2
        selectedXValues(2:lengthTemp) = x_dendrite{i}(22:22:end);
        selectedYValues(2:lengthTemp) = y_dendrite{i}(22:22:end);
    end
    x_dendrite_resample{i} = selectedXValues;
    y_dendrite_resample{i} = selectedYValues;
    [~, maxPosition] = max(abs(z_ampl{i}));
    maxCoordinates(1,i) = x_dendrite{i}(maxPosition);
    maxCoordinates(2,i) = y_dendrite{i}(maxPosition);
end

% Loop through all good clusters to get pngs of the trajectory & position
for j = 1:length(id_good)
    if ~isnan(featNorm(1,j))
        id_show = id_good(j);
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
        wf.path_output = path_output;
    
        % Plot spatiotemporal propagation
        [~, ~] = plotAmplitudePropagation(wf);        % Add 2nd parameter cutoffSig and 3rd parameter ampCutOff
        % Plot dendrite position on probe layout
        plotOverallDendrite(wf,coordinates_reshaped, x_dendrite, y_dendrite, maxCoordinates);
        % Plot Feature space & where current sample is
        plotFeatureSpace(featNorm, j,id_show, path_output,featureNames);
        
        fprintf("Results for cluster number # %d saved \n", id_show);
    end
end
end


