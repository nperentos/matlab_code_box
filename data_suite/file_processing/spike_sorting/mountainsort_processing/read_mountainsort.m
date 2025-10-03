function clusters = read_mountainsort(filebase, spikegroupindex, keepgood);

if nargin<3; keepgood=1; end;
if nargin<2; spikegroupindex = 0; end;
info = get_datfile_info(filebase);

%% Define files
if spikegroupindex==0
    fn = [filebase '/mtsort/output/ms3--ds1/firings.mda'];
    metricsfn = [filebase '/mtsort/output/ms3--ds1/cluster_metrics.json'];
    pairmetricsfn = [filebase '/mtsort/output/ms3--ds1/cluster_pair_metrics.json'];
    %fn = [filebase '/mtsort/output/ms3--ds1/firings.curated.mda'];
else
    fn = [filebase '/mtsort/output' num2str(spikegroupindex) '/ms3--ds1/firings.mda'];
    metricsfn = [filebase '/mtsort/output' num2str(spikegroupindex) '/ms3--ds1/cluster_metrics.json'];
    pairmetricsfn = [filebase '/mtsort/output' num2str(spikegroupindex) '/ms3--ds1/cluster_pair_metrics.json'];
end

%% Load firings
firings = readmda(fn);
cluid = unique(firings(3,:));

%% Load metrics
metrics = fileread(metricsfn);
metrics = jsondecode(metrics);
metrics = metrics.clusters;

pairmetrics = fileread(pairmetricsfn);
pairmetrics = jsondecode(pairmetrics);
pairmetrics = pairmetrics.cluster_pairs;

%%
pairmetrics1 = {};
for c=1:length(pairmetrics);
    pairmetrics1{c,1} = str2num(pairmetrics(c).label);
    pairmetrics1{c,2} = pairmetrics(c).metrics.overlap;
end

mua = pairmetrics1(find(cell2mat(pairmetrics1(:,2))>0.05),1);
mua = unique(cell2mat(mua'));

%%
good = [];
for c=1:length(metrics)
    if (metrics(c).metrics.noise_overlap<=0.05 & metrics(c).metrics.peak_noise<=30 & metrics(c).metrics.isolation>=0.9)
        good = cat(1,good,c);
    end
end

%good = setdiff(good,mua);
if keepgood
    cluid = cluid(good);
end;

%% Prepare table
clusters = table();
clusters.id = double(cluid(:));
clusters.type = repmat({''},length(clusters.id),1);
clusters.channel = double(nan(length(clusters.id),1));
clusters.rel_channel = double(nan(length(clusters.id),1));
%clusters.channel_orig = int16(nan(length(clusters.id),1));
clusters.spikes = cell(length(clusters.id),1);
clusters.waveform = cell(length(clusters.id),1);

%% Load original channels
% Extract spike groups from file
[xcoords,ycoords,kcoords,connected] = read_map_file(filebase);

% Find good channels
channels = find(connected);

%% Populate table
for c=1:length(cluid);
    idx = firings(3,:)==cluid(c);
    clusters.spikes{c} = firings(2,idx);
    clusters.spikes{c} = clusters.spikes{c}(:);
    clusters.rel_channel(c) = unique(firings(1,idx)); % channel within the channels that were sorted in this batch.
    clusters.channel(c) = channels(clusters.rel_channel(c)); % absolute channel - only correct if run in one go - not split in spikegroups
    clusters.metrics{c} = metrics(cluid(c)).metrics;
end


%% Calculate average waveform

nspikes = 1000;
filter_window = 1000;
spike_window = 30;

m = memmap_datfile(filebase,'dat');
maxtime = size(m.Data.m,2);
%%
% waveform = {};
% for c = 1:length(clusters.id);
%     disp(['Processing cluster ' num2str(c) '/' num2str(length(clusters.id))]);
%     tic;
%     % Not filtered - improper
%     %spikes((spikes<spike_window) | (spikes>maxtime - spike_window) )=[]; % ensure we get spikes that fit the window
%     %idx = periodindices(spikes,spike_window); idx = idx(:);
%     %sig = double(m.Data.m(clusters.channel(c),idx));
%     %sig = reshape(sig(:),2*spike_window+1,length(spikes))';
%     %waveform{c} = mean(sig,2);
%
%     spikes = clusters.spikes{c};
%     spikes = spikes(randi(length(spikes),min(nspikes,length(spikes)),1)); % random 1000 spikes (or all spikes if less than 1000);
%     spikes((spikes<filter_window) | (spikes>maxtime - filter_window) )=[]; % ensure we get spikes that fit the window
%     idx = periodindices(spikes,filter_window); idx = idx(:);
%     sig = double(m.Data.m(clusters.channel(c),idx));
%     sig = filter_lfp(double(sig),info.fs,[600 8000]);
%     sig = reshape(sig(:),2*filter_window+1,length(spikes))';
%     sample_idx = (filter_window-spike_window+1):(filter_window+spike_window+1); % keep samples from the middle
%     sig = sig(:,sample_idx);
%     waveform{c} = mean(sig,1);
%     toc;
% end
%
% for c=1:length(waveform); clusters.waveform{c} = waveform{c}; end;

%% Calculate auto-correlations

clusters.autocorr = cell(length(clusters.id),1);
for c=1:length(clusters.id)
    T = clusters.spikes{c};
    G = ones(length(T),1);
    [clusters.autocorr{c},t] = CCG(T,G,0.001*info.fs,0.1/0.001,info.fs,1,'count');
end

%% Save
units = clusters; % rename

if spikegroupindex==0
    units.rel_channel = [];
    clustersfn = get_lfp_filename(filebase,'units');
    save(clustersfn,'units');
    % Waveforms and templates
    add_unit_template(filebase);
    % Create Clu-Res
    try;
        clures_from_units(filebase);
    catch
    end
else
    clustersfn = get_lfp_filename(filebase,['units' num2str(spikegroupindex)]);
    save(clustersfn,'units');
end



%% To add
% Database of waveshape parameters - automatic classification
