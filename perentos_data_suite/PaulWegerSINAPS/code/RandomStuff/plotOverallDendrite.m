function [final_x,final_y,final_zTime,final_zAmpl] = plotOverallDendrite(wf,coordinates_reshaped, x_dendrite_resample, y_dendrite_resample, maxCoordinates)


cutoffSig = 0.12;
fs = 20000;



% Get amplitude information (conventional)
ap = squeeze(wf.waveFormsMean);
[min_value, min_linear_index] = min(ap(:));
[minRowIdx, ~] = ind2sub(size(ap), min_linear_index);
singleChan = ap(minRowIdx,:); 
[minAmp, peekTime] = min(squeeze(wf.waveFormsMean)');
side = NaN;
id_unit = wf.unitIDs;

if mod(minRowIdx,2) == 0                % even = left side of probe
    minAmpO = minAmp(2:2:end);          % O = onesided
    peekTimeO = peekTime(2:2:end);
    side = 1;
else                                    % odd = right side of probe
    minAmpO = minAmp(1:2:end);          
    peekTimeO = peekTime(1:2:end);
    side = 0;
end

[minAmpTot, posMinAmp] = min(minAmpO);
minAmpSigIdx = find(minAmpO < minAmpTot*cutoffSig);
minAmpSig = minAmpO(minAmpSigIdx);

distSoma = zeros(length(minAmpSig),1);
idxSoma = find(minAmpSig == minAmpTot);
distanceNorm = minAmpSigIdx - minAmpSigIdx(idxSoma);
distSoma = distanceNorm * 30;


%distSoma(idxSoma:end) = [0:30:30*(length(distSoma)-idxSoma)];
%distSoma(1:idxSoma) = [-30*(idxSoma-1):30:0];
%distSoma = -distSoma;



peekTimeSig = peekTimeO(minAmpSigIdx) / fs * 1000;
peekTimeSig = peekTimeSig - peekTimeSig(distSoma==0);



% Do here position here
chanIdx_full = 2*minAmpSigIdx + side;


% Calculate position
minVal = abs(min(squeeze(wf.waveFormsMean),[],2));
absMinVal = max(minVal);
%minVal(minVal < cutoffSig*absMinVal) = NaN;

% Estimate point betw. two electrodes
l_elec = minVal(1:2:end);
l_elec = l_elec(minAmpSigIdx);
r_elec = minVal(2:2:end);
r_elec = r_elec(minAmpSigIdx);
relDendritePos = 1-(l_elec./(l_elec + r_elec));

% Get coordinates of dendrites
dendritePos_all = [];
channel_pos_reshaped = reshape(coordinates_reshaped, size(coordinates_reshaped,1),size(coordinates_reshaped,2)*size(coordinates_reshaped,3))';
for i = 1:length(relDendritePos)
    dendritePos_all(i,1) = channel_pos_reshaped(2*minAmpSigIdx(i)-1,1) + relDendritePos(i) * (channel_pos_reshaped(2*minAmpSigIdx(i),1)-channel_pos_reshaped(2*minAmpSigIdx(i)-1,1));
    dendritePos_all(i,2) = channel_pos_reshaped(2*minAmpSigIdx(i)-1,2);
    if isnan(relDendritePos(i))
       dendritePos_all(i,2) = NaN; 
    end
end
dendritePos(:,1) = dendritePos_all(isnan(dendritePos_all(:,1))==false,1);
dendritePos(:,2) = dendritePos_all(isnan(dendritePos_all(:,2))==false,2);




% Get amplitude information 
relAmplitudes = minAmpO(minAmpSigIdx) / minAmpTot;

% All important Variables extracted
x = dendritePos(:,1);
y = dendritePos(:,2);
z_relAmpl = relAmplitudes;
z_Ampl = z_relAmpl* minAmpTot;
z_time = peekTimeSig;
z_dist = distSoma;

% Exclude threshold crossings if too far away
condition = abs(z_dist) > 750;
x = x(~condition);
y = y(~condition);
z_relAmpl = z_relAmpl(~condition);
z_Ampl = z_Ampl(~condition);
z_time = z_time(~condition);
z_dist = z_dist(~condition);



% Do interpolation between two adjacent points to get continuous color
num_points_between = 20;
new_x = [];
new_y = [];
new_zAmpl = [];
new_zTime = [];
for i = 1:length(x)-1
    interpolated_x = linspace(x(i), x(i+1), num_points_between+2);
    interpolated_y = interp1(x(i:i+1), y(i:i+1), interpolated_x, 'linear');
    interpolated_zAmpl = interp1(x(i:i+1), z_relAmpl(i:i+1), interpolated_x, 'linear');
    interpolated_zTime = interp1(x(i:i+1), z_time(i:i+1), interpolated_x, 'linear');
    
    new_x = [new_x, interpolated_x];
    new_y = [new_y, interpolated_y];
    new_zAmpl = [new_zAmpl, interpolated_zAmpl];
    new_zTime = [new_zTime, interpolated_zTime];
end
final_x = new_x;
final_y = new_y;
final_zAmpl = new_zAmpl;
final_zTime = new_zTime;
% Rescale Time to 1:000 range for colors
zTime_scaled = round((final_zTime - min(final_zTime))/(max(final_zTime) - min(final_zTime) + 0.001) * (1000-1) + 1,0);





% Plot Dendrite Position & Spike Timing
fig = figure('Color','w');
mainAxes = axes;
hold on;  
scatter(channel_pos_reshaped(:,1), channel_pos_reshaped(:,2), 'filled','MarkerEdgeColor',[0.9 0.9 0.9],'MarkerFaceColor',[0.9 0.9 0.9], 'DisplayName', 'Multishank Probe');

%Plot All Dendrites
for j = 1:length(x_dendrite_resample)
    plot(mainAxes, x_dendrite_resample{j},y_dendrite_resample{j},'LineWidth',1.5,'Color',[0.6 0.6 0.6]);
    scatter(maxCoordinates(1,j),maxCoordinates(2,j),'filled','MarkerFaceColor',[0.6 0.6 0.6]);
end
jet_colorset = jet(1000);

%Plot Individual Dendrite
for i = 1:length(final_x)-1
    color = jet_colorset(zTime_scaled(i),:);
    plot(mainAxes, final_x(i:i+1), final_y(i:i+1), 'LineWidth', 3, 'Color', color);
end

% Colorbar
colormap(jet_colorset);
h1 = colorbar;
minVal = min(final_zTime);
maxVal = max(final_zTime);
ticks = [minVal,0,maxVal];  % Adjust the number of ticks as needed
tickLabels = {num2str(minVal), '0', num2str(maxVal)};
if (maxVal == 0) && (minVal == 0)
    ticks = [-0.01,0,0.01];
    tickLabels = {'-0.01','0','0.01'};
elseif (minVal == 0) && (maxVal ~= 0)
    ticks = [0, maxVal];
    tickLabels = {'0',num2str(maxVal)};
elseif (maxVal == 0) && (minVal ~= 0)
    ticks = [minVal, 0];
    tickLabels = {num2str(minVal),'0'};
end 
set(h1, 'Ticks', ticks, 'TickLabels', tickLabels);
if minVal ~= maxVal
    caxis([min(minVal, maxVal), max(minVal, maxVal)]);
end

% Labeling etc
ylabel(h1, 'Time relative to Soma (ms)');
xlabel('X (μm)');
ylabel('Y (μm)');
title(['Dendrite Position of unit #', num2str(id_unit)]);
xlim([min(final_x)-80, max(final_x)+80]);
ylim([min(final_y)-50, max(final_y)+50]);
grid on;
hold off;

% Make small plot in corner
sideAxes = axes;
sideAxes.Position = [0.15 0.7 0.2 0.2];
hold(sideAxes, 'on');
%scatter(channel_pos_reshaped(:,1), channel_pos_reshaped(:,2), 'filled','MarkerEdgeColor',[0.9 0.9 0.9],'MarkerFaceColor',[0.9 0.9 0.9], 'DisplayName', 'Multishank Probe');
%Plot All Dendrites
for j = 1:length(x_dendrite_resample)
    plot(sideAxes, x_dendrite_resample{j},y_dendrite_resample{j},'LineWidth',1.5,'Color',[0.6 0.6 0.6])
end
plot(sideAxes, final_x, final_y, 'k', 'LineWidth', 2);
box(sideAxes, 'on');
set(sideAxes, 'XTick',[]);
set(sideAxes, 'YTick',[]);
xlim(sideAxes, [-50, 4050 ]);
ylim(sideAxes, [-20, 2020]);
sideAxes.Color = 'w';
set(sideAxes,'Color','w');
grid on;
hold(sideAxes,'off');






% Export figure as png
folderPath = fullfile(wf.path_output, 'DendritePositions'); % Update folder path
fileName = fullfile(folderPath, ['unit', num2str(id_unit), '_position.png']);
if ~exist(folderPath, 'dir')
    mkdir(folderPath);
end
saveas(gcf, fileName);
clf;
close(fig);




end

