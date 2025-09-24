% Default mode is normalized

function plot_wt(out,varargin)

options = {'mode','real','events',[],'eventscolor','k','normalize',1,'newfig',0,'freqrange',[],'plot',1,'coi',0,'sig',[],'smooth',0};
options = inputparser(varargin,options);
if strcmp(options,'error'); return; end;

if options.newfig;
    figure;
end

if options.plot
    if strcmp(options.mode,'explore')
        figure;
        subplot(2,2,1)
        tmp = abs(out.S).^2;
        %tmp = bsxfun(@rdivide, tmp, max(tmp,[],2));
        ttt = tmp;
        if options.smooth>0;
            imagevar(out.t,out.f,smoothn(tmp,options.smooth)); axis xy;
        else
            imagevar(out.t,out.f,tmp); axis xy;
        end
        %title('Wavelet time-frequency decomposition');
        %ylabel('Frequency (Hz)');
        %xlabel('Time (s)');
        freezeColors(gca)
        
        subplot(2,2,2) % plot it here, because the other plots change the colormaps, so we should freeze it first
        tmp = real(out.S);
        
        tmp = bsxfun(@rdivide, tmp, max(tmp,[],2));
        
        if options.smooth>0;
            imagevar(out.t,out.f,smoothn(tmp,options.smooth)); axis xy;
        else
            imagevar(out.t,out.f,tmp); axis xy;
        end
        
        ylabel('Frequency (Hz)');
        xlabel('Time (s)');
        freezeColors(gca)
        
        subplot(2,2,4)
        if ~isempty(options.sig)
            plot_lfp(options.sig,'sr',out.options.sr)
        end
        
        subplot(2,2,3)
        tmp = angle(out.S);        
        imagevar(out.t,out.f,tmp); axis xy;
        colormap hsv
        freezeColors(gcf)
        hold on
        tmp = zeros(size(tmp,1),size(tmp,2))-pi;        
        h = imagevar(out.t,out.f,tmp);
        tmp = abs(out.S).^2;
        tmp = bsxfun(@rdivide, tmp, max(tmp,[],2));
        set(h,'AlphaData',1-tmp);
        colormap gray
        %ylabel('Frequency (Hz)');
        %xlabel('Time (s)');               

        link_axes('x')
        
    elseif strcmp(options.mode,'power')
        tmp = abs(out.S).^2;        
        %tmp = abs(out.S .* conj(out.S));        
        if options.normalize==1
            tmp = bsxfun(@rdivide, tmp, max(tmp,[],2));            
            %tmp = zscore(tmp,0,2);
        elseif options.normalize>1
            tmp = bsxfun(@rdivide, tmp, nanmean(tmp(:, 1:round(end/options.normalize)), 2));            
            %tmp = zscore(tmp,0,2);
        end
        
        if options.smooth>0;
            imagevar(out.t,out.f,smoothn(tmp,options.smooth)); axis xy;
        else
            imagevar(out.t,out.f,tmp); axis xy;
        end
        %title('Wavelet time-frequency decomposition');
        ylabel('Frequency (Hz)');
        xlabel('Time (s)');
        %c=colorbar
        %ylabel(c,'Power') 
        cc = 'w';
        
    elseif strcmp(options.mode,'real')
        tmp = real(out.S);
        if options.normalize
            tmp = bsxfun(@rdivide, tmp, max(tmp,[],2));
        end
        if options.smooth>0;
            imagevar(out.t,out.f,smoothn(tmp,options.smooth)); axis xy;
        else
            imagevar(out.t,out.f,tmp); axis xy;
        end     
        %title('Wavelet time-frequency decomposition');
        ylabel('Frequency (Hz)');
        xlabel('Time (s)');
        cc = 'k';
        
    elseif strcmp(options.mode,'phase')
        tmp = angle(out.S);
        imagevar(out.t,out.f,tmp); axis xy;
        colormap hsv
        %phasemap
        freezeColors(gcf)
        hold on
        tmp = zeros(size(tmp,1),size(tmp,2))-pi;
        h = imagevar(out.t,out.f,tmp);
        tmp = abs(out.S).^2;
        tmp = bsxfun(@rdivide, tmp, max(tmp,[],2));
        set(h,'AlphaData',1-tmp);
        colormap gray
        ylabel('Frequency (Hz)');
        xlabel('Time (s)');
        cc = 'w';
    end
end

% Plot events
if ~isempty(options.events);
    plot_events(options.events,options.eventscolor,5,'min');
end;



% plot COI
if options.coi    
    hPatch = patch([out.coi(:,1)' 0 0]*(1/out.options.sr),[out.f out.f(end) out.f(1)],min(abs(out.S(:))),'FaceColor','k','EdgeColor', cc, 'LineWidth',1.3);
    hatchfill(hPatch, 'cross', 45, 10,cc);
    hPatch = patch([out.coi(:,2)' out.N out.N]*(1/out.options.sr),[out.f out.f(end) out.f(1)],min(abs(out.S(:))),'FaceColor','k','EdgeColor', cc,'LineWidth',1.3);
    hatchfill(hPatch, 'cross', 45, 10,cc);
end

axis tight;
if ~isempty(options.freqrange);    
    ylim(options.freqrange);
end;

%fixfig;

