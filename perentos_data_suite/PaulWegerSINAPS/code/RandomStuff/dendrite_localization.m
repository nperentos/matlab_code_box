%% Localize Dendrites via Dendritic Backpropagation


%% Importing Data and preprocessing 
% https://phy.readthedocs.io/en/latest/sorting_user_guide/

addpath('~/Downloads/npy-matlab-master/npy-matlab/');       % Might need to be changed!
savepath;
% Spike Information (full) 
fs = 20000;
spike_times = readNPY('/storage3/paul/data/1950_2/KS/spike_times.npy');             % time (sample) of spike
spike_clusters = readNPY('/storage3/paul/data/1950_2/KS/spike_clusters.npy');       % cluster number to each spike
fid = fopen('/storage3/paul/data/1950_2/KS/cluster_group.tsv', 'r');    
cluster_group_cell = textscan(fid, '%s %s', 'HeaderLines', 1, 'Delimiter', '\t');   % Contains mua, good, noise labels
fclose(fid);
% Probe layout
channel_map = readNPY('/storage3/paul/data/1950_2/KS/channel_map.npy');                % Numbers channels
channel_positions = readNPY('/storage3/paul/data/1950_2/KS/channel_positions.npy');    % X, Y coordinates

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


%% Rudimentary probe layout

