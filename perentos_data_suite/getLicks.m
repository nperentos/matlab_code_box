function [out] = getLicks(ch,varargin)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% [lick_activity, lick_events] = getLicks(ch,varargin) takes as input the
% lfp of the licking sensor (default rate of 1000Hz) and extracts a
% smoothed version of its activity and licking events as from the above
% activity through thresholding
% MUST PASS LFP NOT DAT!!
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% PRE 
    fprintf('computing licking...');
    options = {'decFlag','1','lfpSR',1000,'vis',0,'thr',95,'fileBase',[]};
    options = inputparser(varargin,options);
    if strcmp(options,'error'); return; end;
    tScale = 1/options.lfpSR:1/options.lfpSR:length(ch)/options.lfpSR;
    
%% SMOOTHED LICKING ACTIVITY (continuous, no thresholding)
    licks = abs(hilbert(ch));
    ch2 = ButFilter(licks,4,[30]/options.lfpSR,'low');
    ch2(ch2<0) = median(ch2);
    ch2 = ch2 - median(ch2);
    % eegplot([ch;licks;ch2],'srate',1000,'color','on','spacing',500);

    
%% LICKING EVENTS
    threshold = prctile(ch2,options.thr);
    [a,b,c,d]=findpeaks(ch2,'minpeakheight',threshold,'minpeakdistance',options.lfpSR/14); % ,'minpeakprominence',prctile(ch2,90)
    ev = zeros(size(ch2));
    ev(b)=a; % can use variable a to track the peak value
    %eegplot([ch;ch2;ev],'srate',1000,'color','on','spacing',500);


%% SUMMARY FIGURE

hh = newA4Fig;

% spectrogram of licking
    op.defaults = 'theta';
    S1 = specmt(ch,op);
    %subplot(411); imagesc(S1.t,S1.f,log10(S1.Sxy'));axis xy; caxis([0 10]);
    S2 = specmt(ch2,op);
    subplot(4,2,[1 2]); imagesc(S2.t,S2.f,log10(S2.Sxy'));axis xy; caxis auto; %caxis([0 10]);
    hold on; plot(xlim,[7 7],'--w','linewidth',2);
    %plot(mean(S1.Sxy,1)./max(mean(S1.Sxy,1)));
    %hold on;
    xlabel('time (s)');ylabel('frequency (Hz)');
 
%  traces of raw licking sensor and detected events
    subplot(4,2,[3 4]); 
    %plot(tScale,ch);
    hold on; 
    plot(tScale,ch2,'k');    
    hold on; 
    plot(tScale((ev>0)),ev(ev>0),'*r','markersize',1);
    axis tight;
    plot(xlim,[threshold threshold],'--r','linewidth',2);
    xlabel('time (s)');ylabel('piezo amplitude (\mu)');
    %linkaxes(get(gcf,'children'),'x')
    ylim([0 prctile(ch2,99.5)]);
    
% lets add a zoomed in version by finding 10 seconds with many licks
    subplot(4,2,[5 6]); cla
    %plot(tScale,ch);
    hold on; 
    plot(tScale,ch2,'k','linewidth',2);    
    hold on; 
    plot(tScale((ev>0)),ev(ev>0),'vr','markersize',5,'markerfacecolor','r');
    axis tight;
    plot(xlim,[threshold threshold],'--g','linewidth',2);
    incr = 1; ww = 10;%window size in seconds
    for i = 1:options.lfpSR*ww:length(ev)-options.lfpSR*ww
        suma(incr) = sum(ev(i:i-1+options.lfpSR*ww));
        incr = incr + 1;
    end
    [~,iz] = max(suma);
    zr = [iz-0.5, iz+0.5]*ww;
    xlim(zr);
    xlabel('time (s)');ylabel('piezo amplitude (\muV)');
    
    

    
% mean spectrum of licking
    subplot(4,2,7); 
    plot(S2.f,mean(S2.Sxy,1)./max(mean(S2.Sxy,1)),'color','k','linewidth',2);
    hold on;plot([7 7],ylim,'--r','linewidth',2);
    xlabel('frequency (Hz)');ylabel('spectral power (normalised)');

    
% interlick interval    
    subplot(4,2,8);
    histogram(options.lfpSR./diff(b),[0:0.2:20],'edgecolor','k','facecolor','k');
    hold on;plot([7 7],ylim,'--r','linewidth',2);
    text(max(xlim)*.9,max(ylim)*.9,['n=',num2str(length(b))],'fontsize',14,'horizontalalignment','right');
    xlabel('inter-lick rate (Hz)');ylabel('licks (counts)');
    
    
% pretty    
    mtit('licking summary','fontsize',20)
    ForAllSubplots('set(gca,''fontsize'',14,''box'',''off'')'); 
 
    
% should save in the right location if we are already there (should be from where we called this function)    
    %print(fullfile(getfullpath(fileBase),'lickin_summary.jpg'),'-djpeg');
    if isempty(options.fileBase)
        print('lickin_summary.jpg','-djpeg');
    else
        print(fullfile(getfullpath(options.fileBase),'lickin_summary.jpg'),'-djpeg');
    end
  
    
    
%% OUTPUTS
    out.activity = ch2;
    ev(ev>0) = 1;
    out.events = ev; % sparse
    fprintf('DONE\n');
















