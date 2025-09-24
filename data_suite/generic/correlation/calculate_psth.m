function [psth, bins] = calculate_psth(spiketrain, varargin)

if nargin<1;
    display('Please provide the necessary arguments')
    return;
end;

% Input parsing
options = {'events',[],'time',[min(spiketrain), max(spiketrain)],'binsize',0.01,'windowsize',0.5, 'plot',0,'method','bins','zscore','off','zscoremethod','baseline','cumsum',0};
options = inputparser(varargin,options);
if strcmp(options,'error'); return; end;

if strcmp(options.method,'bins')
    if ~isempty(options.events)
        psth=[];
        for c=1:length(options.events);
            start = options.events(c)-options.windowsize;
            stop = options.events(c)+options.windowsize;
            bins1 = linspace(start,options.events(c),options.windowsize/options.binsize+1);
            bins2 = linspace(options.events(c),stop,options.windowsize/options.binsize+1);
            bins = [bins1 bins2(2:end)];
            psth = add_matrix(psth,histc(spiketrain,bins));
        end;
        bins1 = linspace(-options.windowsize+options.binsize/2,-options.binsize/2,options.windowsize/options.binsize);
        bins2 = linspace(options.binsize/2,options.windowsize-options.binsize/2,options.windowsize/options.binsize);
        bins = [bins1 bins2];
        psth=psth(1:end-1); % To return/plot the psth without the last bin;
        
        if strcmp(options.zscore,'on')
            if strcmp(options.zscoremethod,'baseline')
                if std(psth(1:floor(end/2)))~=0
                    psth=(psth - mean(psth(1:floor(end/2))))./std(psth(1:floor(end/2)));
                end;
            elseif strcmp(options.zscoremethod,'all')
                if std(psth)~=0
                    psth=(psth - mean(psth))./std(psth);
                end;
            elseif strcmp(options.zscoremethod,'maxfreq')
                if max(psth)>0;
                    psth=psth./max(psth);
                end;
            end;
        end;
        
        if options.plot;
            figure;
            bar(bins,psth);
            hold on; line([0 0], get(gca,'Ylim'),'Color','r'); hold off;
            if strcmp(options.zscore,'on')
                hold on;
                line(get(gca,'Xlim'),[1.65 1.65],'Color','k','LineStyle','--');
                line(get(gca,'Xlim'),[-1.65 -1.65],'Color','k','LineStyle','--');
                hold off;
            end;
        end;
        
    else % Non event psth
        bins = linspace(options.time(1),options.time(2),(options.time(2)-options.time(1))/options.binsize+1);
        psth=histc(spiketrain, bins);
        if options.plot;
            bar(bins,psth,'k')
        end;
    end;
    
    % to write
elseif strcmp(method,'CCG')
    
    % to write
elseif strcmp(method,'slidingwindow')
    psth=0;
    return
    
    % to write
elseif strcmp(method,'kernel')
    psth=0;
    return
end;

if options.plot;
    xlabel('Time (s)');
    if strcmp(options.zscore,'on'); ylabel('Z-score'); else ylabel('Count'); end;
    
end;
if options.plot && options.cumsum
    figure;
    plot(bins,cumsum(psth),'k')
    box off; set(gca,'TickDir','out');
    xlabel('Time (s)'); ylabel('Count');
end;