coordinates_original = reshape(channel_positions', 2, 128, 8);
% Fix coordinates
y_coordinates_true = coordinates_original(2,:,1);
coordinates_reshaped = coordinates_original;
for i = 1:8
    coordinates_reshaped(2,:,i) = y_coordinates_true;
end


figure;
hold on;

for shank = 1:8
    x_shank = coordinates_reshaped(1,:,shank);
    y_shank = coordinates_reshaped(2,:,shank);
    
    scatter(x_shank, y_shank, 'filled','MarkerEdgeColor',[0.9 0.9 0.9],'MarkerFaceColor',[0.9 0.9 0.9], 'DisplayName', ['Shank ', num2str(shank)]);
end

xlabel('X (μm)');
ylabel('Y (μm)');
%axis equal;
title('Multishank probe layout');
%legend('show');
grid on;
hold off;




%% Extract dendrite position from single cluster & Plot

load_cluster = false;
if load_cluster == true
    id_show = id_good(73);  % 73 is nice
    % Set up the parameters
    gwfparams.dataDir = '/storage3/paul/data/1950_2/KS';     
    gwfparams.fileName =  'temp_wh.dat';
    gwfparams.dataType = 'int16';
    gwfparams.nCh = 1024;
    gwfparams.wfWin = [-40 41];     % samples to include before / after spiketime
    gwfparams.nWf = 1000;
    gwfparams.spikeTimes = spike_times(spike_clusters==id_show);             % vector of cluster spike times (in samples)
    gwfparams.spikeClusters = spike_clusters(spike_clusters==id_show);       % vector of cluster IDs
    wf = getWaveForms(gwfparams);
end


fprintf("Results for cluster number # %d \n", id_show);
[~, ~] = plotAmplitudePropagation(wf);        % Add 2nd parameter cutoffSig and 3rd parameter ampCutOff
plotDendritePosition(wf,coordinates_reshaped, x_dendrite, y_dendrite);
% Load x_dendrites into it BEFORE USING IT




%% Extract probe position from multiple clusters



% Set up the parameters
gwfparams.dataDir = '/storage3/paul/data/1950_2/KS';
gwfparams.fileName = 'temp_wh.dat';
gwfparams.dataType = 'int16';
gwfparams.nCh = 1024;
gwfparams.wfWin = [-40 41];     % samples to include before / after spiketime
gwfparams.nWf = 1000;

% Initialization
%x_dendrite = cell(1, id_show_till);
%y_dendrite = cell(1, id_show_till);
%z_time_dendrite = cell(1, id_show_till);
%z_ampl_dendrite = cell(1, id_show_till);
%features = cell(1, length(id_good));


for i = 1:length(id_good)

    gwfparams.spikeTimes = spike_times(spike_clusters==id_good(i));             % vector of cluster spike times (in samples)
    gwfparams.spikeClusters = spike_clusters(spike_clusters==id_good(i));       % vector of cluster IDs
    wf = getWaveForms(gwfparams);

    [x_dendrite{i}, y_dendrite{i}, z_time_dendrite{i}, z_ampl_dendrite{i}, features{i}] = getDendritePosition(wf, coordinates_reshaped);        % Add 2nd parameter cutoffSig and 3rd parameter ampCutOff

    fprintf("Loop %d completed. \n", i);
    
end

% Loop through all data to create matrix with all features
%feat = zeros(numel(fieldnames(features{1})),length(x_dendrite));
%featureNames = fieldnames(features{1});
%unitID = id_good;

for i = 1:length(x_dendrite)
    fields = fieldnames(features{1});
    sampleFeatures = features{i};
    for j = 1:numel(fieldnames(features{1}))
        featureNameTemp = string(fields{j});
        featureValue = sampleFeatures.(featureNameTemp);
        feat(j,i) = featureValue;
    end
end


%% Show multiple dendrite positions on probe layout including up/down/both classification

figure;
subplot(2,3,[1,2,4,5]);
hold on;  
scatter(channel_pos_reshaped(:,1), channel_pos_reshaped(:,2), 'filled','MarkerEdgeColor',[0.9 0.9 0.9],'MarkerFaceColor',[0.9 0.9 0.9], 'DisplayName', 'Multishank Probe');
for i = 1:length(x_dendrite)
    % See if unit is curved, linear ascending/descending
    isLinear(i) = issorted(z_time_dendrite{i}, 'descend') || issorted(z_time_dendrite{i}, 'monotonic') || issorted(z_time_dendrite{i}, 'ascend');
    isAscending(i) = all(diff(z_time_dendrite{i}) >= 0);
    isDescending(i) = all(diff(z_time_dendrite{i}) <= 0);
    isMonotonic(i) = (isAscending(i) == 1 && isDescending(i) == 1);
    
    if isAscending(i) == 1 && isMonotonic(i) ~= 1
            plot(x_dendrite{i}, y_dendrite{i}, 'LineWidth', 2, 'Color', '#4DBEEE');
    elseif isDescending(i) == 1 && isMonotonic(i) ~= 1
            plot(x_dendrite{i}, y_dendrite{i}, 'LineWidth', 2, 'Color', '#0072BD');
    else
            plot(x_dendrite{i}, y_dendrite{i}, 'LineWidth', 2, 'Color', [0.4 0.4 0.4]);
    end
end
xlabel('X (μm)');
ylabel('Y (μm)');
title('Dendrite Positions and propagation style');
grid on;
hold off;

% Pie chart
subplot(2,3,[3,6]);
pieData = [sum(isAscending)-sum(isMonotonic),sum(isDescending)-sum(isMonotonic),length(isLinear)-sum(isAscending)-sum(isDescending)];
pieLabels = {'Ascending','Descending','Both'};
pieColors = [
    0.3010 0.7450 0.9330;   % '#4DBEEE'
    0.0000 0.4470 0.7410;   % '#0072BD'
    0.4 0.4 0.4;   % grey
];
ax = gca();
pie(pieData);
ax.Colormap = pieColors;
title('Propagation Distribution');
legend(pieLabels,'Location','southoutside');



%% Plot Channel Spread

% Extract positions of maximum amplitude
xMax = zeros(1,length(x_dendrite));
yMax = zeros(1,length(y_dendrite));
for i = 1:length(x_dendrite)
    [~, maxIdx] = max(z_ampl_dendrite{i});
    xTest = x_dendrite{i}(maxIdx);
    xMax(i) = xTest;
    yMax(i) = y_dendrite{i}(maxIdx);
end

% Plot all features
figure;
titleList = ["Propagation direction", "Spread (µm)","1/V_above","1/V_below", "Amplitude (mV)","Duration (ms)","PTratio","Repolarization Slope","Recovery Slope"];

featMax = max(abs(feat),[],2);
featNorm = feat ./ featMax;


for j = 1:numel(fieldnames(features{1}))          % figure out how to use that to loop through features
    subplot(3,3,j);
    hold on;  
    jet_colorset = jet(1000);
    featureInterest = feat(j,:);
    color_index = round(rescale(featureInterest,1,1000),0);
    featureColors = jet_colorset(color_index(~isnan(color_index)),:);
    xMax_trunc = xMax(~isnan(xMax));
    yMax_trunc = yMax(~isnan(yMax));
    scatter(channel_pos_reshaped(:,1), channel_pos_reshaped(:,2), 'filled','MarkerEdgeColor',[0.9 0.9 0.9],'MarkerFaceColor',[0.9 0.9 0.9], 'DisplayName', 'Multishank Probe');
    for i = 1:length(xMax_trunc)
        scatter(xMax_trunc(i),yMax_trunc(i),'filled','MarkerFaceColor',featureColors(i,:));
    end
    title(titleList(j));
    xlabel("X (µm)");
    ylabel("Y (µm)");
    grid on;
    colormap(jet_colorset);
    c = colorbar;
    %Set Ticks & Ticklabels
    Min = round(min(featureInterest),2);
    Max = round(max(featureInterest),2);

    ticks = [min(Min,0),max(Min,0), Max];
    if abs(Min) < 0.05
        ticks = [0, Max];
    end
    if abs(Max) < 0.05
        ticks = [Min, 0];
    end
    ticks = [Min, Max];
    if Min < 0 && Max > 0
         ticks = [Min, 0, Max];
    end
    if j == 1
        ticks = [min(featureInterest), 0, max(featureInterest)];
        tickLabels = ["Down", "Both", "Up"];
    end
    if j == 9
        ticks = [-1, -0.1];
    end
    if j == 8
        ticks = [0.1, 1];
    end
    if j== 6
        ticks = [0.2, 1];
    end
    if j == 7
        ticks = [0.2, 1];
    end


    tickLabels = cellstr(num2str(ticks'));
    c.Ticks = ticks;
    c.TickLabels = tickLabels;
    set(c, 'Ticks', ticks, 'TickLabels', tickLabels);
    caxis([min(featureInterest), max(featureInterest)]);
    ylabel(c, "Normalized feature value");
end

hold off;

%% Aline along linear dimension

% Trim alongside shanks to get upper CA3-CA1
xMax_copy = xMax;
yMax_copy = yMax;
for i = 1:length(xMax_copy)
    if (0 <= xMax_copy(i)) && (xMax_copy(i) <= 30) && (yMax_copy(i) <= 800)
        xMax_copy(i) = NaN;
        yMax_copy(i) = NaN;
    elseif (560 <= xMax_copy(i)) && (xMax_copy(i) <= 590) && (yMax_copy(i) <= 1000)
        xMax_copy(i) = NaN;
        yMax_copy(i) = NaN;
    elseif (1120 <= xMax_copy(i)) && (xMax_copy(i) <= 1150) && (yMax_copy(i) <= 1000)
        xMax_copy(i) = NaN;
        yMax_copy(i) = NaN;
    elseif (1680 <= xMax_copy(i)) && (xMax_copy(i) <= 1710) && (yMax_copy(i) <= 800)
        xMax_copy(i) = NaN;
        yMax_copy(i) = NaN;
    end
end
xCA13 = xMax_copy(~isnan(xMax_copy));
yCA13 = yMax_copy(~isnan(yMax_copy));
unitIdCA13 = id_good(~isnan(xMax_copy));
featCA13 = featNorm(:,~isnan(xMax_copy));


% Seperate into shanks
idxShank = cell(1,8);
for i = 1:length(xCA13)
    if xCA13(i) >= 0 && xCA13(i) <= 30
        idxShank{1} = [idxShank{1}, i];
    elseif (560 <= xCA13(i)) && (xCA13(i) <= 590)
        idxShank{2} = [idxShank{2}, i];
    elseif (1120 <= xCA13(i)) && (xCA13(i) <= 1150)
        idxShank{3} = [idxShank{3}, i];
    elseif (1680 <= xCA13(i)) && (xCA13(i) <= 1710)
        idxShank{4} = [idxShank{4}, i];
    elseif (2240 <= xCA13(i)) && (xCA13(i) <= 2270)
        idxShank{5} = [idxShank{5}, i];
    elseif (2800 <= xCA13(i)) && (xCA13(i) <= 2830)
        idxShank{6} = [idxShank{6}, i];
    elseif (3360 <= xCA13(i)) && (xCA13(i) <= 3390)
        idxShank{7} = [idxShank{7}, i];
    elseif (3920 <= xCA13(i)) && (xCA13(i) <= 3950)
        idxShank{8} = [idxShank{8}, i];
    end 
end

% Calculate average feature per shank
featMean = zeros(length(idxShank),size(featCA13,1));
featStd = zeros(length(idxShank),size(featCA13,1));
for i = 1:length(idxShank)
    for j = 1:size(featCA13,1)
        valueShankFeat = featCA13(j,idxShank{i});

        featMean(i,j) = mean(valueShankFeat);
        featStd(i,j) = std(valueShankFeat);
    end
end

% Plot change of mean features
figure;
shankNumber = [1:8];
hold on;
for i = 1:size(featMean,2)
    plot(shankNumber,featMean(:,i),'-','LineWidth',2,'DisplayName',featureNames{i});
    upperStd = featMean(:,i) + featStd(:,i);
    lowerStd = featMean(:,i) - featStd(:,i);
    inBetween = cat(1,upperStd, fliplr(lowerStd));
    xFill = [shankNumber, fliplr(shankNumber)];
    %fill(xFill, inBetween, [0.5 0.5 0.5], 'FaceAlpha', 0.05,'DisplayName','');
end
legend('Location','eastoutside');
xlabel('Shank Nr.');
ylabel('Normallized Feature');
title("Feature Means alongside CA3-CA1")

%% Make Histogram over all shanks & features

figure;
num_plot = 1;
titleList = string(featureNames);
for i = 1:length(idxShank)
    for j = 1:length(featureNames)

        data_ij = featCA13(j,idxShank{i});
        subplot(9,8,i + 8*(j-1));
        histogram(data_ij,10);
        xlim([-1, 1]);

        if j == length(featureNames)
            xlabel(['Shank #', num2str(i)]);
        end
        if i == 1
            title(titleList(j));
        end
    end
end

%% Extract trajectories from multiple clusters to make statistics


id_show_till = 200;
% Set up the parameters
gwfparams.dataDir = '/storage3/paul/data/1950_2/KS';
gwfparams.fileName = 'temp_wh.dat';
gwfparams.dataType = 'int16';
gwfparams.nCh = 1024;
gwfparams.wfWin = [-40 41];     % samples to include before / after spiketime
gwfparams.nWf = 1000;

timeRelSoma = cell(1, id_show_till);
distToSoma = cell(1, id_show_till);
relAmplitudes = cell(1, id_show_till);
V_above_inv = zeros(1, id_show_till);
V_below_inv = zeros(1, id_show_till);



for i = 1:id_show_till

    gwfparams.spikeTimes = spike_times(spike_clusters==id_good(i));             % vector of cluster spike times (in samples)
    gwfparams.spikeClusters = spike_clusters(spike_clusters==id_good(i));       % vector of cluster IDs
    wf = getWaveForms(gwfparams);

    [timeRelSoma{i}, distToSoma{i}, relAmplitudes{i}, V_above_inv(i), V_below_inv(i)] = getAmplitudePropagation(wf);        % Add 2nd parameter cutoffSig and 3rd parameter ampCutOff

    fprintf("Loop %d completed. \n", i);
end


%% Show overlayed trajectories and velocity scatter

show_until = 100;           %length(timeRelSoma);

figure;
subplot(1,2,1);
hold on;
for i = 1:show_until
    plot(timeRelSoma{i},distToSoma{i},'-','Color',[0.7 0.7 0.7],'LineWidth',1.5);
end
xlabel("Time relative to soma (ms)");
ylabel("Distance to soma (µm)");
title("Spike propagation trajectories");
xline(0, '--', 'Color', [0.7, 0.7, 0.7],'LineWidth',1);  
yline(0, '--', 'Color', [0.7, 0.7, 0.7],'Linewidth',1); 


subplot(1,2,2);
scatter(V_above_inv(1:show_until),V_below_inv(1:show_until),'.','Color',"#0072BD");
xlabel("1/v_a_b_o_v_e (ms/mm)");
ylabel("1/v_b_e_l_o_w (ms/mm)");
title("Scatter plot of inv. propagation velocity");
xline(0, '--', 'Color', [0.7, 0.7, 0.7],'LineWidth',1);  
yline(0, '--', 'Color', [0.7, 0.7, 0.7],'Linewidth',1);  
xlim([-6, 6]);
ylim([-6, 6]);




