%% EXAMPLE PIPELINE
% INPUTS:
% chPyr - a pyramidal layer channel for spectrogramsz
% tS - total seconds to use for theta speed correlation

% given a path, run the following preliminary analysis steps
% 1.  Check and if not convert data and create *.dat and *.lfp files
% 2.  Extract the peripheral channels (licking, carousel and running
        % encoders, speed of running, animal location
% 3.  Visualise these channels to comfirm that it all makes sense
% 4.  Check if licking is modulated by location
% 5.  Generates some example spectrograms - to select which channel to use
        % set the chPyr input variable to the channel number you desire
% 6.  Curate pupil data and save into mat file
% 7.  Generate a speed vs theta correlation
% 8.  Visualise speed, pupil data theta power as a fun. of trial and locat

%% things to feed into this function
chPyr = 23; % select one lfp channel with good theta
tS = 900;

%% DATA CONVERSION
% check if data has been converted already
fldr = 'NP1_2018-04-10_10-22-25';
% pth = [getFullPath(fldrNme),'processed'];
pth = getFullPath(fldr);
ifConvert = 0;
if size(dir([pth,'processed']),1) < 9
    ifConvert = 1;
end
% data conversion
if ifConvert
    options.lfpSR=1000;
    options.mapping= oemaps.P2;
    options.numcores=[];
    options.downsampleparallel=1;
    options.period=[];%[1.3609e3, 2.5648e3];
    options.jumpoverride=1;
    options.appendchannels=1;
    openephys2dat(pth,options);
end

%% GET DATA %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%fldr = 'NP3_2018-04-11_19-37-06';
processedPath = getfullpath(fldr); % folder to keep processed data figs etc
% check if peripherals structure was already generated
if exist([processedPath,'peripherals.mat'],'file') == 2
    disp '>loading preprocessed peripherals<';
    load([processedPath,'peripherals.mat']);
    if size(data,1) < 40 % this conditions need to be further confirmed - dont take for granted. They might fail if using other probes...
        runCh = 35; lickCh = 36; carouselCh = 37; rewardCh = 38;
    else
        runCh = 67; lickCh = 68; carouselCh = 69; rewardCh = 70;
    end
else
    disp '>generating peripheral channels<';
    % get all channels into workspace
    [data,settings,tScale] = getLFP(fldr);
    if size(data,1) < 40 % this conditions need to be further confirmed - dont take for granted. They might fail if using other probes...
        runCh = 35; lickCh = 36; carouselCh = 37; rewardCh = 38;
    else
        runCh = 67; lickCh = 68; carouselCh = 69; rewardCh = 70;
    end

    % get 30kHz data for analog channels since encoder pulses are missed from
    % the lfp-1jHz data
    [data30k,settings30k,tScale30k] = getDAT(fldr,[runCh, lickCh, carouselCh, rewardCh]);
    %clear settings30k data30k;
    rewards         = getRewards(data30k(4,:));         % REWARD TIMEPOINTS - reward channel = 38
    runSpeed        = getRunSpeed(data30k(1,:));        % RUNNING SPEED
    carouselSpeed   = getCarouselSpeed(data30k(3,:));   % CAROUSEL SPEED 
    location        = getLocation(data30k(3,:),rewards);        % CAROUSEL LOCATION
    licks           = getLicks(data(lickCh,:));         % LICKING AS A FUNCTION OF LOCATION
    save([processedPath,'peripherals.mat'],'data','rewards','runSpeed','carouselSpeed','location','licks','tScale');
end

%% VISUALISE PERIPHERAL CHANNELS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ifPlot = 1;
if ifPlot
    % close all;
    figure; hold all;
    % run and carousel speeds
    h(1) = subplot(211);
    plot(tScale,runSpeed,'color',[0 .1 1],'linewidth',2); hold on; %h(1) = gca;
    plot(tScale,carouselSpeed,'color','k','linewidth',2);
    drawPatches(h(1), [tScale(rewards.soundIdx); tScale(rewards.consumeIdx(:,2))]');
    Lh = findobj(gca,'Type','line');
    legend(Lh,{'carousel speed','run speed'}); ylabel('speed (cm/s)');
    xlabel('time (s)');
    % licking and location
    h(2) = subplot(212);
    plot(tScale,location,'color','k','linewidth',2); hold on; % plot([0 max(tScale)],[4096 4096],'k');
    plot(tScale,licks,'color',[1 0.1 1 0.8],'linewidth',2);
    drawPatches(h(2), [tScale(rewards.soundIdx); tScale(rewards.consumeIdx(:,2))]');
    Lh = findobj(gca,'Type','line');
    legend(Lh,{'licking','location'});
    linkaxes(h,'x');
    xlim([0 1800]);
    set(gcf,'Position',[65 152 1920 1003]);
    xlabel('time (s)')
    if exist([processedPath,'peripheralsOverview.jpg'],'file') ~= 2        
        print([processedPath,'peripheralsOverview'],'-djpeg','-r600');
    end
    xlim([0 300]);
    if exist([processedPath,'peripheralsOverviewZoom.jpg'],'file') ~= 2        
        print([processedPath,'peripheralsOverviewZoom'],'-djpeg','-r600');
    end
end

%% LOCATION vs LICKING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% only first 300 seconds since rest is sleep or non task
from = 1; to = find(tScale >= tS,1,'first');
% [N,LocEdges,LicEdges,binLoc,binLic] = histcounts2(location,zscore(licks)');
% figure;imagesc(LocEdges,LicEdges,N',[0 500]);axis xy
locEdges = linspace(0,max(location(from:to)),20);
positionInd = discretize(location(from:to),locEdges);
mlr = accumarray(positionInd',licks(from:to),[numel(locEdges),1],@mean);
slr = accumarray(positionInd',licks(from:to),[numel(locEdges),1],@std);
mlr = (mlr-mean(mlr))./(max(mlr)-min(mlr));
slr = (slr-mean(slr))./(max(slr)-min(slr));
%locEdgesScaled = 2*pi*((locEdges - min(locEdges))./(max(locEdges)-min(locEdges)));
% figure; shadedErrorBar(locEdgesScaled(1:end-1),   mlr(1:end-1),    slr(1:end-1)./sqrt(sum(rewards.soundIdx*0.001<300)));
figure; 
shadedErrorBar(locEdges(1:end-1).*(2*pi*25)./max(location),   mlr(1:end-1),    slr(1:end-1)./sqrt(sum(rewards.soundIdx*0.001<1800)), 'k');
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
    print([processedPath,'locationVsLicking'],'-djpeg','-r600');
end

%% LICKING SPECTROGRAM %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear options;
options.defaults = 'theta';
out = specmt(data(lickCh,:),options);
clear options;
options.mode = 'spectrogram';
options.events = tScale(rewards.soundIdx);
options.eventscolor = 'k';    
figure('Name','licking spectrogram - all');
out1 = plot_spectra(out,1,options); hold on;
delete(colorbar); xlabel('time (s)');ylabel('frequency (Hz)'); title('lickport specgram - whole sessionn');
if exist([processedPath,'lickingWholeSession.jpg'],'file') ~= 2        
    print([processedPath,'lickingSpectWholeSession'],'-djpeg','-r600');
end
figure('Name','licking spectrogram - task');
out1 = plot_spectra(out,1,options); hold on;
delete(colorbar); xlabel('time (s)');ylabel('frequency (Hz)'); xlim([0 200]); title('lickport specgram - engaged in task');
if exist([processedPath,'lickingTask.jpg'],'file') ~= 2        
    print([processedPath,'lickingSpectTask'],'-djpeg','-r600');
end
figure('Name','licking spectrogram - immobility');
out1 = plot_spectra(out,1,options); hold on;
delete(colorbar); xlabel('time (s)');ylabel('frequency (Hz)'); xlim([900 1100]);title('lickport specgram - immobility');
if exist([processedPath,'lickingSpectImmobility.jpg'],'file') ~= 2        
    print([processedPath,'lickingSpectImmobility'],'-djpeg','-r600');
end

%% CURATE PUPIL data%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% run pupil summary which will return nan if no processed data is
% found. If not found then you must manually run the pupil detection
% functions
%pupilH = pupilSummary(fldr);
curatePupilData(fldr,1,1);
load([processedPath,'pupilResults.mat']);
%set(gcf,'pos',[1 64 957 1117]);
%frameTimes = linspace(tScale(1),tScale(end),numel(frameTimes));

%% WHISKER TRACKING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% not done prob won't bother with this

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
            print([processedPath,'session_spgram_all_ch_',specgramTypes{i}],'-djpeg','-r600');
        end
    end
end

%% SINGLE HPC SPECTROGRAM FOR THETA, GAMMA, RIPPLES AND UNIVERSAL %%%%%%%%%%%%%%%%%%%
% theta_w=2s, gamma_w = 0.1s, ripple_w = 0.1, univresal_w = 2.5s
ifRun = 1;
if ifRun
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
            print([processedPath,'session_spgram_ch_',int2str(ch),'_',specgramTypes{i}],'-djpeg','-r600');
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
    print([processedPath,'thetaSpeedCorr_ch_',int2str(chPyr)],'-djpeg','-r600');
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
    mlr(:,i) = accumarray(positionInd(idx),thetaP(idx),[numel(locEdges)-1,1],@mean);
    %slr(:,i) = accumarray(positionInd(idx),thetaP(idx),[numel(locEdges)-1,1],@std);
end
imagesc(locEdges',lst',mlr'); colorbar;
axis xy;xlabel('position');ylabel('trial');title('theta power');

%--------------------------------------------------------------------------
% speed as a function of location and trial
subplot(322);
clear lst mlr slr;
lst = unique(trialInd);
for i = 1:length(lst)-1
    idx = find(trialInd == lst(i));
    mlr(:,i) = accumarray(positionInd(idx),runSpeedAtSpectrPoints(idx),[numel(locEdges)-1,1],@mean);
    %slr(:,i) = accumarray(positionInd(idx),runSpeedAtSpectrPoints(idx),[numel(locEdges)-1,1],@std);
end
imagesc(locEdges',lst',mlr'); colorbar;
axis xy;xlabel('position');ylabel('trial');title('speed');

%--------------------------------------------------------------------------
% occupancy as a function of location and trial
subplot(323);
clear lst mlr slr;
lst = unique(trialInd);
for i = 1:length(lst)-1
    idx = find(trialInd == lst(i));
    mlr(:,i) = accumarray(positionInd(idx),positionInd(idx),[numel(locEdges)-1,1],@numel);
    %slr(:,i) = accumarray(positionInd(idx),runSpeedAtSpectrPoints(idx),[numel(locEdges)-1,1],@std);
end
imagesc(locEdges',lst',mlr'); colorbar;
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
    mlr(:,i) = accumarray(positionInd(idx),pupAtSpectrPoints(idx),[numel(locEdges)-1,1],@mean);
    %slr(:,i) = accumarray(positionInd(idx),pupAtSpectrPoints(idx),[numel(locEdges)-1,1],@std);
end
imagesc(locEdges',lst',mlr'); colorbar;
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
    mlr(:,i) = accumarray(positionInd(idx),pupAtSpectrPoints(idx),[numel(locEdges)-1,1],@mean);
    %slr(:,i) = accumarray(positionInd(idx),pupAtSpectrPoints(idx),[numel(locEdges)-1,1],@std);
end
imagesc(locEdges',lst',mlr'); colorbar;
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
    mlr(:,i) = accumarray(positionInd(idx),pupAtSpectrPoints(idx),[numel(locEdges)-1,1],@mean);
    %slr(:,i) = accumarray(positionInd(idx),pupAtSpectrPoints(idx),[numel(locEdges)-1,1],@std);
end
imagesc(locEdges',lst',mlr'); colorbar;
axis xy;xlabel('position');ylabel('trial');title('pupilCenterY');

%% SPIKES - MOUNTAINSORT
% % some commands i found that apparently ran ok relating to mountainsort
% %addpath(genpath('/storage2/nikolas/code/data_suite'))
% pth = [dataPath,'NP1','/','NP1_2018-04-10_10-22-25'];
% cd([dataPath,'NP1','/','NP1_2018-04-10_10-22-25']);
% run_mountainsort(pth)
% unit_manual_cleanup(pth)
% % below is trying to figure out what is what? (from history)
% % setenv('LD_LIBRARY_PATH','/lib/x86_64-linux-gnu');
% % system('rm -rf /bigscratch/mountainsort/mountainlab');
% % mtsortdir = [directory_sanitizer(filename) 'mtsort/'];
% % mkdir(mtsortdir);
% % mkdir([mtsortdir 'datasets']);

% if already clustered
unitsfn = get_lfp_filename(pth,'units');
load(unitsfn,'units','-mat');
nUnits = size(units,1);
% curate cells
% mergelist = unit_manual_merge(pth);
% cleanup cells
% mergelist = unit_manual_merge(pth)
    

% lets work with a single cluster for now
% get location and spikes in the same units
% location - seconds
% tScale - seconds
% temp (spikes) - samples so spikes /30k is seconds


spikeTimes = round((units.spikes{18,1})./30);
% discretize location
locEdges = linspace(0,max(location),360/5); % 5 degree bins or 2*pi*25/(360/5)=2cm
positionInd = discretize(location,locEdges);
spikePosInd = discretize(location(spikeTimes),locEdges);

% Justins way
positionOcc = accumarray(positionInd',ones(size(positionInd)),[numel(locEdges)-1,1],@sum);
spikeOcc = accumarray(spikePosInd',ones(size(spikePosInd)),[numel(locEdges)-1,1],@sum);
figure();plot(spikeOcc./positionOcc*1000);

% NPs way
binnedSpikes = histc(spikeTimes,tScale*1000)';
cellTuning = accumarray(positionInd',binnedSpikes,[numel(locEdges)-1,1],@mean)*1000;
figure;plot(cellTuning);



figure('units','normalized','outerposition',[0 0 1 1]);% repeat of the above - Justins way only
p = numSubplots(nUnits);
locEdges = linspace(0,max(location),360/5); % 5 degree bins or 2*pi*25/(360/5)=2cm
positionInd = discretize(location,locEdges);
positionOcc = accumarray(positionInd',ones(size(positionInd)),[numel(locEdges)-1,1],@sum);
for i = 1:nUnits
    spikeTimes = round((units.spikes{i,1})./30); 
    spikeTimes(spikeTimes == 0) = 1;
    spikePosInd = discretize(location(spikeTimes),locEdges);
    spikeOcc = accumarray(spikePosInd',ones(size(spikePosInd)),[numel(locEdges)-1,1],@sum);
    subplot(p(1),p(2),i);
    plot(((2*pi*25)*locEdges(2:end))./max(location),spikeOcc./positionOcc*1000,'color',[0.7 0.7 0.7]); box off; axis tight; hold on;
    plot(((2*pi*25)*locEdges(2:end))./max(location),smooth(spikeOcc./positionOcc*1000),'linewidth',3,'color','b');
    plot([(2*pi*25)*1450/max(location) (2*pi*25)*1450/max(location)],ylim,'-.r'); plot([(2*pi*25)*2900/max(location) (2*pi*25)*2900/max(location)],ylim,'-.r'); title(int2str(i));
    xlabel('position (cm)'); ylabel('rate (Hz)');    
end
print([processedPath,'mtsortPlaceCells'],'-djpeg','-r600');



%% SPIKES - KLUSTAKWIK
% lets load Justin's clustered data generated with KlustaKwik and manually
% curated
fldr = 'NP1_2018-04-10_10-22-25';
pth = getFullPath(fldr);

[Res,Clu,Map] = LoadCluRes(fullfile(pth,fldr));
nClusters = unique(Clu);

for i = 1:length(nClusters)
    temp = Clu == nClusters(i);
    temp = Res(temp);
    unitsKlu{i} = temp;  
    clear temp;
end
    
figure;
p = numSubplots(length(nClusters));

for i = 1:length(nClusters)
    spikeTimes = round([unitsKlu{i}]./30);
    binnedSpikes = histc(spikeTimes,tScale*1000)';
    locEdges = linspace(0,max(location),360/5); % 5 degree bins or 2*pi*25/(360/5)=2cm
    positionInd = discretize(location,locEdges);
    cellTuning = accumarray(positionInd',binnedSpikes,[numel(locEdges)-1,1],@mean)*1000;
    subplot(p(1),p(2),i)
    plot(locEdges(1:end-1),cellTuning,'color',[.7 .7 .7]); hold on;
    plot(locEdges(1:end-1),smooth(cellTuning,3),'r'); axis tight;
    plot([1450 1450],ylim,'-b'); plot([2900 2900],ylim,'-b'); box off;%title(int2str(i));
    clear spikeTimes;
end
    mtit('all Klusters all recording');    
    set(gcf, 'Position', get(0, 'Screensize'));
    print([processedPath,'AllKlustersAllRecording'],'-djpeg','-r600');

%% plot clusters by time
% periods where the purported movement of the electrodes occur
figure;
for i = 1:length(nClusters)
    plot(Res(Clu==i)./30000,i*ones([sum(Clu==i),1]),'.');
    hold on;
end
xlim([0, Res(end)/30000]);
    mtit('Klusters vs time');
    box off;
    set(gcf, 'Position', get(0, 'Screensize'));
    print([processedPath,'KlustersVsTime'],'-djpeg','-r600');

%% now select subset of data corresponding to the stable recording period
figure;
p = numSubplots(length(nClusters));
% where U at the end of variables is to signify that its a subset of the data
for i = 1:length(nClusters)
    spikeTimes = round([unitsKlu{i}]./30);
        % select subPeriod        
        [spikeTimesU, indSpikeTimesU]   =  SelectPeriods(spikeTimes,[70 1100]*1e3,'d',1, 1);
        [tScaleU, indtScaleU]           =  SelectPeriods(tScale.*1e3,[70 1100]*1e3,'d',1, 1);
        % [locationU, indlocationU]       =  SelectPeriods(location,indtScaleU,'d',1, 1);
        locationU = location(indtScaleU);
       
    binnedSpikes = histc(spikeTimesU,tScaleU)';
    locEdges = linspace(1,max(locationU),360/5); % 5 degree bins or 2*pi*25/(360/5)=2cm
    positionInd = discretize(locationU,locEdges);
    cellTuning = accumarray(positionInd',binnedSpikes,[numel(locEdges)-1,1],@mean)*1000;
    subplot(p(1),p(2),i)
    plot(locEdges(1:end-1),cellTuning,'color',[.7 .7 .7]); hold on;
    plot(locEdges(1:end-1),smooth(cellTuning,3),'r'); axis tight;
    plot([1450 1450],ylim,'-b'); plot([2900 2900],ylim,'-b'); box off;%title(int2str(i));
    clear spikeTimes;
end
mtit('70-1100s Klusters - no drifts');
set(gcf, 'Position', get(0, 'Screensize'));
print([processedPath,'70-1100sKlustersNoDrifts'],'-djpeg','-r600');

%% now select subset of data corresponding to the second stable recording period
figure;
p = numSubplots(length(nClusters));
% where U at the end of variables is to signify that its a subset of the data
for i = 1:length(nClusters)
    spikeTimes = round([unitsKlu{i}]./30);
        % select subPeriod        
        [spikeTimesU, indSpikeTimesU]   =  SelectPeriods(spikeTimes,[1100 2100]*1e3,'d',1, 1);
        [tScaleU, indtScaleU]           =  SelectPeriods(tScale.*1e3,[1100 2100]*1e3,'d',1, 1);
        % [locationU, indlocationU]       =  SelectPeriods(location,indtScaleU,'d',1, 1);
        locationU = location(indtScaleU);
       
    binnedSpikes = histc(spikeTimesU,tScaleU)';
    locEdges = linspace(1,max(locationU),360/5); % 5 degree bins or 2*pi*25/(360/5)=2cm
    positionInd = discretize(locationU,locEdges);
    cellTuning = accumarray(positionInd',binnedSpikes,[numel(locEdges)-1,1],@mean)*1000;
    subplot(p(1),p(2),i)
    plot(locEdges(1:end-1),cellTuning,'color',[.7 .7 .7]); hold on;
    plot(locEdges(1:end-1),smooth(cellTuning,3),'r'); axis tight;    
    plot([1450 1450],ylim,'-b'); plot([2900 2900],ylim,'-b'); box off;% title(int2str(i)); box off;
    clear spikeTimes;
end
mtit('1100-2100s Klusters - no drifts');
set(gcf, 'Position', get(0, 'Screensize'));
print([processedPath,'1100-2100sKlustersNoDrifts'],'-djpeg','-r600');



%% VAR - dont run
ifdo = 0
if ifdo
%% WRAP COLORMAP ON ITSELF
jet_wrap = vertcat(jet,flipud(jet));
colormap(jet_wrap);



%%


figure(1)
subplot(3,1,1); hold on; cla
plot(encoder)
axis tight

plot(locs, pks, 'r*')



deltaTs = diff(locs);
speed = 2*pi*Radius/600*100 ./ deltaTs ;  % cm/s


figure
subplot(221)
hist(speed,50)
end