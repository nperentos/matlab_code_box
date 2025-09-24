function [final_x,final_y,final_zTime,final_zAmpl, features] = getDendritePosition(wf,coordinates_reshaped)


cutoffSig = 0.12;
fs = 20000;



% Get amplitude information (conventional)
ap = squeeze(wf.waveFormsMean);
[min_value, min_linear_index] = min(ap(:));
[minRowIdx, ~] = ind2sub(size(ap), min_linear_index);
singleChan = ap(minRowIdx,:); 
[minAmp, peekTime] = min(squeeze(wf.waveFormsMean)');
side = NaN;

% Extract single channel features from singleChan
singleFeature = struct();
[trough, troughTime] = min(singleChan);
[singlepeak, singlepeakTime] = max(singleChan(troughTime:end));
singlepeakTime = troughTime + singlepeakTime;
singleFeature.amplitude = abs(trough - singlepeak);     % in mV
singleFeature.duration = (singlepeakTime - troughTime)*(1/fs)*1000;     % in ms
singleFeature.PTratio = abs(singlepeak) / abs(trough);  

yRepo = singleChan(troughTime:troughTime+2);
xRepo = [0, 1/fs, 2*1/fs];
dy = diff(yRepo);
dx = diff(xRepo);
singleFeature.repoSlope = mean(dy)/mean(dx);

yReco = singleChan(singlepeakTime:singlepeakTime+2);
xReco = [0, 1/fs, 2*1/fs];
dy = diff(yReco);
dx = diff(xReco);
singleFeature.recoSlope = mean(dy)/mean(dx);




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

multiFeature = struct();

%distSoma(idxSoma:end) = [0:30:30*(length(distSoma)-idxSoma)];
%distSoma(1:idxSoma) = [-30*(idxSoma-1):30:0];
%distSoma = -distSoma;

peekTimeSig = peekTimeO(minAmpSigIdx) / fs * 1000;
peekTimeSig = peekTimeSig - peekTimeSig(distSoma==0);


% Get regression line vabove
    x_Vabove = peekTimeSig(distSoma>=0);
    [~,idxHighestAbove] = max(abs(x_Vabove));
    y_Vabove = distSoma(distSoma>=0)';
    xA_0 = 0;
    yA_0 = 0;
    xA_mean = mean(x_Vabove);
    yA_mean = mean(y_Vabove);
    xA_max = xA_mean * (x_Vabove(idxHighestAbove)/xA_mean);
    yA_max = yA_mean * (x_Vabove(idxHighestAbove)/xA_mean);
    regLineXAbove = [xA_0, xA_mean, xA_max];
    regLineYAbove = [yA_0, yA_mean, yA_max];
    Vabove_inv = xA_mean / yA_mean * 1000;        % 1/1000 to get to ms/mm from ms/µm
    if isinf(Vabove_inv)
        Vabove_inv = 0;
    end
    if isnan(Vabove_inv)
        Vabove_inv = 0;
    end
    multiFeature.vAboveInv = Vabove_inv;
    %disp(['Value 1/v_above is: ' num2str(round(Vabove_inv,2)) ' ms/mm']);   
    
    % Get regression line vbelow
    x_Vbelow = peekTimeSig(distSoma<=0);
    [~,idxHighestBelow] = max(abs(x_Vbelow));
    y_Vbelow = distSoma(distSoma<=0)';
    xB_0 = 0;
    yB_0 = 0;
    xB_mean = mean(x_Vbelow);
    yB_mean = mean(y_Vbelow);
    xB_max = xB_mean * (x_Vbelow(idxHighestBelow)/xB_mean);
    yB_max = yB_mean * (x_Vbelow(idxHighestBelow)/xB_mean);
    regLineXBelow = [xB_0, xB_mean, xB_max];
    regLineYBelow = [yB_0, yB_mean, yB_max];
    Vbelow_inv = xB_mean / yB_mean * 1000;        % 1/1000 to get to ms/mm from ms/µm
    if isinf(Vbelow_inv)
        Vbelow_inv = 0;
    end
    if isnan(Vbelow_inv)
        Vbelow_inv = 0;
    end
    multiFeature.vBelowInv = Vbelow_inv;
    %disp(['Value 1/v_below is: ' num2str(round(Vbelow_inv,2)) ' ms/mm']);



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

% Exclude cluster by setting values to NaN if spread is too large
if any(abs(z_dist) > 450)
    countLarger = sum(abs(z_dist) > 450);

    if countLarger > 0.5*length(z_dist)
        final_x = NaN;
        final_y = NaN;
        final_zAmpl = NaN;
        final_zTime = NaN;
        
        features = struct();
        features.multi_direction = NaN;
        %features.multi_speed = NaN;
        features.multi_spread = NaN;
        features.multi_vAboveInv = NaN;
        features.multi_vBelowInv = NaN;
    
        features.amplitude = NaN;
        features.duration = NaN;
        features.PTratio = NaN;
        features.repoSlope = NaN;
        features.recoSlope = NaN;

        return;
    else
        condition = abs(z_dist) > 450;
        x = x(~condition);
        y = y(~condition);
        z_relAmpl = z_relAmpl(~condition);
        z_Ampl = z_Ampl(~condition);
        z_time = z_time(~condition);
        z_dist = z_dist(~condition);
    end
end

multiFeature.spread = abs(z_dist(end) - z_dist(1));


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
final_zAmpl = new_zAmpl * minAmpTot;
final_zTime = new_zTime;
% Rescale Time to 1:000 range for colors
zTime_scaled = round((final_zTime - min(final_zTime))/(max(final_zTime) - min(final_zTime) + 0.001) * (1000-1) + 1,0);


% See if unit is curved, linear ascending/descending
% = determine multiFeature "direction"
    isLinear = issorted(final_zTime, 'descend') || issorted(final_zTime, 'monotonic') || issorted(final_zTime, 'ascend');
    isAscending = all(diff(final_zTime) >= 0);
    isDescending = all(diff(final_zTime) <= 0);
    isMonotonic = (isAscending == 1 && isDescending == 1);
    
    if isAscending == 1 && isMonotonic ~= 1
            multiFeature.direction = 1;
            multiFeature.speed = abs(final_y(end) - final_y(1)) / abs(max(final_zTime) - min(final_zTime));
    elseif isDescending == 1 && isMonotonic ~= 1
            multiFeature.direction = -1;
            multiFeature.speed = abs(final_y(end) - final_y(1)) / abs(max(final_zTime) - min(final_zTime));
    else
            multiFeature.direction = 0;    % = curved
            [minTimeVal, minTimeSample] = min(final_zTime);
            [maxTimeVal, maxTimeSample] = max(final_zTime);

            distanceOnesided = abs(final_y(maxTimeSample) - final_y(minTimeSample));

            if (maxTimeVal - minTimeVal) ~= 0
                multiFeature.speed = distanceOnesided / abs((maxTimeVal - minTimeVal));
            else
                multiFeature.speed = 0;
            end

    end


features = struct();
if isempty(final_x) == false
    features.multi_direction = multiFeature.direction;

    %features.multi_speed = multiFeature.speed;
    features.multi_spread = multiFeature.spread;
    features.multi_vAboveInv = multiFeature.vAboveInv;
    features.multi_vBelowInv = multiFeature.vBelowInv;
    
    features.amplitude = singleFeature.amplitude;
    features.duration = singleFeature.duration;
    features.PTratio = singleFeature.PTratio;
    features.repoSlope = singleFeature.repoSlope;
    features.recoSlope = singleFeature.recoSlope;

    if isnan(features.amplitude)
        features.multi_direction = NaN;
    end

else
    features.multi_direction = NaN;
    %features.multi_speed = NaN;
    features.multi_spread = NaN;
    features.multi_vAboveInv = NaN;
    features.multi_vBelowInv = NaN;
    
    features.amplitude = NaN;
    features.duration = NaN;
    features.PTratio = NaN;
    features.repoSlope = NaN;
    features.recoSlope = NaN;


    final_y(:) = NaN;
    final_zTime(:) = NaN;
    final_zAmpl(:) = NaN;
    final_x(:) = NaN;

end



if isempty(final_x)
    final_x = NaN;
    final_y = NaN;
    final_zAmpl = NaN;
    final_zTime = NaN;
end







% Plot Dendrite Position & Amplitude Information
% figure;
% subplot(1,2,1);
% hold on;  
% jet_colorset = jet(1000);
% scatter(channel_pos_reshaped(:,1), channel_pos_reshaped(:,2), 'filled','MarkerEdgeColor',[0.9 0.9 0.9],'MarkerFaceColor',[0.9 0.9 0.9], 'DisplayName', 'Multishank Probe');
% %scatter(x, y, 50*z_ampl, 'k', 'filled');
% for i = 1:length(final_x)-1
%     color_index = round(final_zAmpl(i)*1000,0);
%     color = jet_colorset(color_index,:);
%     plot(final_x(i:i+1), final_y(i:i+1), 'LineWidth', 4, 'Color', color);
% end
% colormap(jet_colorset);
% h = colorbar;
% ylabel(h, 'Normalized Amplitude (n.u.)');
% xlabel('X (μm)');
% ylabel('Y (μm)');
% title('Axon Position and Amplitude');
% grid on;
% hold off;


% Plot Dendrite Position & Spike Timing
% subplot(1,2,2);
% hold on;  
% scatter(channel_pos_reshaped(:,1), channel_pos_reshaped(:,2), 'filled','MarkerEdgeColor',[0.9 0.9 0.9],'MarkerFaceColor',[0.9 0.9 0.9], 'DisplayName', 'Multishank Probe');
% %scatter(x, y, 50*z_ampl, 'k', 'filled');
% for i = 1:length(final_x)-1
%     color = jet_colorset(zTime_scaled(i),:);
%     plot(final_x(i:i+1), final_y(i:i+1), 'LineWidth', 4, 'Color', color);
% end
% colormap(jet_colorset);
% h1 = colorbar;
% 
% minVal = min(final_zTime);
% maxVal = max(final_zTime);
% 
% ticks = [minVal,0,maxVal];  % Adjust the number of ticks as needed
% tickLabels = {num2str(minVal), '0', num2str(maxVal)};
% 
% if (maxVal == 0) && (minVal == 0)
%     ticks = [-0.01,0,0.01];
%     tickLabels = {'-0.01','0','0.01'};
% elseif (minVal == 0) && (maxVal ~= 0)
%     ticks = [0, maxVal];
%     tickLabels = {'0',num2str(maxVal)};
% elseif (maxVal == 0) && (minVal ~= 0)
%     ticks = [minVal, 0];
%     tickLabels = {num2str(minVal),'0'};
% end 
% 
% 
% % Set the ticks and tick labels on the colorbar
% set(h1, 'Ticks', ticks, 'TickLabels', tickLabels);
% if minVal ~= maxVal
%     caxis([min(minVal, maxVal), max(minVal, maxVal)]);
% end
% 
% 
% ylabel(h1, 'Time relative to Soma (ms)');
% xlabel('X (μm)');
% ylabel('Y (μm)');
% title('Axon Position and Spike Timing');
% grid on;
% hold off;


end




