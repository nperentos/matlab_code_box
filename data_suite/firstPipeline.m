    function firstPipeline(fle, chPyr, tS)

%% FIRST PIPELINE
% INPUTS:
% chPyr - a pyramidal layer channel for spectrogramsz
% tS - total seconds to use for theta speed correlation

% given a path, run the following preliminary analysis steps
% 1.  Check and if not convert data and create *.dat and *.lfp files
% 2.  Extract the peripheral channels (licking, carousel and running
        % encoders, speed of running, animal location, vidFrameTimes
% 3.  Visualise these channels to confirm it all makes sense
% 4.  Check if licking is modulated by location
% 5.  Generates some example spectrograms - to select which channel to use
        % set the chPyr input variable to the channel number you desire
% 6.  Curate pupil data and save into mat file
% 7.  Generate a speed vs theta correlation
% 8.  Visualise speed, pupil data theta power as a fun. of trial and locat

%% VALIDATE INPUT VARIABLES
if nargin < 3; tS = 900; end
if nargin < 2; chPyr = 29; end
if nargin < 1; error('you must specify a folder to process'); end
    
%% things to feed into this function
chPyr = 29; % select one lfp channel with good theta
tS = 900;

% % % %% DATA CONVERSION
% % % % check if data has been converted already
% % % fldr = 'NP1_2018-04-10_10-22-25';
% % % % pth = [getFullPath(fldrNme),'processed'];
% % % pth = getFullPath(fldr);
% % % ifConvert = 0;
% % % if size(dir([pth,'processed']),1) < 9
% % %     ifConvert = 1;
% % % end
% % % % data conversion
% % % if ifConvert
% % %     options.lfpSR=1000;
% % %     options.mapping= oemaps.P2;
% % %     options.numcores=[];
% % %     options.downsampleparallel=1;
% % %     options.period=[];%[1.3609e3, 2.5648e3];
% % %     options.jumpoverride=1;
% % %     options.appendchannels=1;
% % %     openephys2dat(pth,options);
% % % end
li

%% CHECK IF DATA CONVERTED, IF NOT, CONVERT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
convertData(fle);% dont forget the map

%% GET DATA %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%fldr = 'NP3_2018-04-11_19-37-06';
processedPath = getfullpath(fle); % folder to keep processed data figs etc
% check if peripherals structure was already generated
if exist([processedPath,'peripherals.mat'],'file') == 2
    disp '>loading preprocessed peripherals<';
    load([processedPath,'peripherals.mat']);
else
    disp '>generating peripheral channels<';
    % get all channels into workspace
    [data,settings,tScale] = getLFP(fle);
    [chanTypes] = getChanTypes(settings);
    chPeriph = find(chanTypes == 2);

    if numel(chPeriph) == 4
        runCh = chPeriph(1); lickCh = chPeriph(2); carouselCh = chPeriph(3); rewardCh = chPeriph(4); 
    elseif numel(chPeriph) == 5
        runCh = chPeriph(1); lickCh = chPeriph(2); carouselCh = chPeriph(3); rewardCh = chPeriph(4); vidPulsesCh = chPeriph(5);
    elseif numel(chPeriph) == 8 %(photometry on 6 and empty on 7&8)
        runCh = chPeriph(1); lickCh = chPeriph(2); carouselCh = chPeriph(3); rewardCh = chPeriph(4); vidPulsesCh = chPeriph(5); AChPulsesCh = chPeriph(6);
    else
        error('I was expecting 4 or 5 ADC channels - aborting');
    end

    % need 30kHz to detect all the pulses from encoders
    [data30k,settings30k,tScale30k] = getDAT(fle,chPeriph);

    rewards         = getRewards(data30k(4,:));             % REWARD TIMEPOINTS - reward channel = 38
    runSpeed        = getRunSpeed(data30k(1,:));            % RUNNING SPEED
    carouselSpeed   = getCarouselSpeed(data30k(3,:));       % CAROUSEL SPEED 
    %location        = getLocation(data30k(3,:),rewards);    % CAROUSEL LOCATION for single direction
    [location, direction] = getLocation_v2(data30k(3,:),rewards);
    %locationTD        = getLocationTwoDirections(ch,rewards); % for bidirectional CAROUSEL LOCATION
    licks           = getLicks(data(lickCh,:));           % LICKING AS A FUNCTION OF LOCATION     
    if numel(chPeriph) == 5
        vidPulses       = getVidTimes(data30k(5,:));        % A PULSE FOR EACH ACQUIRED VIDEO FRAME    
    end
    if numel(chPeriph) == 8 || numel(chPeriph) == 6 % or 6 depending on the OE pipeline used
        vidPulses      = getVidTimes(data30k(5,:));        % A PULSE FOR EACH ACQUIRED VIDEO FRAME    
        AchPulses      = getVidTimes(data30k(6,:));
    end
    
    %data([68:101 107:109]+1,:)=[];
    %data([0,5:31,96:101,107:109]+1,:) = [];
    %data = data([1:16 36:41],:);
    % load also network events (such as auditory stimulation marked through
    % network events interace together with startExperiment.py
    cd ..
    netEvfle = 'messages.events';
    fid = fopen(netEvfle);    
    linenum = 4;
    delimiter = ' ';
    formatSpec = '%f%s%s%s%s%f%s%f%s%s%s%[^\n\r]';
    ev = textscan(fid, formatSpec, 'Delimiter', delimiter, 'MultipleDelimsAsOne', true, 'EmptyValue' ,NaN, 'ReturnOnError', false);
    fclose(fid);
    ev = ev{1,1};ev(1) = [];ev = ev-ev(1);ev(1)=[];
    save([processedPath,'peripherals.mat'],'data','rewards','runSpeed','carouselSpeed','location','direction','licks','tScale','vidPulses','settings', '-v7.3');% ,'AchPulses'
end


%% VISUALISE PERIPHERAL CHANNELS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ifPlot = 1;
if ifPlot
    % close all;
    figure; hold all;
    % run and carousel speeds
    h(1) = subplot(211);
    plot(tScale,runSpeed,'color',[0 .1 1],'linewidth',1.1); hold on; %h(1) = gca;
    plot(tScale,carouselSpeed,'color','k','linewidth',1.1); axis tight;
    drawPatches(h(1), [tScale(rewards.atStart); tScale(rewards.atStart)+0.2]');
    Lh = findobj(gca,'Type','line');
    legend(Lh,{'carousel speed','run speed'}); ylabel('speed (cm/s)');
    xlabel('time (s)'); box off;
    % licking and location
    h(2) = subplot(212);
    locRescaled = (location./(max(location)-min(location)))*2*pi;
    plot(tScale,locRescaled,'color','k','linewidth',1.1); hold on; % plot([0 max(tScale)],[4096 4096],'k');
    ylim([0 2*pi]);
    set(gca,'ytick',[0 pi/2 pi 3*pi/2 2*pi], 'yticklabel',{'0' ,'\pi/2' '\pi' '3\pi/2' '2\pi'});
    plot(tScale,licks.*max(ylim)/2,'color',[1 0.1 1 0.5],'linewidth',1.1); axis tight;
    drawPatches(h(2), [tScale(rewards.atStart); tScale(rewards.atStart)+0.2]');
    Lh = findobj(gca,'Type','line');
    legend(Lh,{'licking','location'});
    linkaxes(h,'x');
    xlabel('time (s)');
    ylabel('carousel position');
    xlim([0 max(tScale)]);
    box off;
    cd(processedPath);
    if exist([processedPath,'peripheralsOverview.jpg'],'file') ~= 2        
        print([processedPath,'peripheralsOverview'],'-djpeg','-r300');
    end
    xlim([tScale(rewardss.atStart(4)) tScale(rewardss.atStart(10))]);
    if exist([processedPath,'peripheralsOverviewZoom.jpg'],'file') ~= 2        
        print([processedPath,'peripheralsOverviewZoom'],'-djpeg','-r300');
    end
end

%% LICKING ANALYSIS
figure; set(gcf,'position',[2726 60 683 723]);
% licking as a function of carousel location
from = find(tScale >= tScale(rewards.atStart(1)),1,'first');
to = find(tScale >= tScale(rewards.atStart(60)),1,'first');
lickCh = 70;

%select periods around start points
Periods = [rewards.atStart-20e3 rewards.atStart+20e3];
[y, ind] = SelectPeriods(locRescaled,Periods);
ind = unique(ind);

locEdges = linspace(min(locRescaled(ind)),max(locRescaled(ind)),20);
positionInd = discretize(locRescaled(ind),locEdges);
lickAnalog = abs(hilbert(data(lickCh,ind)));
mulr = accumarray(positionInd',lickAnalog,[numel(locEdges),1],@mean); % mlr = (mlr-mean(mlr))./(max(mlr)-min(mlr))
stdlr = accumarray(positionInd',lickAnalog,[numel(locEdges),1],@std); % slr = (slr-mean(slr))./(max(slr)-min(slr));
sumlr = accumarray(positionInd',lickAnalog,[numel(locEdges),1],@sum);
subplot(3,2,[1 2]);
shadedErrorBar( locEdges(1:end-1),  mulr(1:end-1),  stdlr(1:end-1)./sqrt(numel(rewards.atStart)), 'k');
hold on;
%shadedErrorBar( locEdges(1:end-1),  sumlr(1:end-1),  stdlr(1:end-1)./sqrt(numel(rewards.atStart)), 'k');
set(gca,'xtick',[0,pi/2,pi,3*pi/2,2*pi],'xticklabel',{'0' ,'\pi/2' '\pi' '3\pi/2' '2\pi'}); xlim([0 2*pi]);
xlabel('position (cm)'); ylabel('licking (A.U.)'); box off;
cage1 = (120/360)*2*pi;
cage2 = (120*2/360)*2*pi;
hold on; 
plot([cage1 cage1],ylim,'--r');    text(cage1,max(ylim)*.9,'cageR');
plot([cage2 cage2],ylim,'--r');    text(cage2,max(ylim)*.9,'cageL');
plot([0 0],ylim,'--r');        text(0,max(ylim)*.9,'reward');
plot([locEdges(end-1) locEdges(end-1)],ylim,'--r'); text(locEdges(end-1),max(ylim)*.9,'reward','HorizontalAlignment','center');

% licking around the start point as a function of time
secs = 10;win = 1; xax = linspace(-secs/2,secs/2,secs/win);
[out,excluded] = trig_lfp(licks,rewards.atStart, secs*win*win*1e3);
out(:,end)=[];
out2 = reshape(out,size(out,1),size(out,2)/secs,secs);
tbl = squeeze(sum(out2,2));
subplot(323);
imagesc(xax,[],tbl);hcl = colorbar; xlabel(hcl,'licks (n)');
ylabel('trial (n)');xlabel('time (s)'); hold on;
subplot(324);
plot(xax,mean(tbl(1:size(tbl,1)/2,:            ))); hold on;
plot(xax,mean(tbl(1+size(tbl,1)/2:size(tbl,1),:)));
ylabel('licks/s (n)');xlabel('time (s)');box off;
lg=legend('first half','second half');set(lg,'color','none','box','off');
% licking frequency around events
out = specmt(data(lickCh,:),'defaults','theta'); % get the spectrogram
[ltS,t,f] = trig_spec(out,tScale(rewards.atStart), 10);% 10 is window length
subplot(325);imagesc(t,f,squeeze(mean(ltS(:,:,1:numel(rewards.atStart)/2),3))'); axis xy;
ylabel('lick freq. (Hz)');xlabel(['time (s) [trials 1:',num2str(length(rewards.atStart)/2),']']); hold on;
subplot(326);imagesc(t,f,squeeze(mean(ltS(:,:,1+numel(rewards.atStart)/2:numel(rewards.atStart)),3))'); axis xy;
ylabel('lick freq. (Hz)');xlabel(['time (s) [trials ',num2str(1+length(rewards.atStart)/2),':',num2str(length(rewards.atStart)),']']);
if exist([processedPath,'lickingAnalysis.jpg'],'file') ~= 2        
    print([processedPath,'lickingSummary'],'-djpeg','-r300');
end

%% alternative analysis for licking - extract segments around arrival points
% to the center and from there create a single array that contains the time
% points to be included
Periods = [rewards.atStart-20e3 rewards.atStart+20e3];
[y, ind] = SelectPeriods(location,Periods);
ind = unique(ind); % this is the indices of datapoints to include in the licking detection
locEdges = linspace(min(location(ind)),max(location(ind)),20);
positionInd = discretize(location(ind),locEdges);
sumlr = accumarray(positionInd',licks(ind),[numel(locEdges),1],@sum);


%% CURATE PUPIL data%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% run pupil summary which will return nan if no processed data is
% found. If not found then you must manually run the pupil detection
% functions
%pupilH = pupilSummary(fldr);
curatePupilData(fle,1,1);
load([processedPath,'pupilResults.mat']);
%set(gcf,'pos',[1 64 957 1117]);
%frameTimes = linspace(tScale(1),tScale(end),numel(frameTimes));

%% ALL SPECTROGRAMS FOR THETA, GAMMA, RIPPLES AND UNIVERSAL %%%%%%%%%%%%%%%%%%%
% general spectrograms for inspection
% theta_w=2s, gamma_w = 0.1s, ripple_w = 0.1, univresal_w = 2.5s
ifRun = 0;
if ifRun
    specgramTypes = {'theta';'ripples'};%;'theta';'gamma';'ripples';'universal'};
    [a,b] = numSubplots(size(data,1));
    for i=1:length(specgramTypes)
        close all; figure(1); figure('Position',[0 40 2560 1287]);    
        for ch = 1:size(data,1) 
            clear options;
            options.defaults = specgramTypes{i};
            out = specmt(data(ch,:),options);
            clear options;
            options.mode = 'spectrogram';
            options.events = rewards.soundIdx./1000;
            options.eventscolor = 'k';    
            figure(1); clf;
            out1 = plot_spectra(out,1,options);
            delete(colorbar); xlabel('');ylabel('');
            h = get(gcf,'Children');
            figure(2);
            ax = subplot(a(2),a(1),ch);
            axD = get(ax,'Position');delete(ax);
            tmph(ch) = copyobj(h,2);       
            set(tmph(ch),'Position',axD);
            if ch ~= 1; axis off; end         
        end   
        figure(2);         
        if exist([processedPath,'session_spgram_all_ch_',specgramTypes{i}],'file') ~= 2        
            print([processedPath,'session_spgram_all_ch_',specgramTypes{i}],'-djpeg','-r300');
        end
    end
end

%% SINGLE HPC SPECTROGRAM FOR THETA, GAMMA, RIPPLES AND UNIVERSAL %%%%%%%%%%%%%%%%%%%
% theta_w=2s, gamma_w = 0.1s, ripple_w = 0.1, univresal_w = 2.5s
ifRun = 1;
if ifRun
    disp '>generating requested spepctrograms (for visualisation) <';
    specgramTypes = {'theta';'ripples'};%'gamma';'ripples';'universal'};
    wltxt = {'thetaW=2s','gammaW = 0.1s'};
    [a,b] = numSubplots(size(data,1));
    for i=1:length(specgramTypes)
        close all; figure(1); figure('Position',[0 40 1000 800]);    
        for ch = chPyr
            clear options;
            options.defaults = specgramTypes{i};
            out = specmt(data(ch,:),options);
            clear options;
            options.mode = 'spectrogram';
            figure(1); clf;
            out1 = plot_spectra(out,1,options);
            xlabel('time (s)'); ylabel('frequency (Hz)');        
        end  
        title(wltxt{i});        
        if exist([processedPath,'session_spgram_ch_',int2str(ch),'_',specgramTypes{i}],'file') ~= 2        
            print([processedPath,'session_spgram_ch_',int2str(ch),'_',specgramTypes{i}],'-djpeg','-r300');
        end
        % linkaxes(tmph,'x','y');    
    end
end

%% SPEED AND THETA CORRELATION
clear out; clear options; options.defaults = 'theta';
out = specmt(data(chPyr,:),options);
thetaP = mean(out.Sxy(:,(out.f>5 & out.f<10)),2);
thetaP = thetaP(out.t<=tS);

% speed theta correlation
locAtSpectrPoints = spline(tScale(tScale<=tS),location(tScale<=tS),out.t(out.t<=tS)); % <300 is task
positionInd = discretize(locAtSpectrPoints,locEdges);
runSpeedAtSpectrPoints = spline(tScale(tScale<=tS),runSpeed(tScale<=tS),out.t(out.t<=tS)); 
figure;
mdl = fitlm(runSpeedAtSpectrPoints,normalize_array(thetaP));
plot(mdl); axis tight;
xlabel('speed (cm/s)'); ylabel('theta power (normalised)');

if exist([processedPath,'thetaSpeedCorr_ch_',int2str(chPyr)],'file') ~= 2        
    print([processedPath,'thetaSpeedCorr_ch_',int2str(chPyr)],'-djpeg','-r300');
end

%% 2D heat maps x-axis:position, y-axis:trials, color:(occupancy,theta power, speed, pupil size, pupil positionX, pupil positionY)
% location,trials and theta power 2d heat map
locEdges = linspace(0,max(locAtSpectrPoints),20);
positionInd = discretize(locAtSpectrPoints,locEdges);
tTmp = out.t(out.t<=tS);
trialInd = discretize(tTmp,[-inf,tScale(rewards.soundIdx(tScale(rewards.soundIdx)<=tS)),inf]); % index time variable according to trials
trialInd = trialInd(2:end-1);
figure('pos',[836 174 806 734]);

%--------------------------------------------------------------------------
% theta power as a function of location and trial
subplot(321);
clear lst mlr slr;
lst = unique(trialInd);
for i = 1:length(lst)-1
    idx = find(trialInd == lst(i));
    mulr(:,i) = accumarray(positionInd(idx),thetaP(idx),[numel(locEdges)-1,1],@mean);
    %slr(:,i) = accumarray(positionInd(idx),thetaP(idx),[numel(locEdges)-1,1],@std);
end
imagesc(locEdges',lst',mulr'); colorbar;
axis xy;xlabel('position');ylabel('trial');title('theta power');

%--------------------------------------------------------------------------
% speed as a function of location and trial
subplot(322);
clear lst mlr slr;
lst = unique(trialInd);
for i = 1:length(lst)-1
    idx = find(trialInd == lst(i));
    mulr(:,i) = accumarray(positionInd(idx),runSpeedAtSpectrPoints(idx),[numel(locEdges)-1,1],@mean);
    %slr(:,i) = accumarray(positionInd(idx),runSpeedAtSpectrPoints(idx),[numel(locEdges)-1,1],@std);
end
imagesc(locEdges',lst',mulr'); colorbar;
axis xy;xlabel('position');ylabel('trial');title('speed');

%--------------------------------------------------------------------------
% occupancy as a function of location and trial
subplot(323);
clear lst mlr slr;
lst = unique(trialInd);
for i = 1:length(lst)-1
    idx = find(trialInd == lst(i));
    mulr(:,i) = accumarray(positionInd(idx),positionInd(idx),[numel(locEdges)-1,1],@numel);
    %slr(:,i) = accumarray(positionInd(idx),runSpeedAtSpectrPoints(idx),[numel(locEdges)-1,1],@std);
end
imagesc(locEdges',lst',mulr'); colorbar;
axis xy;xlabel('position');ylabel('trial');title('occupancy');

%--------------------------------------------------------------------------
% pupil area as a function of location and trial

videoFrameTimes = pupilResults.frameTimes.*(50/30);

subplot(324);
pupArea = [smPupilResults.Area];
idx = find(videoFrameTimes<=tS);
pupAtSpectrPoints = spline(videoFrameTimes(idx),pupArea(idx),out.t(out.t<=tS)); % <300 is task

clear lst mlr slr;
lst = unique(trialInd);
for i = 1:length(lst)-1
    idx = find(trialInd == lst(i));
    mulr(:,i) = accumarray(positionInd(idx),pupAtSpectrPoints(idx),[numel(locEdges)-1,1],@mean);
    %slr(:,i) = accumarray(positionInd(idx),pupAtSpectrPoints(idx),[numel(locEdges)-1,1],@std);
end
imagesc(locEdges',lst',mulr'); colorbar;
axis xy;xlabel('position');ylabel('trial');title('pupilArea');

%--------------------------------------------------------------------------
% pupil center X
subplot(325);
pupCentroid = [tracked.Centroid];
pupCentroidX = pupCentroid(1:2:end); pupCentroidY = pupCentroid(2:2:end);
pupCentroidX = pupCentroidX - mean(pupCentroidX); 
pupCentroidY = pupCentroidY - mean(pupCentroidY);
idx = find(videoFrameTimes<=tS);
pupAtSpectrPoints = spline(videoFrameTimes(idx),pupCentroidX(idx),out.t(out.t<=tS)); % <300 is task

clear lst mlr slr;
lst = unique(trialInd);
for i = 1:length(lst)-1
    idx = find(trialInd == lst(i));
    mulr(:,i) = accumarray(positionInd(idx),pupAtSpectrPoints(idx),[numel(locEdges)-1,1],@mean);
    %slr(:,i) = accumarray(positionInd(idx),pupAtSpectrPoints(idx),[numel(locEdges)-1,1],@std);
end
imagesc(locEdges',lst',mulr'); colorbar;
axis xy;xlabel('position');ylabel('trial');title('pupilCenterX');
frameTimes = 0;
%--------------------------------------------------------------------------
% pupil center X
subplot(326);
pupCentroid = [tracked.Centroid];
pupCentroidX = pupCentroid(1:2:end); pupCentroidY = pupCentroid(2:2:end); 
pupCentroidX = pupCentroidX - mean(pupCentroidX); 
pupCentroidY = pupCentroidY - mean(pupCentroidY);
idx = find(videoFrameTimes<=tS);
pupAtSpectrPoints = spline(videoFrameTimes(idx),pupCentroidY(idx),out.t(out.t<=tS)); % <300 is task

clear lst mlr slr;
lst = unique(trialInd);
for i = 1:length(lst)-1
    idx = find(trialInd == lst(i));
    mulr(:,i) = accumarray(positionInd(idx),pupAtSpectrPoints(idx),[numel(locEdges)-1,1],@mean);
    %slr(:,i) = accumarray(positionInd(idx),pupAtSpectrPoints(idx),[numel(locEdges)-1,1],@std);
end
imagesc(locEdges',lst',mulr'); colorbar;
axis xy;xlabel('position');ylabel('trial');title('pupilCenterY');

if exist([processedPath,'trialVsStuff.jpg'],'file') ~= 2        
    print([processedPath,'trialVsStuff'],'-djpeg','-r300');
end


%

%% LOCATION vs LICKING %%%%%%%%%OLD ONE%%%%%%%%%%%%%%%%%%%
ifRun=0;
if ifRun
    % only first 300 seconds since rest is sleep or non task
    from = find(tScale >= 950,1,'first');
    to = find(tScale >= 1350,1,'first');
    % [N,LocEdges,LicEdges,binLoc,binLic] = histcounts2(location,zscore(licks)');
    % figure;imagesc(LocEdges,LicEdges,N',[0 500]);axis xy
    locEdges = linspace(min(location(from:to)),max(location(from:to)),20);
    positionInd = discretize(location(from:to),locEdges);
    mulr = accumarray(positionInd',licks(from:to),[numel(locEdges),1],@mean);
    stdlr = accumarray(positionInd',licks(from:to),[numel(locEdges),1],@std);
    mulr = (mulr-mean(mulr))./(max(mulr)-min(mulr));
    stdlr = (stdlr-mean(stdlr))./(max(stdlr)-min(stdlr));
    %locEdgesScaled = 2*pi*((locEdges - min(locEdges))./(max(locEdges)-min(locEdges)));
    % figure; shadedErrorBar(locEdgesScaled(1:end-1),   mlr(1:end-1),    slr(1:end-1)./sqrt(sum(rewards.soundIdx*0.001<300)));
    figure; 
    shadedErrorBar(locEdges(1:end-1).*(2*pi*25)./max(location),   mulr(1:end-1),    stdlr(1:end-1)./sqrt(sum(rewards.atStart*0.001<1800)), 'k');
    hold on;
    % shadedErrorBar((locEdges(1:end-1)+locEdges(end-1)).*(2*pi*25)./max(location),   mlr(1:end-1),    slr(1:end-1)./sqrt(sum(rewards.soundIdx*0.001<1800)),{'color',[0 0.5 1]});
    % figure;
    % % x
    % x = locEdges(1:end-1).*(2*pi*25)./max(location); x = [x,x+150];
    % % y
    % y = mlr(1:end-1); y = [y; y];
    % % z
    % z = slr(1:end-1)./sqrt(sum(rewards.soundIdx*0.001<1800)); z = [z;z];
    % shadedErrorBar(x,y,z,{'color',[0 0 0 0.8]})
    xlabel('position (cm)'); ylabel('licking (normalised amplitude)'); box off;
    cage1 = (2*pi*25)*(1450/max(location));
    cage2 = (2*pi*25)*(2900/max(location));
    hold on; 
    plot(cage1,0,'.b', 'markersize',40);    text(cage1,0.1,'cage1');
    plot(cage2,0,'.b', 'markersize',40);    text(cage2,0.1,'cage2');
    plot(150,0,'.b', 'markersize',40);        text(150,0.1,'reward');
    % plot(cage1+150,0,'.b', 'markersize',40);    text(cage1,0.1,'cage1');
    % plot(cage2+150,0,'.b', 'markersize',40);    text(cage2,0.1,'cage2');
    % plot(150+150,0,'.b', 'markersize',40);        text(150,0.1,'reward');
    %,'color',[0 0.5 1]
    %plot(0,0,'.b', 'markersize',40);      text(155,0,'reward');
    if exist([processedPath,'locationVsLicking.jpg'],'file') ~= 2        
        print([processedPath,'locationVsLicking'],'-djpeg','-r300');
    end
end

