% input is the output structure of the specmt function

%  Dependencies: inputparser, sem, spikes_in_periods

function out1 = plot_spectra(out,ch,varargin)
% Input parsing
options = {'mode','spectrogram','log',1,'events',[],'eventscolor','k','eventsLineThickness',[1],'plot3',0,'smooth',0,...
    'normalize',0,'newfig',1,'freqrange',[],'periods',[],'bins',[],'plot',1,'smoothgauss',0,'ylog',0};
options = inputparser(varargin,options);

if nargin<2
    if size(out.Sxy,3)==1;
        ch=1;
    else
        disp('Please provide a channel.');
        return
    end
end;

t = out.t;
f = out.f;
bins = 1:size(out.Sxy,1);

if ~isempty(options.periods) & isempty(options.bins); [t,bins] = spikes_in_periods(t,options.periods); end;
if ~isempty(options.bins); t=t(options.bins); bins = options.bins; end;

%% Calculate
if strfind('spectrogram',options.mode)==1 &  length(ch)==1;
    S = abs(out.Sxy(:,:,ch,ch));
    %Smean = [mean(S(bins,:)) ; sem(S(bins,:))];
    Smean = nanmean(S(bins,:));
    type=1;
    disp 'type is 1';
    
elseif strfind('spectrogram',options.mode)==1 &  length(ch)==2;
    S = abs(out.Sxy(:,:,ch(1),ch(2)));
    %Smean = [mean(S(bins,:)) ; sem(S(bins,:))];
    Smean = nanmean(S(bins,:));
    type=2;
    
elseif strfind('coherogram',options.mode)==1 &  length(ch)==2;
    S = abs(out.Sxy(:,:,ch(1),ch(2)).^2)./(out.Sxy(:,:,ch(1),ch(1)) .* out.Sxy(:,:,ch(2),ch(2)));
    Smean = ((abs(nansum(out.Sxy(bins,:,ch(1),ch(2))))).^2)./(nansum(out.Sxy(bins,:,ch(1),ch(1))).*nansum(out.Sxy(bins,:,ch(2),ch(2))));
    type=3;
    
elseif strfind('imcoherogram',options.mode)==1 &  length(ch)==2;
    % Imaginary Coherence : here I calculate it using the sqrt, so that I
    % can retain the sign of the imaginary part.
    % Values range from -1 to 1
    % The sign indicates directionality (see Nolte 2004). +: from 1 --> 2, -: from 2 --> 1
    S = imag(out.Sxy(:,:,ch(1),ch(2)))./sqrt(out.Sxy(:,:,ch(1),ch(1)) .* out.Sxy(:,:,ch(2),ch(2)));
    Smean = (imag(nansum(out.Sxy(bins,:,ch(1),ch(2)))))./sqrt(nansum(out.Sxy(bins,:,ch(1),ch(1))).*nansum(out.Sxy(bins,:,ch(2),ch(2))));
    type=4;
    
elseif strfind('phasespectrogram',options.mode)==1 &  length(ch)==2;
    S = angle(out.Sxy(:,:,ch(1),ch(2)));
    Smean = [];
    type=5;
    
elseif strfind('phasecoherogram',options.mode)==1 &  length(ch)==2;
    S = angle(out.Sxy(:,:,ch(1),ch(2)).^2); % Normalizing here (by Sxx.*Syy) has no effect
    % By definition this is: atan(imag(Sxy)./real(Sxy));
    Smean = [];
    type=6;
    
else
    disp('Unknown mode');
    return
end

%% Modify spectra
if ~isempty(options.freqrange);
    fidx = (f>=options.freqrange(1) & f<=options.freqrange(2));
    f = f(fidx);
    S = S(:,fidx);
    Smean = Smean(fidx);
end;

if options.log & type<3; % Only for spectrograms
    S = 20*log10(S);
    Smean = 20*log10(Smean);
end

out1.S = S;
out1.f = f;
out1.t = out.t;
out1.Smean = Smean;

if options.normalize & type<3; % Only for spectrograms
    S = bsxfun(@rdivide,S,mean(S,2));
end;


if options.smooth>0;
    S = smoothn(S, options.smooth);
end;

if options.smoothgauss>0;
    S = imgaussfilt(options.smoothgauss);    
end;

%% Ploting
if isempty(options.bins) & isempty(options.periods) & options.plot;
    
    if options.ylog==1; % sub-log scale
        idx = size(S,2)+1 - cell2mat(arrayfun(@(x) repmat(x,1,x),1:size(S,2),'un',0));
        idx1 = round(linspace(1,length(idx),length(f)));
        idx = idx(idx1);        
        f1=f(idx);
        S = S(:,idx);
    elseif options.ylog==2; % real log scale
        [~,idx]=find_nearest(logspace(log10(max(f)),log10(min(f)),length(f)),f); 
        f1=f(idx);
        S = S(:,idx);
    end
    
    if options.newfig;
        figure;
    end
    
    if options.plot3
        out1.h = surf(f,t,S,'edgecolor','none');
    elseif sum(isnan(S(:)))>1 & ~options.ylog;
        out1.h = imagescnan(t,f,abs(S)'); colorbar;
    elseif sum(isnan(S(:)))>1 & options.ylog;
        
    elseif ~(sum(isnan(S(:)))>1) & options.ylog;
        out1.h = imagesc(t,1:size(S,2),abs(S)'); colorbar;
        idx = 1:round(0.1*size(S,2)):size(S,2);
        %idx = [round(min(f)):2:round(max(f))];
        idx = logspace(log10(min(f)),log10(max(f)),0.1*length(f));
        idx = round(idx);
        [~,idx]=find_nearest(idx,f1);
        idx=sort(unique(idx));
        set(gca,'YTick',idx,'YTickLabel',round(f1(idx)));
        out1.f1 = f1;
    elseif ~(sum(isnan(S(:)))>1) & ~options.ylog;
        out1.h = imagesc(t,f,abs(S)'); colorbar;
        axis xy;
    end
    
    
    
    
    % Main plotting
    axis tight; %colorbar;
    xlabel('Time (s)');
    ylabel('Frequency (Hz)');
    box off;
    set(gca,'TickDir','out');
    
    % Set circular colormap
    if ismember(type,[5 6]); circ_colormap; end;
    
    % Plot events
    if ~isempty(options.events);
        plot_events(options.events,options.eventscolor,options.eventsLineThickness,'min');
    end;
    
elseif options.plot && type<=4; % This is the case when a period/bins have been provided so it plots the normal spectrum/coherence of the period
    if options.newfig;
        figure;
    end
    
    
    out1.h = jplot(f,Smean);
    
    if options.log & type<3; % Only for spectrograms
        ylabel('Power (dB)');
    elseif ~options.log & type<3;
        ylabel('Power (a.u.)');
    elseif type==3;
        ylabel('Coherence');
    elseif type==4;
        ylabel('Imaginary Coherence');
    end
    
    
    xlabel('Frequency (Hz)');
    box off;
    set(gca,'TickDir','out');
    
end;