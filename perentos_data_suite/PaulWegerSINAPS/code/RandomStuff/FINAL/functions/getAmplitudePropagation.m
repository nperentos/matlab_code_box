function [peekTimeSig, distSoma, relAmplitudes, Vabove_inv, Vbelow_inv] = getAmplitudePropagation(wf,varargin)


    % Some initial values that can be passed to the function if desired
    if nargin == 2
        cutoffSig = varargin{1};
    else
        cutoffSig = 0.12;   % What minimum amplitude (% of max) is shown in amplitude distribution
    end
    fs = 20000;
  
    
    % Calculate channel with largest spike
    ap = squeeze(wf.waveFormsMean);
    [min_value, min_linear_index] = min(ap(:));
    [minRowIdx, ~] = ind2sub(size(ap), min_linear_index);
    singleChan = ap(minRowIdx,:); 

    
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
    distSoma(idxSoma:end) = [0:30:30*(length(distSoma)-idxSoma)];
    distSoma(1:idxSoma) = [-30*(idxSoma-1):30:0];
    distSoma = -distSoma;
    peekTimeSig = peekTimeO(minAmpSigIdx) / fs * 1000;
    peekTimeSig = peekTimeSig - peekTimeSig(distSoma==0);

    relAmplitudes = minAmpSig / minAmpTot;

    
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
    %disp(['Value 1/v_above is: ' num2str(Vabove_inv) ' ms/mm']);   
    
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
    %disp(['Value 1/v_below is: ' num2str(Vbelow_inv) ' ms/mm']);
    
    
    % Plot spatiotemporal trajectory
    % subplot(4,5,[14,15,19,20]);
    % hold on;
    % plot(peekTimeSig,distSoma,'-','LineWidth',2, 'Color',[0.7 0.7 0.7]);
    % plot(peekTimeSig,distSoma,'.','MarkerSize',15,'Color',[0.9500 0.5250 0.2980]);
    % plot(regLineXAbove,regLineYAbove,'--','LineWidth',1.5,'Color',[0.6350 0.0780 0.1840]);
    % plot(regLineXBelow,regLineYBelow,'--','LineWidth',1.5,'Color',[0.6350 0.0780 0.1840]);
    % xlabel("Time relative to soma (ms)");
    % ylabel("Distance from soma (µm)");
    % title("Spike trajectory (single sided)");
    % xline(0, '--', 'LineWidth', 1, 'Color', [0.8 0.8 0.8]);  
    % yline(0, '--', 'LineWidth', 0.5, 'Color', [0.8 0.8 0.8]);  
    % xlim([min(peekTimeSig)*1.2 max(peekTimeSig)*1.1]);
    % ylim([min(distSoma)*1.2 max(distSoma)*1.1]);

    


end