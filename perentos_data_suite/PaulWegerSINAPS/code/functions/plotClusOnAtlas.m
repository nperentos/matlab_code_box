function [final_x,final_y,final_zTime,final_zAmpl] = plotClusOnAtlas(wf,coordinates_reshaped, x_dendrite_resample, y_dendrite_resample, maxCoordinates)


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


%% correctly plot the channel positions
% correction = [zeros(128,1);280.*ones(128,1);2*280.*ones(128,1);3*280.*ones(128,1);4*280.*ones(128,1);5*280.*ones(128,1);6*280.*ones(128,1);7*280.*ones(128,1)];
figure('pos',[1075   400   800   800]); 
electrode_color = [1 1 1].*0.6;
plot(channel_pos_reshaped(:,1),channel_pos_reshaped(:,2),'markerfacecolor',electrode_color,...
    'linestyle','none','marker','s','color','none'); %-correction
xlim([-100 2000]);ylim([-100 2000]);
hold on; 
plot([0 0],[-100 0],'r')
plot([500 500],[-100 0],'r')
set(gcf,'color','w');
set(gca,'color','w');
axis equal;
% %print(gcf,['test2.eps'],'-deps','-r300'); 


%% Plot Dendrite Position & Spike Timing
% fig = figure('Color','none');
%mainAxes = axes;
%subplot(5,5,[13,14,18,19]);
%hold on;  
%scatter(channel_pos_reshaped(:,1), channel_pos_reshaped(:,2), 'filled','MarkerEdgeColor',[0.9 0.9 0.9],'MarkerFaceColor',[0.9 0.9 0.9], 'DisplayName', 'Multishank Probe');

%Plot All Dendrites
for j = 1:length(x_dendrite_resample)
    %plot(mainAxes, x_dendrite_resample{j},y_dendrite_resample{j},'LineWidth',1.5,'Color',[0.6 0.6 0.6]);
    %plot(x_dendrite_resample{j},y_dendrite_resample{j},'LineWidth',1.5,'Color',[0.6 0.6 0.6]);
    scatter(maxCoordinates(1,j),maxCoordinates(2,j),'filled','MarkerFaceColor','r');%[0.6 0.6 0.6]
end
xlim([-200 2200]);ylim([-200 2000]);
plot([0 0],[-100 0],'r');
plot([500 500],[-100 0],'r');

jet_colorset = jet(1000);

%Plot Individual Dendrite
for i = 1:length(final_x)-1
    color = jet_colorset(zTime_scaled(i),:);
    %plot(mainAxes, final_x(i:i+1), final_y(i:i+1), 'LineWidth', 3, 'Color', color);
    plot(final_x(i:i+1), final_y(i:i+1), 'LineWidth', 3, 'Color', color);
end

% Colorbar
c2 = colormap(gca, jet_colorset);
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
title('Dendrite Position');
minX = min(final_x)-80;
maxX = max(final_x)+80;
minY = min(final_y)-50;
maxY = max(final_y)+50;
xlim([minX, maxX]);
ylim([minY, maxY]);
grid on;
hold off;

% Make small plot in corner
%sideAxes = axes;
%sideAxes.Position = [0.15 0.7 0.2 0.2];
%hold(sideAxes, 'on');
subplot(5,5,[16,17]);
hold on;
scatter(channel_pos_reshaped(:,1), channel_pos_reshaped(:,2), 'filled','MarkerEdgeColor',[0.9 0.9 0.9],'MarkerFaceColor',[0.9 0.9 0.9], 'DisplayName', 'Multishank Probe');
axis equal;
%Plot All Dendrites
for j = 1:1%length(x_dendrite_resample)
    %plot(sideAxes, x_dendrite_resample{j},y_dendrite_resample{j},'LineWidth',1.5,'Color',[0.6 0.6 0.6])
    plot(x_dendrite_resample{j},y_dendrite_resample{j},'LineWidth',1.5,'Color',[0.6 0.6 0.6])
end
%plot(sideAxes, final_x, final_y, 'k', 'LineWidth', 2);
plot(final_x, final_y,'Color', 'k','LineWidth', 3);
%box(sideAxes, 'on');
%set(sideAxes, 'XTick',[]);
%set(sideAxes, 'YTick',[]);
xlim([-50, 4050 ]);
ylim([-20, 2020]);
%sideAxes.Color = 'w';
%set(sideAxes,'Color','w');
grid on;
xlabel('X (µm)');
ylabel('Y (µm)');
title('Probe Layout');
rectangle('Position', [minX, minY, maxX - minX, maxY - minY], 'EdgeColor', 'r','LineWidth',2);

%hold(sideAxes,'off');

% % Plot autocorrelogram
% subplot(5,5,[11,12]);
% hold on;
% bar(wf.acgx,wf.acgy);
% xlabel('Time bins (ms)');
% title('Autocorrelogram');




% Export figure as png
% folderPath = fullfile(wf.path_output, 'DendritePositions'); % Update folder path
% fileName = fullfile(folderPath, ['unit', num2str(id_unit), '_position.png']);
% if ~exist(folderPath, 'dir')
%     mkdir(folderPath);
% end
% saveas(gcf, fileName);
% clf;
% close(fig);




end









