function [A_line,W_line,A,W,power_ratio,line_thrd] = getLineNoise(x,varargin)
% [A_line,W_line,A_rm_line,W_rm_line] = EMG_rm_linenoise(wx,[line_thrd,lfpSampleRate])
% 
% This function is intend to remove the line noise here. To reconstruct the
% signal without EMG noise, do: x = x-x*W_line'*A_line' (x in nt*nch)
% 
% Inputs: 
%   x: data, nt x nch.
%   Optional: 
%   line_thrd: power ratio between line band and other band. 
%                  defualt: 1.8, I'm being conservative here.
%   lfpSampleRate: default: 1250
%   show_line_noise: default: false
% 
% Outputs:
%   A_line: the mixing vector of line noise component
%   W_line: the unmixing vector of line noise component
%   A: the mixing matrix of the line noise component
%   W: the unmixing matrix of the line noise component
%   power_ratio
%   line_thrd
% 
% Related functions: 
% EMG_rm_long.m, EMG_rm_main.m.
% This function is a part of the EMG_removing toolbox. But could serve
% general purpose. 
%  
% Error contact: chen at biologie.uni-muenchen.de
% 
% Last Modified: 11.12.2019.
% This is NPerentos local and modified copy. 
%% PRE
    [line_thrd,lfpSampleRate,show_line_noise] = DefaultArgs(varargin, {1.8, 1000,false});

    [nt,nch] = size(x);
    if nt<nch
        warning('Wrong dimension of the data matrix. Shifted. ')
        x = x';
        [nt,nch] = size(x);
    end
    [A, W] = fastica(x', 'verbose','on');

    x = x*W';
    yo = [];
    for k = 1:size(x,2)
        [yo(:,k), fo] = mtcsdfast(x(:,k),[],lfpSampleRate);
    end
    
%% LINE NOISE
    line_noise_band = false(size(fo));
    for k = 1:floor(lfpSampleRate/50)
        line_noise_band(fo<(k*50 +5) & fo>(k*50 -5)) = true;
    end

    power_ratio = mean(yo(line_noise_band,:))./mean(yo(~line_noise_band,:));
    ids = find(power_ratio>line_thrd/2);
    A_line = A(:,ids);
    W_line = W(ids,:);


%% SUMMARY PLOT AND SAVE?
    ss=4;
    tScale = 1/lfpSampleRate:1/lfpSampleRate:1*ss;
    %clrs = {}; clrs(1:size(x,2)) = deal({'k'});clrs(ids) = deal({'r'}); 
    %eegplot(x','srate',1000,'color',clrs)
    ColorSpec = [ones(size(x,2),1), zeros(size(x,2),2)];
    ColorSpec = [zeros(size(x,2),3)];
    for i = 1:length(ids)
        ColorSpec(ids(i),:) = [1 0 0];
    end
    %figure; eegplot(x(1:lfpSampleRate,:)','srate',lfpSampleRate,'color',clrs)
    figure('units','normalized','outerposition',[0 0 1 1]);
    ax = axes;
    ax.ColorOrder = ColorSpec;
    ax.NextPlot = 'add';
    plot(tScale,bsxfun(@plus, x(1:ss*lfpSampleRate,:), [1:size(x,2)]*2),'linewidth',2);
    axis tight;
    xlabel('time (s)');ylabel('independent components');title('red line(s): 50 Hz components');
    ForAllSubplots('set(gca,''fontsize'',16,''box'',''off'')'); 
    print('lineNoise.jpg','-djpeg');
