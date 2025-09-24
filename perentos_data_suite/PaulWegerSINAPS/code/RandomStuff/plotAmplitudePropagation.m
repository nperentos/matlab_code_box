function [Vabove_inv, Vbelow_inv] = plotAmplitudePropagation(wf, varargin)


    % Some initial values that can be passed to the function if desired
    if nargin == 2
        cutoffSig = varargin{1};
        ampCutoff = 0.06;
    else if nargin == 3
        cutoffSig = varargin{1};
        ampCutoff = varargin{2};
    else
        cutoffSig = 0.12;    % What % of amplitude of maximum amplitude are relevant for analysis
        ampCutoff = 0.07;   % Significant peak to consider for analysis? in % of maximum peak
    end
    fs = 20000;
  
    
    % Calculate channel with largest spike
    id_unit = wf.unitIDs;
    ap = (squeeze(wf.waveFormsMean));
    [min_value, min_linear_index] = min(ap(:));
    [minRowIdx, ~] = ind2sub(size(ap), min_linear_index);
    singleChan = ap(minRowIdx,:);
    
    % Get Start & stop row for channel overvier
    lowerLim = max(1,minRowIdx-30);
    upperLim = min(1024,minRowIdx+30);
    
    % Channel overview
    %clf;
    fig = figure; 
    subplot(2,4,[1, 2, 5, 6]);
    imagesc(squeeze(wf.waveFormsMean));
    xlabel('Time (ms)'); ylabel('Channel number'); 
    titelTemp = sprintf('Unit #%d channel overview',id_unit);
    title(titelTemp);
    colormap(colormap_BlueWhiteRed);  caxis([-1 1]*max(abs(caxis()))/2); box off;
    xlim([25 65]);
    existing_ticks = xticks;
    modified_labels = arrayfun(@(x) sprintf('%.1f', x*1000/fs), existing_ticks, 'UniformOutput', false);
    xticklabels(modified_labels);
    %xlim([1.25 3.25])
    axis xy;
    ylim([lowerLim, upperLim]);




    
    
    % Get mean waveforms of every 2nd trace 
    startRow = lowerLim;
    endRow = upperLim;
    extractRows = startRow:2:endRow;
    traces = ap(extractRows,:);
    tracesNorm = (traces / abs(min_value));
    
    subplot(2,4,[3, 7]);
    x_values = (1:82)*1000 / fs;
    hold on;
    for row = 1:size(tracesNorm, 1)
    
        if (min(tracesNorm(row,:))<-cutoffSig)
            plot(x_values, 1.5*tracesNorm(row, :) + row, "LineWidth",2,'Color',"#0072BD");
            % Find minimum
            [traceMin, traceMinIdx] = min(tracesNorm(row,:));
            plot(x_values(traceMinIdx),1.5*traceMin + row, '.','MarkerSize',15,'Color',[0.9500 0.5250 0.2980]);
        else
            plot(x_values, 1.5*tracesNorm(row, :) + row, "LineWidth",2,'Color',[0.7 0.7 0.7]);
        end
    end
    ylim([0.9, size(tracesNorm,1)+0.1]);
    timeLength = size(tracesNorm,2)*1000/fs;
    xlim([0.3*timeLength 0.75*timeLength]);
    %xlim([0, timeLength]);
    set(gca, 'XTick', []);
    set(gca, 'YTick', []);  
    xlabel('');
    ylabel('');
    ax = gca;
    ax.Box = 'off';
    axis off;
    box off;
    
    
    % Get trajectory
    [minAmp, peekTime] = min(squeeze(wf.waveFormsMean)');
    
    % Seperate into left/right half of probe
    if mod(minRowIdx,2) == 0                % even = left side of probe
        minAmpO = minAmp(2:2:end);          % O = onesided
        peekTimeO = peekTime(2:2:end);
    else                                    % odd = right side of probe
        minAmpO = minAmp(1:2:end);          
        peekTimeO = peekTime(1:2:end);
    end
    
    % Get minima of traces and track their position in time/space
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
    

    % Exclude threshold crossings if too far away
    condition = abs(distSoma) > 500;
    distSoma = distSoma(~condition);
    peekTimeSig = peekTimeSig(~condition);
    






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
    %disp(['Value 1/v_below is: ' num2str(round(Vbelow_inv,2)) ' ms/mm']);
    
    


    % Plot spatiotemporal trajectory
    subplot(2,4,8);
    hold on;
    plot(peekTimeSig,distSoma,'-','LineWidth',2, 'Color',[0.7 0.7 0.7]);
    plot(peekTimeSig,distSoma,'.','MarkerSize',15,'Color',[0.9500 0.5250 0.2980]);
    plot(regLineXAbove,regLineYAbove,'--','LineWidth',1.5,'Color',[0.6350 0.0780 0.1840]);
    plot(regLineXBelow,regLineYBelow,'--','LineWidth',1.5,'Color',[0.6350 0.0780 0.1840]);
    xlabel("Time relative to soma (ms)");
    ylabel("Distance from soma (µm)");
    title("Trajectory");
    xline(0, '--', 'LineWidth', 1, 'Color', [0.8 0.8 0.8]);  
    yline(0, '--', 'LineWidth', 0.5, 'Color', [0.8 0.8 0.8]); 
    lower_lim = min(min(peekTimeSig)*1.2, max(peekTimeSig)*1.1);
    upper_lim = max(min(peekTimeSig)*1.2, max(peekTimeSig)*1.1);
    if lower_lim ~= upper_lim
           xlim([min(min(peekTimeSig)*1.2, max(peekTimeSig)*1.1)     max(min(peekTimeSig)*1.2,max(peekTimeSig)*1.1)]);
    end
    ylim([min(distSoma)*1.2 max(distSoma)*1.1]);

    % Plot Amplitude Spread
    normAmp = minAmpO(minAmpO <= ampCutoff*minAmpTot)/minAmpTot;

    idxSomaNorm = find(normAmp == 1);

    distSomaNorm = zeros(length(minAmp),1);


    minAmpNormIdx = find(minAmpO <= minAmpTot*ampCutoff);

    distanceNormAmpl = minAmpNormIdx - minAmpNormIdx(idxSomaNorm);
    distSomaNorm = distanceNormAmpl * 30;
    


    %distSomaNorm(idxSomaNorm:end) = [0:30:30*(length(distSomaNorm)-idxSomaNorm)];
    %distSomaNorm(1:idxSomaNorm) = [-30*(idxSomaNorm-1):30:0];
    %distSomaNorm = -distSomaNorm;
    
    subplot(2,4,4);
    plot(distSomaNorm,normAmp);
    hold on;
    plot(distSomaNorm,normAmp,'-','LineWidth',2, 'Color',[0.7 0.7 0.7]);
    plot(distSomaNorm(normAmp<cutoffSig),normAmp(normAmp<cutoffSig),'.','MarkerSize',15,'Color',[0.7 0.7 0.7]);
    plot(distSomaNorm(normAmp>=cutoffSig),normAmp(normAmp>=cutoffSig),'.','MarkerSize',15,'Color', [0.9500 0.5250 0.2980]); % Blue "#0072BD"
    xlabel("Distance to soma (µm)");
    ylabel("Normalized Amplitude");
    title("Amplitude dist.");
    yline(cutoffSig, '--', 'LineWidth', 1, 'Color', [0.8 0.8 0.8]);  
    box off;

    



    % Export figure as png
    folderPath = fullfile(wf.path_output, 'Trajectories'); % Update folder path
    fileName = fullfile(folderPath, ['unit', num2str(id_unit), '_trajectory.png']);
    if ~exist(folderPath, 'dir')
        mkdir(folderPath);
    end
    saveas(gcf, fileName);
    clf;
    close(fig);

end