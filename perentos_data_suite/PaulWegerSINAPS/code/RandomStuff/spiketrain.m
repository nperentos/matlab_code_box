%% File creating spike trains from Phy ouput

%% Importing Data
fs = 20000;
spike_times = readNPY('spike_times.npy');
spike_templates = readNPY('spike_templates.npy');
spike_clusters = readNPY('spike_clusters.npy');
cluster_group = readtable('cluster_group.tsv', 'Delimiter', '\t', 'FileType','text');

%% Find 'good' cluster IDs
groups = cluster_group.group;
ind_good = find(strcmp(groups, 'good'));

cluster_id = cluster_group.cluster_id;
cluster_id_good = cluster_id(ind_good);

%% Create spiketrain matrix within 1 second

% Get 'good' spiketimes within first 1 second
spike_times_b1 = spike_times(spike_times < 1*fs);
spike_clusters_b1 = spike_clusters(1:length(spike_times_b1));
spiketimes_good = cell(length(cluster_id_good),1);

for i=1:length(cluster_id_good)
    ind_clusterid = find(spike_clusters_b1 == cluster_id_good(i));
    spiketimes_good{i} = spike_times_b1(ind_clusterid);
end

% Remove empty, bin into 1 ms and sort top activity to bottom
spiketimes_full = spiketimes_good(~cellfun('isempty',spiketimes_good));
spiketimes_ms = cellfun(@(x) floor(x*1000 / fs), spiketimes_full, 'UniformOutput',false);
numEntries = cellfun(@numel, spiketimes_ms);
[~, sortOrder] = sort(numEntries, 'descend');
spiketimes_ms = spiketimes_ms(sortOrder);

% Put into spiketrain matrix containing 1s and 0s
train = zeros(length(spiketimes_ms), 1*1000);

for i = 1:length(spiketimes_ms)
    train(i,spiketimes_ms{i}) = 1;
end

%% Calculate firing rate statistics

% Define exponential kernel
tau = 50;  % Time constant of the exponential kernel
kernelLength_exp = 2 * tau;  % Set the length of the kernel
kernel_exp = exp(-(0:kernelLength_exp) / tau);

% Define gauss Kernel
sigma = 50;  % Standard deviation of the Gaussian kernel
kernelLength_gauss = 6 * sigma;  % Set the length of the kernel
kernel_gauss = normpdf(-kernelLength_gauss/2:kernelLength_gauss/2, 0, sigma);

% Pad spiketrain and convolve
train_padded = padarray(train, [0, kernelLength_gauss]);
firingRate = conv2(train_padded, kernel_gauss, 'valid');

% Do some sketchy stuff to match overall firing rate]
meanFiringRate = sort(numEntries, 'descend');
firingRate = firingRate .* (meanFiringRate ./ mean(firingRate,2)) / 2;

%% Plot the spiketrain

figure;
subplot(2,1,1);
imagesc(1 - train, 'CDataMapping','scaled');
colormap('gray');
caxis([0, 1]);
xlabel('Time (ms)');
ylabel('Neuron #');
title('Spiketrain');

subplot(2,1,2);
hold on;
plot(firingRate(1,:)');
plot(firingRate(10,:)');
plot(firingRate(30,:)');
hold off;
xlim([0 1300]);
title('Momentary Firing Rate');
xlabel('Time (ms)');
ylabel('Firing Rate (Hz)');
legend('Neuron #1', 'Neuron #10', 'Neuron #30');

 