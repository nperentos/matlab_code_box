% scrap 2


%% CAN DELETE THIS NOW temp trying to work out tuning curves for controlled exposures

%      CUED DIRECTION (CAROUSEL MOVES IN PREDETERMINED PATTERN - AKA CONTROLLED EXPOSURES)
if options.flag == 2
    
    % a different approach is needed here from the continuous case.
    % The reason being that the same positions  along trajectories exist in
    % two distinct contexts, inbound and outbound. The same can be said for
    % times when the carousel is not moving because it could be followed or
    % preceded by one context/trajectory or another. For start, we focus on
    % the movement periods. 
    
%     if mean(location) < 370 && mean(location) > 350
%         % convert data to 0 centered to match session.helper.positionBinCenters
%         location = location +360; 
%     elseif mean(location) < 10 && mean(location) > -10
%         % data is centered on 0 already
%     end
    
    % get contexts 
    if strcmp('1:toR2:fromR3:toL4:fromL5:atO6:atR7:atL',session.helper.position_context.labels);
        ctx_lbl = {'toR','fromR','toL','fromL','atO','atR','atL'}; 
    else
        error('please fix ''session.helper.position_context.labels'' variable. You probably need to (re)run updateSession(fileBase) function...');
    end
    ctx = session.helper.position_context.context; % the 'contexts'
    per = session.helper.position_context.segs;    % the idxs of the 'contexts'
    nBlocks = session.info.nBlocks;
    nTrials = session.info.nTrials;
    nTrOfs = round(nTrials*0.9); % n of trials offset for vis only
    brk = 4; % num of trials to inject between blocks for vis only
    breakDurations = session.info.breakDurations;
    trialsPerBlock = session.info.trialsPerBlock;
    rejTrials = session.info.rejTrials;
    tBreaks = session.info.breakDurations;
    conds = session.info.conditions;
    %     if any(ctx == 0)
    %         A(nV).warning = 'there are epochs with zero context';                        
    %         if ~isempty(rejTrials)
    %             tt = session.events.TTL.atStart(max(rejTrials));% in lfp sampling rate
    %             fr = find(per(:,1)<tt & per(:,2)>tt) + 1;                
    %         else
    %             fr = 1;
    %         end
    %     end
    ctx(ctx == 0) = 8;% pool unknown ctxs into an 8th category
    edges_tr = [1 cumsum(trialsPerBlock)];% block edges in trial space                
    edges_ctx = find(diff(session.helper.position_context.segs')'./SR > 30);% block edges inctxs space
    clear blk_lims;
    for i = 1:length(edges_tr)
        blk_lims(i) = find(per(:,1) <= session.events.TTL.atStart(edges_tr(i)) & ...
                           per(:,2) >= session.events.TTL.atStart(edges_tr(i)));
    end
    blk_lims(1) = 0; blk_lims(end) = length(per);
    blk_lims = [blk_lims(1:end-1);blk_lims(2:end)];
    blk_lims(1,:) = blk_lims(1,:) + 1;
    blk_lims = blk_lims';
    blkID = [];
    for i = 1:size(blk_lims,1)
        blkID(blk_lims(i,1):blk_lims(i,2),1) = i;
    end
    % all ctxs
    data_f = zeros(length(ctx),1); data_f(edges_ctx) = 1;
    blks = [per, blkID, ctx' data_f];% non-boundary break periods (atO) are assigned to next block

    % armed with blks we can start putting together tuning curves
%     for U = 1:2
%         if U == 1; display('processing multi unit clusters (MUA)...'); end
%         if U == 2; display('processing putative single unit clusters (SU)...'); end
        gU = sp.cids(sp.cgs == 1 | sp.cgs == 2);
        p = numSubplots(length(gU)); 

        for cx = 1:4
            incr = 1;
            % 1. find all times and positions for context cx            
            myBlks = find(blks(:,4) == cx);
            myPeriods = blks(find(blks(:,4) == cx),[1:2]);    
            [myLoc, myT] = SelectPeriods(location,myPeriods ,[],[],0);
            % ensure correct position scale    
            locs2Keep = [min(myLoc):1:max(myLoc)]';%locEdges = [min(tmpLoc):1:max(tmpLoc)]';
            locs{cx} = [1:length(locs2Keep)];
            %locEdges = [-360:1:360];
            locEdges = [1:1:720];
            %occupancy - should be rather flat (barring ramp in speed at start and end)    
            [occupancy]=histc(myLoc,locEdges); %(unique(myLoc))
            occupancy = occupancy./sum(occupancy);
            %figure;plot(locEdges,occupancy);

            for i = 1:length(gU) 
                idxSp = find(sp.clu == gU(i)); 
                spT = round(sp.st(idxSp).*1000);
                res = zeros(size(tScale));% unsparsify
                res(spT) = 1; 
                mySpikes = res(myT); % keep spikes for movement periods            
                sz = [numel(session.helper.positionBinCenters)-1,1]; % offset by half a degree -360 to 360 matching location span

                %cell's mean tuning
                meanCellTuning = accumarray(myLoc , mySpikes , sz , @mean) .* (1/diff(tScale(1:2)));
                muFR = (sum(mySpikes)/length(mySpikes)) * (1/diff(tScale(1:2)));
                % Skaggs 1993 Information in bits per spike
                SSI = nansum(occupancy.*meanCellTuning/muFR.*log2(meanCellTuning/muFR));

                % cell's tuning split in trials
                clear cellTuning; 
                cellTuning = zeros(sz(1), length(myBlks));%length(rewards.atStart));   
                for j = 1:length(myBlks)           
                    from = myPeriods(j,1);
                    to   = myPeriods(j,2);
                    cellTuning(:,j) = accumarray(location(from:to),res(from:to),sz,@mean).*(1/diff(tScale(1:2))); % [numel(locEdges)-1,1]
                end
                %cellTuning = cellTuning(locEdges,:);

                % trial similarities
                mu = mean(cellTuning,2);        
                w = 6; sd3 = 2;
                for j = 1:length(w)
                    %subplotfit(j,length(w)); hold on;
                    for tr = 1:size(cellTuning,2)
                        data_f = corrcoef(smooth_gauss(cellTuning(:,tr),w(j),sd3(j)),smooth_gauss(mu,w(j),sd3(j)));    
                        CC(tr) = data_f(2,1);
                        %
                        cellTuningSm(:,tr) = smooth_gauss(cellTuning(:,tr),w(j),sd3(j));
                        %plot(smooth_gauss(cellTuning(:,i),w(j),sd3(j)),'color',[i/(size(cellTuning,2)) 0.5 0.0 0.5],'linewidth',2);
                    end
                    %plot(smooth_gauss(mu,w(j),sd3(j)),'b','linewidth',3);
                    %title([' mu=',num2str(w(j)),' sd3=',num2str(sd3(j))]);
                end   

                % covariance matrix of smoothed trials
                CV = cov(zscore(cellTuningSm));            
                CV = CV-diag(diag(CV));        

                % store variables in a structure for further use            
                tun(incr,cx).locs2Keep = locs2Keep;
                tun(incr,cx).tuning(:,:) = cellTuning;
                tun(incr,cx).muTuning(:) = meanCellTuning;
                tun(incr,cx).muFR = muFR;
                tun(incr,cx).SSI = SSI;
                tun(incr,cx).cids = gU(i);
                tun(incr,cx).cellType = sp.cgs(sp.cids == gU(i));;
                tun(incr,cx).shank = nq.cluAnatGroup(find(nq.cids == gU(i))); %% this seems to be wrong but only for the first cell???
                tun(incr,cx).cluCh = nq.cluCh(find(nq.cids == gU(i))); %% this seems to be wrong but only for the first cell???
                tun(incr,cx).spkWidthR = nq.spkWidthR(find(nq.cids == gU(i))); %% this seems to be wrong but only for the first cell???
                tun(incr,cx).CC = CC';
                tun(incr,cx).muCC = nanmean(CC);
                tun(incr,cx).tuningSm(:,:) = cellTuningSm;
                tun(incr,cx).CV = CV;                
                incr = incr + 1;        
            end
        end        
end



%% KEEP THIS IN CASE CHANGE MIND ABOUT PRESENTATION puts the four trajectories into the 4 quadrants of the XY plane
    close all;
    % figure; 
    % p = numSubplots(length(tun));
    % ha = tight_subplot(3,4,[.01 .03],[.1 .01],[.01 .01]);
    c = 1;
    figure;%axes(ha(c)); 
    maxTr = max([size(tun(c,1).tuning,2) size(tun(c,3).tuning,2)]) + 1;
    % trajectory to R target
    myX = tun(c,1).locs2Keep; myY = size(tun(c,1).tuning(myX,:),2);
    imagesc([1:length(myX)],[1:myY],fliplr(tun(c,1).tuning(myX,:)')); hold on;
    text(-125,0,'inbound   outbound','rotation',90,'horizontalalignment','center');
    text(60,maxTr,'A \rightarrow B','horizontalalignment','center')

    % trajectory to L target
    myX = tun(c,3).locs2Keep; myY = size(tun(c,3).tuning(myX,:),2);
    imagesc(fliplr(-[1:length(myX)]),[1:myY],fliplr(tun(c,3).tuning(myX,:)'));
    text(-60,maxTr,'C \leftarrow A','horizontalalignment','center')


    % trajectory from R to Origin
    myX = tun(c,2).locs2Keep; myY = size(tun(c,2).tuning(myX,:),2);
    imagesc([1:length(myX)],-[1:myY],tun(c,2).tuning(myX,:)');
    text(60,-maxTr,'B \rightarrow A','horizontalalignment','center')


    % trajectory from L to to Origin
    myX = tun(c,4).locs2Keep; myY = size(tun(c,4).tuning(myX,:),2);
    imagesc(fliplr(-[1:length(myX)]),-[1:myY],fliplr(tun(c,4).tuning(myX,:)')); 
    text(-60,-maxTr,'A \leftarrow C','horizontalalignment','center')

    box off; axis tight; axis xy;
    set(gca,'XAxisLocation', 'origin','YAxisLocation', 'origin');
    clm = flipud(colormap('gray'));
    colormap(clm);%colorbar;

    ForAllLabels('fontsize',14)
    
    
%% PLAY WITH SACCADES

% position distribution of saccades   
    fileBase = 'NP44_2019-12-13_17-49-06';
    [session, behavior] = loadSession(fileBase);
    beh = behavior.data.data; 

    sac = beh(:,[end-1:end]);
    ipos = find(strcmp(behavior.name,'position'));
    [ix,~] = find(sac == 1); % both saccades
    [ix,~] = find(sac(:,1) == 1); % X only
    [ix,~] = find(sac(:,2) == 1); % Y only
    sac_pos = beh(ix,ipos);
    figure; histogram(sac_pos,100);


% theta raw phase triggered by saccade (peaks) timepoints
    fileBase = 'NP44_2019-12-13_17-49-06';
    [session, behavior] = loadSession(fileBase);
    beh = behavior.data.data;

    iphs = find(strcmp(behavior.name,'theta_raw_phase'));
    %[ix,~] = find(sac(:,1) == 1); % X only length(ix)
    %[ix,~] = find(sac(:,2) == 1); % Y only
    [ix,~] = find(sac == 1); % both saccades
    ix = sort(unique(ix));
    th_ph = beh(:,iphs);
    w = 300;
    periods = [ix-w, ix+w];

    [y, ind] = SelectPeriods(th_ph,periods,[],1);
    y2 = reshape(y,length(y)/length(periods),length(periods));
    xax = -w:1:w;
    figure;
    plot(xax,y2,'color',[.5 .5 .5]); hold on; 
    plot([0 0],ylim,'--','color',[1 1 1].*0.0,'linewidth',4);
    plot(xax,circ_mean(y2,[],2),'b','linewidth',4);

    shadedErrorBar(xax,circ_mean(y2,[],2),circ_std(y2,[],[],2))


% theta ica phase triggered by saccade (peaks) timepoints
    fileBase = 'NP44_2019-12-13_17-49-06';
    [session, behavior] = loadSession(fileBase);
    beh = behavior.data.data;

    %iphs = find(strcmp(behavior.name,'theta_ica_phase'));
    %[ix,~] = find(sac(:,1) == 1); % X only length(ix)
    %[ix,~] = find(sac(:,2) == 1); % Y only
    [ix,~] = find(sac == 1); % both saccades
    ix = sort(unique(ix));

    th_ph = beh(:,iphs);
    w = 300;
    periods = [ix-w, ix+w];

    [y, ind] = SelectPeriods(th_ph,periods,[],1);
    y2 = reshape(y,length(y)/length(periods),length(periods));
    xax = -w:1:w;
    figure;
    plot(xax,y2,'color',[.5 .5 .5]); hold on; 
    plot([0 0],ylim,'--','color',[1 1 1].*0.0,'linewidth',4);
    plot(xax,circ_mean(y2,[],2),'b','linewidth',4);

    shadedErrorBar(xax,circ_mean(y2,[],2),circ_std(y2,[],[],2))

% SUA and MUA rasters triggered on saccades
% load the spike data
goto(fileBase); sp = loadKSdir(pwd);
% load the saccade data
[session, behavior] = loadSession(fileBase);
% which raster function to use?
beh = behavior.data.data;
ch1 = find(strcmp(behavior.name,'saccadesX'));
ch2 = find(strcmp(behavior.name,'saccadesY'));
sac = beh(:,[ch1,ch2]);
[ix,~] = find(sac(:,1) == 1); % X and Y saccades indices
ix = ix./session.info.SR_LFP;
% pick SUA only
iSUA = sp.cids(find(sp.cgs == 2));%iSUA=iSUA(20); whos iSUA
Clu = double(sp.clu(find(ismember(sp.clu, iSUA)))); whos Clu
Res =  sp.st(find(ismember(sp.clu, iSUA))); max(Res)
TrigRasters(ix, 0.4, Res, Clu, session.info.SR_LFP, 0);%[TrLag TrInd TrClu TrValue] = 
[out,bins] = trig_spikes(Res,ix, 0.5, 0.01);
figure; histogram(out,bins);


%% ripple detection on all files in myDB
set(0,'DefaultFigureVisible','off');
GoThroughDb('updateSession',myDB, 0, 0, 0);
for i = 21:length(myDB)
    unitProcessing(myDB{i});
end



%% make graphs for SINAPS paper
figure;
% first select SU clusters
    idxSU = find(nq.cgs == 2);
    div = 5.859375;
    
   
% firing rate 
    fr = nq.fr(idxSU);
    [N,EDGES] = histcounts(fr,20);
    subplot(131); plot_shaded(EDGES(1:end-1)+max(diff(EDGES))/2,N);set(gca,'xscale','log');
    xlabel('firing rate (1/s)');

% peak to trough aplitude distribution (for extracellular max depolarisation = negative deflection)
    pk2trgh = abs(nq.centerMax(idxSU) - nq.rightMax(idxSU))./1; % is the unit correct div replaced by 1 instead of 5.859375
    [N,EDGES] = histcounts(pk2trgh,20);
    subplot(132); plot_shaded(EDGES(1:end-1)+max(diff(EDGES))/2,N);set(gca,'xscale','log');
    xlabel('waveform amplitude (\muV)');    
    
% wavefore relative noise level(peak amp divided by std at tail)
    % clu_noise_estimate = sqrt(mean(nq.sdSpk(idxSU,end-4:end),2)) ./ abs(nq.centerMax(idxSU)); % if using the tail's sd
    clu_noise_estimate = (nq.sdSpk(idxSU,round(end/2))) ./ abs(nq.centerMax(idxSU)); % if using the peak's sd
    [N,EDGES] = histcounts(clu_noise_estimate,20);
    subplot(133); plot_shaded(EDGES(1:end-1)+max(diff(EDGES))/2,N);
    xlabel('waveform relative noise level');
 

%% get the waveform on all channels
% we go by this paper and fix a span of interest of 400 um. On the 8 shank
% sinaps this translates to 400um span / 28um interpixel distance = 14
% channels, 7 above and 7 below. In that paper they ignore the second
% dimension
% https://doi.org/10.1152/jn.00680.2018
close all;

% should we upsample?
SR = sp.sample_rate;
ResCoef = 10; % upsample factor WAS CHANGED ON Aug.30 2005!!!!!!!!!!
Sample2Msec = 1000/SR/ResCoef; %to get fromnew samplerate to the msec


test = mean(Amp,2);
test = sq(mean(Amp,2))';
test = resample(test,ResCoef,1);
ofs = max(test(:))*2;

% test 2 is for vis.
test2 = test + repmat([0:ofs:ofs*(size(test,2)-1)],[size(test,1), 1]);


[mnAmp mnLoc] = min(test2);


% we should already know the central channel as tmpCh or refind as min(min)
[mn ch] = min(min(test));
% find 7 channels above and 7 below the max
ch_subset = [ch-15:2:ch+15]+1;
ch_subset(ch_subset < 1) = [];

% out of these channels, get the ones whith amplitude > 12% of max
chs_with_waveform = find(abs(min(test(:,ch_subset))) > abs(0.12*mn));
chs_with_waveform = ch_subset(chs_with_waveform);

figure('pos',[1927 233 613 395]); 

subplot(121); 
    plot(test2(:,ch_subset),'k'); hold on; axis tight;set(gca, 'visible', 'off'); 
    plot(test2(:,ch),'r','Linewidth',1.5);
    
    plot(mnLoc(chs_with_waveform),mnAmp(chs_with_waveform),'or');
    plot(mnLoc(chs_with_waveform),mnAmp(chs_with_waveform),'.r');

subplot(122); 
    imagesc(test(:,ch_subset)');  axis tight;set(gca, 'visible', 'off'); axis xy; colormap autumn; clb = colorbar; ylabel(clb,'amp. (\muV)');

clm = get(gca,'clim');
clm = clm.*1.2;
set(gca,'clim',clm);

% get the  spatial delay um/ms in 1D
[Vx tx] = min(test(:,chs_with_waveform));
ii = find(chs_with_waveform == ch);

chs_x = sp.xcoords(chs_with_waveform)
chs_y = sp.ycoords(chs_with_waveform)

pfit = polyfit(tx(1:ii)',chs_y(1:ii),1); % degrees but irrelevant: atand(pfit(1))
disp(['below soma speed: ', num2str(pfit(1)), ' um/ms']);

pfit = polyfit(tx(ii:end)',chs_y(ii:end),1);
disp(['above soma speed: ', num2str(pfit(1)), ' um/ms']);


% zdata = test(:,ch_subset);zdata = zscore(zdata(:));zdata = reshape(zdata,[820, length(ch_subset)]);
% size(zdata)
% figure; plot(zdata)

% %%
% % repeat in 2D!
% % find 7 channels above and 7 below the max
% ch_subset = [ch-13:1:ch+13]+1;
% ch_subset(ch_subset < 1) = [];
% 
% % out of these channels, get the ones whith amplitude > 12% of max
% chs_with_waveform = find(abs(min(test(:,ch_subset))) > abs(0.12*mn));
% chs_with_waveform = ch_subset(chs_with_waveform);
% 
% figure('pos',[1927 233 613 395]); 
% 
% subplot(121); 
%     plot(test2(:,ch_subset),'k'); hold on; axis tight;set(gca, 'visible', 'off'); 
%     plot(test2(:,ch),'r','Linewidth',1.5);
%     
%     plot(mnLoc(chs_with_waveform),mnAmp(chs_with_waveform),'or');
%     plot(mnLoc(chs_with_waveform),mnAmp(chs_with_waveform),'.r');
% 
% subplot(122); 
%     imagesc(test(:,ch_subset)');  axis tight;set(gca, 'visible', 'off'); axis xy; colormap autumn; clb = colorbar; ylabel(clb,'amp. (\muV)');
% 
% clm = get(gca,'clim');
% clm = clm.*1.2;
% set(gca,'clim',clm);
% 
% % get the  spatial delay um/ms in 1D
% [Vx tx] = min(test(:,chs_with_waveform));
% ii = find(chs_with_waveform == ch);
% 
% chs_x = sp.xcoords(chs_with_waveform)
% chs_y = sp.ycoords(chs_with_waveform)
% 
% pfit = fitlm([chs_y(1:ii),chs_x(1:ii)],tx(1:ii)','linear');
% % these would be the speeds in x and y
% 1./pfit.Coefficients.Estimate(2:3)
% 
% atand(pfit(1))
% pfit = polyfit(tx(ii:end)',chs_y(ii:end),1);
% atand(pfit(1))


% trying to redo this more clearly cause it got confusing
i=254;
current_clu_id = sp.cids(i);
        idx = find(tbl.cluster_id == current_clu_id);
        current_clu_chan = tbl.ch(idx);
        current_clu_shank = anat_group(current_clu_chan+1);
        current_shank_chans = find(anat_group == current_clu_shank);

        display(['unit ',num2str(i),'/',num2str(length(sp.cids)), ', ',str{sp.cgs(i)},', shank ', num2str(current_clu_shank)]);

    % get spike waveform time indexes
        myT = Res(find(Clu == sp.cids(i)));% spikes of current cluster
        %Lag = [-40:42];% Lag = [-15:40];this was for my OE data at antons
        myT(myT<1-Lag(1) | myT>nSamples-Lag(end))=[]; % eliminate spikes to close to start/end of file
        nLag = length(Lag);
        nmyT = length(myT);
        myTLagged = reshape(bsxfun(@plus,myT, Lag),[],1); % idxs into dat file for each spike

    % bring in all individual spikes
        %Amp = mmap.Data.x(:,myTLagged); % takes too much memory?
        %Amp = reshape(Amp, nChannels, nmyT, nLag); % takes too much memory?
        Amp = mmap.Data.x(current_shank_chans,myTLagged);
        Amp = reshape(Amp, length(current_shank_chans), nmyT, nLag);


    % from the current shank, consider only good channels
        good_chans_shank = intersect(good_chans_all,current_shank_chans); % abs chan. values
        good_chans_idx = good_chans_shank - current_shank_chans(1)+1 ;
        
        %Amp = Amp(good_chans_idx,:,:); % remove irrelevant channels
        mn = repmat(mean(Amp,3),[1, 1, size(Amp,3)]); % all the waveforms across whole electrode space
        mAmp = double(Amp)-mn; % mean corected spike waveforms
        mW = squeeze(mean(mAmp,2)); %
        sdW = squeeze(std(mAmp,[],2)); %

    % find max amp waveform/channel
        % looks for non inverted waveforms too
        %[~,cluCh(i)] =max(max(-mW'));
        [tmp1Amp,tmp_idx_1] =max(max(-mW'));
        [tmp2Amp,tmp_idx_2] =max(max(mW'));

        [a,b] = max([tmp1Amp tmp2Amp]);
        if b == 1
            cluCh(i) = good_chans_shank(tmp_idx_1);%good_chans(tmp1Ch); no! b/c we only loaded the subset of channels
            disp([num2str(cluCh(i))]);
            tmpCh = good_chans_idx(tmp_idx_1);
        else
            cluCh(i) = good_chans_shank(tmp_idx_2);%good_chans(tmp2Ch); no! b/c we only loaded the subset of channels
            tmpCh = good_chans_idx(tmp_idx_2);
            disp([num2str(cluCh(i))]);
        end
        
        
        
%% SINAPS data find ripples 12/04/2024
sessionFolder = '/storage2/perentos/data/SINAPS_2024__sorting/1950_2/';
[data,settings,tScale] = getLFP([],sessionFolder);
SR = str2num(settings.parameters.fieldPotentials.lfpSamplingRate.Text);
% get channel skip information
nCh1 = str2num(settings.parameters.acquisitionSystem.nChannels.Text);
nCh2 = size(data,1);
if nCh1 == nCh2
    k = 1;
    for i = 1:16
        for j = 1:64
            skp(k) = str2num(settings.parameters.anatomicalDescription.channelGroups.group{1, i}.channel{1, j}.Attributes.skip);
            k=k+1;
        end
    end
else
    error('number of channels in settings.xml doesnt match the number of imported channels');
end

% keep 1 in 4 channels
data = data(1:4:end,:);
data = data - mean(data,2);
%ripples = find_ripples(data,{'sr',SR,'method','hilbert','plot',1,'ripplefreq',[80 250],'mode','auto','thr',2.5,'mincycles',4,'refsig',[], 'periods',[],'wavelet_freq',0});
% filter for ripple band
tic;data_f = eegfilt(data,SR,80,250);toc
% get distribution of amplitudes
env = abs(hilbert(data_f));
figure; 
plot(data(1,1:10000)); hold on; 
plot(data_f(1,1:10000));
plot(env(1,1:10000));
legend('raw','ripple band','hilbert env');

kurt = kurtosis(env')';
prtl = prctile(env',95)';
figure; plot(zscore(kurt)); hold on; plot(zscore(prtl));
legend('z-kurtosis','z-prtle');
[pk,loc] = findpeaks(zscore(prtl),'minpeakheight',1);
loc = loc.*4 - 3;

loc_kurt = [4 18 32 51 65 79 97]*4-3
        
        
        
        
% 





