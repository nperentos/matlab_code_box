function tun = getTuningCurvesBackUp(fileBase,varargin)
%function tun = getPlaceTuningNew(fileBase,flag,pth)

% getTuningCurves extract trial resolved place fields and computes tuning 
% curves for each, as well as various properties that quantify the qualilty 
% of the fields.
% historically this is a combination of getPlaceTuningNew, PFStability and
% permutePlaceCells
% calls permutePlaceRasters.m
%       getMeanSpikesPerPeriod.m

%set(0, 'defaultFigurePosition',  [3841 1361 970 460]);
%error('check before using as a whole using debugger')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% getPlaceTuninng(filebase,flag)
% generates tuning curves for all SUs and MUAs as generated from Kilosort 2
% and curated in phy.
% The script is specific to the carousel setup
% NPerentos - 26/06/2019
% -----INPUTS-----
% filebase: main folder with data e.g. filebase = 'NP25_2019-06-02_merged';
% flag:     defines the task used 
%           flag = 1 for continuous unidirectional
%           flag = 2 for cued direction
%           flag = 3 for passive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% PREREQUISITES
    disp('constructing tuning curves...');
    options = {'flag',[],'pth',[],'verbose',1};
    options = inputparser(varargin,options);

    ifPlot = 0;
    if ~isempty(options.pth)
        processedPath = getfullpath(fileBase,options.pth);
    else
        processedPath = getfullpath(fileBase);
    end

% % bring in peripherals
%     cd(processedPath)
%     disp 'attempting to load peripherals'; 
%     if exist('peripheralsPP.mat')
%         load('peripheralsPP.mat');
%         carouselSpeed = carouselGetVar(fileBase,{'carouselSpeed'},ppp,pppNames);
%         tScale = carouselGetVar(fileBase,{'tScale'},ppp,pppNames);
%         location = carouselGetVar(fileBase,{'posDiscr'},ppp,pppNames); %3degree bins...
%         load('peripherals.mat');
%         rewards = peripherals.events;
%     else
%         load('peripherals.mat');
%     end
    
% bring in session we will need the
% tScale, 
% location,
% carouselSpeed, 
% and reward TTLs?   
    [session, behavior]=loadSession(fileBase);    
    beh = behavior.data.data; % this is very annoying...
    
    location = beh(:,strcmp(behavior.name,'posDiscr'));
    
    idxMv = find(session.helper.idxMov == 1);    
    
    idxTr = session.helper.idxTrials;
    
    SR = session.info.SR_LFP
    
    tScale = 1/SR:1/SR:session.info.nSamples_LFP/SR;
    

    rewards = session.events.TTL;
    
    if isempty(options.flag)
        if strcmp(session.info.taskType,'continuous')
            options.flag = 1;
        elseif strcmp(session.info.taskType,'controlled')
            options.flag = 2;
        elseif strcmp(session.info.taskType,'cued')
            options.flag = 3;    
        else
            disp('there was no carousel rotation so no place tuning can be computed... skipping');
            tun = NaN;
            return;
        end
    end
                
% bring in spikes
    if exist(fullfile(processedPath,'KS'),'dir')
        cd KS;
        warning(' please consider moving the KS data into the main ''processed''');
    end
    sp = loadKSdir(pwd);
    tit = {'MUA','SU'};
    sprintf('\n-------------------------------\n   in KS ''1''= MUA, ''2''= SU\n-------------------------------\n')
    
% load the nq structure so as to extract the shank and channel number?
    disp('loading the nq structure...')
    load([fileBase,'.nq.mat']); % nq structure
    
    
%%      UNIDIRECTIONAL PROTOCOL (CAROUSEL MOTION COUPLED TO RUNNING DISK)
if options.flag == 1
    incr = 1;
    for U = 1:2 % unit type (MUA or SUA)
        
        if U == 1; display('processing multi unit clusters (MUA)...'); end
        if U == 2; display('processing putative single unit clusters (SU)...'); end

        %figure;
        gU = sp.cids(sp.cgs == U);    
        p = numSubplots(length(gU));

        % sub select data where carousel or animal is moving
        % BUT idxMov should be taken from ppp since is already lodaded
        % idxMv = find(carouselSpeed>1); % idxMv = find(runSpeed>1);
        tmpLoc = location(idxMv);
        % as it happens the position is already discretised within
        % peripheralsPP
        % locEdges = linspace(min(tmpLoc),max(tmpLoc),360/5); % 5 degree bins or 2*pi*25/(360/5)=2cm
        % positionInd = discretize(tmpLoc,locEdges);
        
        %locEdges = [0; unique(tmpLoc)];
        %locEdges = session.helper.positionBinCenters(unique(tmpLoc));
        %positionInd = session.helper.positionBinCenters(tmpLoc);
        
        locEdges = unique(tmpLoc);
        % to be on the safe side force complete scale
        locEdges = [min(locEdges):1:max(locEdges)]';
        
        tmptScale = tScale(idxMv);
        
        % this is not used but maybe it should unless accumarray corrects for this automatically(it should)        
        [occupancy]=histc(tmpLoc,(unique(tmpLoc)));  
        [occupancy]=histc(tmpLoc,(unique(tmpLoc)));  
        occupancy = occupancy./sum(occupancy);
        
    % cycle through cells
        for i = 1:length(gU) 
            clf;
            idxSp = find(sp.clu == gU(i));
            spT = round(sp.st(idxSp).*1000);
            res = zeros(size(tScale));
            res(spT) = 1; % spikes array as a series of 1s and 0s for the whole tScale
            tmpSpikes = res(idxMv); % keep spikes for movement periods

            % average cell tuning for carousel movement (or run?) periods
            % only. In units of ????? (kHz unless you normalise by the size
            % of the time bin which is 0.0001!!!
%         meanCellTuning = accumarray(positionInd',tmpSpikes,[numel(locEdges)-1,1],@mean).*(1/diff(tScale(1:2))); % thiis occupancy-normalised
            sz = [numel(session.helper.positionBinCenters)-1,1];
            meanCellTuning = accumarray(tmpLoc , tmpSpikes , sz , @mean) .* (1/diff(tScale(1:2)));
            % lets trim the cell tuning array to its meaningful range, that
            % is defined by the locEdges
            meanCellTuning = meanCellTuning(locEdges);
            %sumCellTuning = accumarray(positionInd',tmpSpikes,[numel(locEdges)-1,1],@sum); % number of spikes in spatial bin
            muFR = (sum(tmpSpikes)/length(tmpSpikes)) * (1/diff(tScale(1:2))); % firing rate carousel movement periods (not overall for cluster)
    % Skaggs 1993 Information in bits per spike
            SSI = nansum(occupancy.*meanCellTuning/muFR.*log2(meanCellTuning/muFR));
                        
            
   % cell tuning split in trials
   clear cellTuning; 
   cellTuning = zeros(sz(1), length(rewards.atStart));   
   for j = 1:max(idxTr)
       from = find(tmptScale >= tScale(find(idxTr == j,1       ))  ,1);
       to   = find(tmptScale >= tScale(find(idxTr == j,1,'last'))  ,1);
       cellTuning(:,j) = accumarray(tmpLoc(from:to),tmpSpikes(from:to),sz,@mean).*(1/diff(tScale(1:2))); % [numel(locEdges)-1,1]
   end
   cellTuning = cellTuning(locEdges,:);
   
    % trial similarities 
            mu = mean(cellTuning,2);        
            w = 6; sd3 = 2;
            for j = 1:length(w)
                %subplotfit(j,length(w)); hold on;
                for tr = 1:size(cellTuning,2)
                    tmp = corrcoef(smooth_gauss(cellTuning(:,tr),w(j),sd3(j)),smooth_gauss(mu,w(j),sd3(j)));    
                    CC(tr) = tmp(2,1);
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
            tun(incr).tuning(:,:) = cellTuning;
            tun(incr).muTuning(:) = meanCellTuning;
            tun(incr).muFR = muFR;
            tun(incr).SSI = SSI;
            tun(incr).cids = gU(i);
            tun(incr).cellType = U;
            tun(incr).shank = nq.cluAnatGroup(find(nq.cids == gU(i))); %% this seems to be wrong but only for the first cell???
            tun(incr).cluCh = nq.cluCh(find(nq.cids == gU(i))); %% this seems to be wrong but only for the first cell???
            tun(incr).spkWidthR = nq.spkWidthR(find(nq.cids == gU(i))); %% this seems to be wrong but only for the first cell???
            tun(incr).CC = CC';
            tun(incr).muCC = nanmean(CC);
            tun(incr).tuningSm(:,:) = cellTuningSm;
            tun(incr).CV = CV;
            incr = incr + 1;  
        end
        
    end
end


%%      CUED DIRECTION (CAROUSEL MOVES IN PREDETERMINED PATTERN - AKA CONTROLLED EXPOSURES)
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
    tmp = zeros(length(ctx),1); tmp(edges_ctx) = 1;
    blks = [per, blkID, ctx' tmp];% non-boundary break periods (atO) are assigned to next block

    
    for cx = 1:4
        myBlks = find(blks(:,4) == cx);
        myPeriods = blks(find(blks(:,4) == cx),[1:2]);    
        [myLoc, myT] = SelectPeriods(location,myPeriods ,[],[],0);
        % ensure correct position scale    
        locs2Keep = [min(myLoc):1:max(myLoc)]';%locEdges = [min(tmpLoc):1:max(tmpLoc)]';
        locs{cx} = locs2Keep;
        locEdges = [1:1:720];
        %occupancy - should be rather flat (barring ramp in speed at start and end)    
        [occupancy]=histc(myLoc,locEdges); %(unique(myLoc))
        occupancy = occupancy./sum(occupancy);
        occup{cx} = occupancy;
    end
    
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
                    tmp = corrcoef(smooth_gauss(cellTuning(:,tr),w(j),sd3(j)),smooth_gauss(mu,w(j),sd3(j)));    
                    CC(tr) = tmp(2,1);
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

%%      PASSIVE ROTATIONS 
if flag == 3
    error('THIS OPTION IS NOT IMPLEMENTED YET you did not fix the tuning curve units here, the SSI is not available and this will lead to problems - fix before using!!!!!');
   display 'not implemented yet'; 
end


%% SAVE THE TUN STRUCTURE
    if options.flag == 1
        test = [tun.tuning];
        test = reshape(test,[size(tun(1).tuning,1),size(tun(1).tuning,2),length(test)/size(tun(1).tuning,2)]);    
    elseif options.flag == 2
        test = [];
    elseif options.flag == 3
        test = [];
    end
    % resort cells according to their ID (cids) 
    [~,I] = sort([tun(:,1).cids]); 
    tun = tun(I,:);
    tun(1).allTun = test;
    tun(1).fileBase = fileBase;
    tun(1).note = {'pos x trial x cluster'; 'cellType: 1 for MUA, 2 for SU'; 'CC: corr coef b/w trial  and mean of all trials'; 'CV: trial-by-trial covariance matrix';};
    tun(1).occupancy = occupancy;
    tun(1).pos = session.helper.positionBinCenters(locEdges);    
    save([fileBase,'.tun.mat'],'tun');%save('[fileBase,'.tun.mat'].mat','tun','tunNote','tunOccupancy','tunAll');


%% ADD PLACE FIELD STABILITY (computed across all trials)
    out = PFStability(fileBase);    
    % disp('here we create subfield PFStability(1), which details stability information on the ful trial set. PFStability2 could later encode those same variables but for a subset of trials. This could be invoked in selectCells.m');    
    % deal out variable to the tun structure
    for cx = 1:to
        for i = 1:length(tun)
            % find corresponding entries
            idx = find([out(i,1).cids] == tun(i,1).cids); % this matching of IDs might be reduntant but I will keep it as a safety
            if ~isempty(idx)
                tun(i,cx).PFStability(1).nmfW                 = out(idx,cx).nmfW;
                tun(i,cx).PFStability(1).nmfH                 = out(idx,cx).nmfH;
                tun(i,cx).PFStability(1).mainFieldActivity    = out(idx,cx).mainFieldActivity;
                tun(i,cx).PFStability(1).chPnt                = out(idx,cx).chPnt;
                tun(i,cx).PFStability(1).chPnt_pval           = out(idx,cx).chPnt_pval;
                tun(i,cx).PFStability(1).coefVar              = out(idx,cx).coefVar;
                tun(i,cx).PFStability(1).trials               = out(idx,cx).trials; 
            end
        end
    end
    clear out;
    
    
%% ADD PERMUTATION TEST FOR THE SPATIAL SELECTIVITY INDEX    
    disp('performing permutation tests for spatial selectivity indices');
    fprintf('...');
    if options.flag == 2; to = 4; else to = 1; end
    % deal out variable to the tun structure
    for i = 1:length(tun)   
        for cx = 1:to
            fprintf('\b');
            % find corresponding entries
            data = tun(i,cx).tuningSm;
            if isfield(tun,'locs2Keep')
                data = data(tun(i,cx).locs2Keep,:);
            end
            out = permutePlaceRasters(data);
            %idx = find([out.clu_idx] == tun(i).cids);
            tun(i,cx).PFStability(1).trueSSI              = out.trueSSI;
            tun(i,cx).PFStability(1).nullMap              = out.nullMap;
            tun(i,cx).PFStability(1).SSI_pval             = out.pval;
            tun(i,cx).PFStability(1).shuffleCorrectedSSI  = out.shufCorSSI;
            tun(i,cx).PFStability(1).SSIsOfShuffles       = out.shufflesSSI;
            fprintf('.'); pause(0.1);
        end
    end    
       
    
%% COMPUTE MEAN CLUSTER WAVEFORMS SPLIT BY PERIOD & MERGE INTO TUN STRUCT
    out = getMeanSpikePerPeriod(fileBase);
    
    
%% UPDATE THE TUN STRUCTURE
    save([fileBase,'.tun.mat'],'tun');    
    tun1 = joinTunNq(tun,nq,to);
    save([fileBase,'.tun1.mat'],'tun1');
   
    
%% GENERATE (AND SAVE) A FIGURE FOR EACH CLUSTER usings the intermediate tun structure... (convoluted and a bit risky, but means that I dont have to change the whole code)
    if options.verbose
        figure('pos',[2 30 876 1241]);
        processedPath = getfullpath(fileBase);
        tit = {'MUA','SU'};        
        locDeg = session.helper.positionBinCenters(locEdges);%locEdges = 3*(locEdges(1:end-1)+(locEdges(2)-locEdges(1)));
        % mean spike waveforms split by periods
        load('cluster_waveform_by_trial.mat'); 
        cWPT = cluWavePerTrial; % rename for convenience
        L = size(cWPT(1).wv,1);
        
        for i = 1:length(tun)
            clf;
            tmp = find([cWPT.cids] == tun(i).cids); % should match but double checking anyway
% waveform shape as a function trial                        
            ax = axes('pos',[.1 .68 .45 .2]);
            imAlpha=ones(size(cWPT(tmp).wv));
            imAlpha(isnan(cWPT(tmp).wv))=0;
            imagesc(cWPT(tmp).wv,'AlphaData',imAlpha); %axis xy;
            set(gca,'color',0.5*[1 1 1]);
            colormap(gca,'summer'); 
            clb = colorbar; xlabel(clb,'ampl (\muV)');
            ylabel('periods (#)'); 
            ax_sz = get(ax,'pos');
            
            
% rate as a function of trial in blue and in red is trial duration
            axes('pos',ax_sz);
            shadedErrorBar([],nanmean(cWPT(tmp).wv,1),nanstd(cWPT(tmp).wv),[],1); 
            wvCV = cWPT(tmp).wvCV;
            x = min(cWPT(tmp).wv,[],2);
            wvChPt = cWPT(tmp).wvChPt;
            wvChPtPval = cWPT(tmp).wvChPtPval;
            hold on;
            plot([10 10],ylim,'--k')
            axis tight;
            axis off;

            
            clrs = [(0.1+([1:L]/L)*0.2)' (0.5+([1:L]/L)*0.4)' ones(1,L)' 0.5*ones(1,L)'];
            cdd = uint8(clrs'*255);
            cdd(4,:) = 255;

            ax = axes('pos',[.68 .68 .25 .2]);
            frate = cWPT(tmp).nSpk./cWPT(tmp).dur;
            [haxes,hline1,hline2] = plotyy([1:1:L],frate,...
                                           [1:1:L],cWPT(tmp).dur);
            view([90 -90]); box off; 
            set(haxes(:),'xlim',[1 L]); % ,'ycolor','k'
            lm = get(haxes(2),'ylim');
            set(haxes,'Xdir','reverse');
            set(haxes(2),'LineWidth',1,'ytick',[0, round(max(lm)/2), max(lm)]); % ,'ycolor','r'
            ylabel(haxes(2),'duration (s)');
            ylabel(haxes(1),'rate (Hz)');
            set(hline2,'LineWidth',2,'Marker','o','linestyle','none');
            set(hline1,'LineWidth',2);% ,'Color',[0 0 1]
            xlabel('periods (#)'); 
            set(hline1.Edge,'ColorBinding','interpolated','ColorData',cdd);  pause(0.5);                         
            set(hline1.Edge,'ColorBinding','interpolated','ColorData',cdd);   
            hold(haxes(1)); 
            pk = abs(x)/max(abs(x))*max(frate);            
            plot(haxes(1),[1:1:L],pk,'k','linewidth',2);
            plot(haxes(1),wvChPt,pk(wvChPt),'or','markersize',10,'markerfacecolor','r');
            
            axes('pos',[.3 .7 .15 .1])
            for j = 1:L
                plot(smooth(cWPT(tmp).wv(j,:),4),'color',clrs(j,:),'Linewidth',1.2); %[0.1+(j/L)*0.2 0.5+(j/L)*0.4 1]
                hold on;
            end
                                   
% raster of all trials
            if to == 1
                ax(1) = axes('pos',[.1 .42 .5 .2]);
                imagesc(locDeg,1:1:size(tun(i).tuning,2),tun(i).tuning');  
                %axis xy;
                clm = flipud(colormap('gray'));
                hold on;box off; set(gca,'TickDir','out');
                ylabel('trial number (#)'); xlabel('carousel position (^o)');
                colormap(clm);hold on;xlim([0 360]);
                % add another axis with mean firing rate
                pos = get(gca,'pos');
                axes('pos',pos, 'YAxisLocation','right','color','none');
                lineClr = [1 0 0 0.5;0 1 0 0.5];
                plot(locDeg,smooth(tun(i).muTuning,4),'linewidth',3,'color',lineClr(tun(i).cellType,:));
                set(gca, 'YAxisLocation','right','color','none');
                xlim([0 360]);
                ylabel('firing rate (Hz)'); box off; set(gca,'TickDir','out');
                %title([tit{tun(i).cellType},' clu:',num2str(tun(i).cids)),' FR=',num2str(tun(i).muFR,'%0.2f'), ' {\itI}=',num2str(tun(i).SSI,'%0.2f'),' bits/spike, similarity:',num2str(nanmedian(tun(i).CC),'%0.2f')]);
            elseif to == 4
                % still missing the mean (trial-averaged) waveforms...
                ax(1) = axes('pos',[.1 .42 .5 .2]);
                maxTr = max([size(tun(i,1).tuning,2) size(tun(i,3).tuning,2)]) + 1;
                % trajectory to R target
                myX = tun(i,1).locs2Keep; myY = size(tun(i,1).tuning(myX,:),2);
                imagesc([1:length(myX)],[1:myY],fliplr(tun(i,1).tuning(myX,:)')); hold on;
                text(-125,0,'inbound   outbound','rotation',90,'horizontalalignment','center');
                text(60,maxTr,'A \rightarrow B','horizontalalignment','center')

                % trajectory to L target
                myX = tun(i,3).locs2Keep; myY = size(tun(i,3).tuning(myX,:),2);
                imagesc(fliplr(-[1:length(myX)]),[1:myY],fliplr(tun(i,3).tuning(myX,:)'));
                text(-60,maxTr,'C \leftarrow A','horizontalalignment','center')


                % trajectory from R to Origin
                myX = tun(i,2).locs2Keep; myY = size(tun(i,2).tuning(myX,:),2);
                imagesc([1:length(myX)],-[1:myY],tun(i,2).tuning(myX,:)');
                text(60,-maxTr,'B \rightarrow A','horizontalalignment','center')


                % trajectory from L to to Origin
                myX = tun(i,4).locs2Keep; myY = size(tun(i,4).tuning(myX,:),2);
                imagesc(fliplr(-[1:length(myX)]),-[1:myY],fliplr(tun(i,4).tuning(myX,:)')); 
                text(-60,-maxTr,'A \leftarrow C','horizontalalignment','center')

                box off; axis tight; axis xy;
                set(gca,'XAxisLocation', 'origin','YAxisLocation', 'origin');
                clm = flipud(colormap('gray'));
                colormap(clm);%colorbar;
            end


% violin plot of the trial corcoef with the mean response            
                axes('pos',[.75 .53 .14 .09]);
                pnts = []; categ = [];
                for cx = 1:to
                    pnts = [pnts, tun(i,cx).CC(find(~isnan(tun(i,cx).CC)))];
                    categ = [categ,cx*ones(length(tun(i,cx).CC(find(~isnan(tun(i,cx).CC)))),1)];    
                end
                if ~isempty(pnts)
                    violinplot(pnts,categ)
                else
                    text(.5,.5,'no data');
                end
                %    xlim([0 1]);ylim([0,1]);
                %if ~isempty(tun(i,cx).CC(find(~isnan(tun(i,cx).CC))))
                %    violinplot(tun(i,cx).CC(find(~isnan(tun(i,cx).CC))));  hold on;
                %    ylabel('cross-cor'); grid on; ylim([-0.5 1]);
                %else
                %    text(.5,.5,'no data');
                %    xlim([0 1]);ylim([0,1]);
                %end


% trial by trial covariance matrix  
            axes('pos',[.75 .39 .14 .14]);
            CV = tun(i).CV;%numel(
            imagesc((CV)); % imagesc(triu(CV));
            axis square; set(gca,'color','w','YTick',[1, round(length(CV)/2), length(CV)],'XTick',[1, round(length(CV)/2), length(CV)]); 
            %axis xy;
            xlabel('trial (#)'); ylabel('trial (#)'); colormap(gca,'jet'); %clb = colorbar; ylabel(clb,'covariance');

            
% nmfs across position (W)
            axes('pos',[.1 .24 .2 .1]);
            W = tun(i).PFStability(1).nmfW;
            W = W./max(W(:));
            plot(locDeg,W,'linewidth',2); % W(:,I)./norm(W,2) the norm        
            xlabel('carousel position (^o)'); ylabel('normalised activity');
            title('nmf-W');
            if to == 4
                xlim([min(tun(i).locs2Keep) max(tun(i).locs2Keep)]-360); 
            end

            
% nmf activations (H)
            axes('pos',[.4 .24 .2 .1]);
            H = tun(i).PFStability(1).nmfH;
            imagesc(H);
            xlabel('trial #'); ylabel('component');
            colormap(gca,'jet'); 
            title('nmf-H');
            
            
% in-field 1st nmf component activity across trials
            axes('pos',[.7 .24 .2 .1]);
            tmp = tun(i).PFStability(1).mainFieldActivity;
            plot(tmp); hold on;        
            a = tun(i).PFStability(1).chPnt;
            plot(a,tmp(a),'or','markersize',6,'markerfacecolor','r');
            xlabel('trial #'); ylabel('in-field 1st comp. activ.');


% boxplot trials before versus after changepoint (in-field 1st nmf component activity)
            axes('pos',[.1 .07 .2 .1]);
            gr = [zeros(1,length(tmp(1:a-1))),ones(1,length(tmp(a:end)))];
            boxplot(tmp,gr); 
            hold on;
            if tun(i).PFStability(1).chPnt_pval < 0.05
                plot(1.5,max(ylim)/2,'*r','markersize',10,'LineWidth',2);
            end           
            xlabel('before-after changepoint'); ylabel('in-field 1st comp. activ.');

            
% mean map of shuffles
            axes('pos',[.4 .07 .2 .1]);
            imagesc(locDeg,[],tun(i).PFStability(1).nullMap);
            colormap(gca,'jet');%axis xy;
            xlabel('carousel position (^o)'); ylabel('trial #');
            title('mean shuffle map');

            
% histogram of the shuffle SSIs
            axes('pos',[.7 .07 .2 .1]);
            histogram(tun(i).PFStability(1).SSIsOfShuffles); hold on;
            plot([tun(i).PFStability(1).trueSSI tun(i).PFStability(1).trueSSI],ylim,'--r','linewidth',2);
            hold on;
            if tun(i).PFStability(1).SSI_pval < 0.05
                plot(tun(i).PFStability(1).trueSSI/2 ,max(ylim)/2,'*r','markersize',10,'LineWidth',2);
            end
            xlabel('SSI');ylabel('counts #');
            
            set(all_subplots(gcf),'Xlimspec','tight','Ylimspec','tight','fontsize',11, 'box','off','tickdir','out')
            
% texts
            txt = {[tit{tun(i).cellType},' #',num2str(tun(i).cids),'      FR=',num2str(tun(i).muFR,'%0.2f'),'         SSI=',num2str(tun(i).SSI,'%0.2f'),' bits/spike'];
               ['chgpnt(main nmf field activity) = ', int2str(a-1),',   p=',num2str(tun(i).PFStability(1).chPnt_pval)];
               ['chgpnt(waveform amplitude) = ', int2str(wvChPt),',     p=',num2str(wvChPtPval)];
               ['CV(trials) = ', num2str(tun(i).PFStability(1).coefVar),  ',      CV(waveform) = ', num2str(wvCV)]
               ['activity = ' int2str(sum(tun(i).tuning(:))),' \propto nSpikes' ];};
            axes('pos',[0 0 1 1]);  
            text(0.1,0.94,txt,'fontsize',16); axis off; 
            if to == 4; text(0.1,0.36,'hereon, A to C is displayed only','fontsize',16); end
           
% save the figure
            print(gcf,[processedPath,'tuning_',num2str(tun(i).cids),'_',tit{tun(i).cellType},'_ch',num2str(tun(i).cluCh)],'-djpeg');
            %pause
        end    
    end
    
    
%% TO DELETE
    % ifPlot moved to the end
        if 1 == 0   
        % circular colorplot
        %{
            %R = [240:1:240+length(rewards.atStart)-1];Az = locEdges(1:end);
            %clf;polarPcolor(R,(360/(length(Az)-1))*Az,[cellTuning; cellTuning(1,:)]','circlesPos',[240 360],'spokesPos',[0 120 240],'colormap','jet');
            %hold on;            
            %text(0,0,['cell: ', num2str(gU(i))]);            
            %print(gcf,[processedPath,'cluster_',num2str(gU(i)),'_place_field_circ_raster'],'-djpeg');
            %waitforbuttonpress;clf;
        %}

        end
end

%% MODIFY THE TUN STRUCTRE ARRAY TO A PLAIN STRUCTURE
function tt = joinTunNq(tun,nq,to)
    disp 'joining tun with nq...'
    % CONVERT TUN STRUCTURE ARRAY TO A STRUCTURE -EASIER TO HANDLE AND CONSISTENT WITH NQ
    % nan variables to be populated:
    nTun                                = length(tun);
    nTr                                 = size(tun(1).tuning,3);
    tuning                              = nan(nTun,size(tun(1).tuning,1),size(tun(1).tuning,2),to);
    muTuning                            = nan(nTun,size(tun(1).muTuning,2),to);
    muFR                                = nan(nTun,to);
    SSI                                 = nan(nTun,1,to);
    cids                                = nan(nTun,1);
    cellType                            = nan(nTun,1);
    shank                               = nan(nTun,1);
    cluCh                               = nan(nTun,1);
    spkWidthR                           = nan(nTun,1);
    CC                                  = nan(nTun,size(tun(1).CC,1),to);
    muCC                                = nan(nTun,to);
    tuningSm                            = nan(nTun,size(tun(1).tuningSm,1),size(tun(1).tuningSm,2),to);
    CV                                  = nan(nTun,size(tun(1).CV,1),size(tun(1).CV,2),to);
    note                                = tun(1).note;
    
    locEdges                            = tun(1).pos;
    PFStability1_nmfW                   = nan(nTun,size(tun(1).PFStability.nmfW,1),size(tun(1).PFStability.nmfW,2),to);
    PFStability1_nmfH                   = nan(nTun,size(tun(1).PFStability.nmfH,1),size(tun(1).PFStability.nmfH,2),to);     
    PFStability1_mainFieldActivity      = nan(nTun,size(tun(1).PFStability.mainFieldActivity,2),to);
    PFStability1_chPnt                  = nan(nTun,1,to);
    PFStability1_chPnt_pval             = nan(nTun,1,to);
    PFStability1_coefVar                = nan(nTun,1,to);
    PFStability1_trials                 = tun(1).PFStability.trials;
    PFStability1_trueSSI                = nan(nTun,to);
    PFStability1_nullMap                = nan(nTun,size(tun(1).PFStability.nullMap,1),size(tun(1).PFStability.nullMap,2),to);
    PFStability1_SSI_pval               = nan(nTun,to);
    PFStability1_shuffleCorrectedSSI    = nan(nTun,to);
    PFStability1_SSIsOfShuffles         = nan(nTun,size(tun(1).PFStability.SSIsOfShuffles,1),to);

    if to == 1
        occupancy = tun(1).occupancy; 
    end
    if to == 4
        occupancy{1} = tun(1,1).occupancy;
        occupancy{2} = tun(1,2).occupancy;
        occupancy{3} = tun(1,3).occupancy;
        occupancy{4} = tun(1,4).occupancy;
        locs2Keep{1} = tun(1,1).locs2Keep;
        locs2Keep{2} = tun(1,2).locs2Keep;
        locs2Keep{3} = tun(1,3).locs2Keep;
        locs2Keep{4} = tun(1,4).locs2Keep;
    end
    
    
% POPULATE VARIABLES
for cx = 1:to
    for ii = 1:nTun
        % verify the cid matches
        if nq.cids(ii) ~= tun(ii).cids
            error('problem with cids???');
        end
        tuning(ii,:,:,cx)                  = tun(ii,cx).tuning;
        muTuning(ii,:,cx)                  = tun(ii,cx).muTuning;
        muFR(ii,cx)                        = tun(ii,cx).muFR;
        SSI(ii,cx)                         = tun(ii,cx).SSI;
        cids(ii)                           = tun(ii).cids; 
        cellType(ii)                       = tun(ii).cellType;
        shank(ii)                          = tun(ii).shank;
        cluCh(ii)                          = tun(ii).cluCh;
        %spkWidthR(ii)                   = tun(ii).spkWidthR;
        CC(ii,:,cx)                        = tun(ii,cx).CC;
        muCC(ii,cx)                        = tun(ii,cx).muCC;
        tuningSm(ii,:,:,cx)                = tun(ii,cx).tuningSm;
        CV(ii,:,:,cx)                      = tun(ii,cx).CV;
        nmfW(ii,:,:,cx)                    = tun(ii,cx).PFStability.nmfW;
        nmfH(ii,:,:,cx)                    = tun(ii,cx).PFStability.nmfH;
        mainFieldActivity(ii,:,cx)         = tun(ii,cx).PFStability.mainFieldActivity;
        chPnt(ii,cx)                       = tun(ii,cx).PFStability.chPnt;
        chPnt_pval(ii,cx)                  = tun(ii,cx).PFStability.chPnt_pval;
        coefVar(ii,cx)                     = tun(ii,cx).PFStability.coefVar;    
        trueSSI(ii,cx)                     = tun(ii,cx).PFStability.trueSSI;
        nullMap(ii,:,:,cx)                 = tun(ii,cx).PFStability.nullMap;
        SSI_pval(ii,cx)                    = tun(ii,cx).PFStability.SSI_pval;
        shuffleCorrectedSSI(ii,cx)         = tun(ii,cx).PFStability.shuffleCorrectedSSI;
        SSIsOfShuffles(ii,:,cx)            = tun(ii,cx).PFStability.SSIsOfShuffles;
    end
end

% PUT INTO A NEW TUN STRUCTURE
    tt.note                                   = {'cluster x pos x trial'; 'cellType: 1 for MUA, 2 for SU'; 'CC: corr coef b/w trial  and mean of all trials'; 'CV: trial-by-trial covariance matrix';};
    tt.occupancy                              = tun(1).occupancy;
    tt.locEdges                               = tun(1).pos;
    tt.tuning                                 = tuning;
    tt.muTuning                               = muTuning;
    tt.muFR                                   = muFR;
    tt.SSI                                    = SSI;
    %tun1.cids                                   = cids; 
    tt.cellType                               = cellType;
    tt.shank                                  = shank;
    %tun1.cluCh                                  = cluCh;
    %tun1.spkWidthR(i)                           = tun(i).spkWidthR;
    tt.CC                                     = CC;
    tt.muCC                                   = muCC;
    tt.tuningSm                               = tuningSm;
    tt.COV                                     = CV;
    tt.PFStability(1).nmfW                    = nmfW;
    tt.PFStability(1).nmfH                    = nmfH;
    tt.PFStability(1).mainFieldActivity       = mainFieldActivity;
    tt.PFStability(1).chPnt                   = chPnt;
    tt.PFStability(1).chPnt_pval              = chPnt_pval;
    tt.PFStability(1).coefVar                 = coefVar;
    tt.PFStability(1).trials                  = PFStability1_trials;
    tt.PFStability(1).trueSSI                 = trueSSI;
    tt.PFStability(1).nullMap                 = nullMap;
    tt.PFStability(1).SSI_pval                = SSI_pval;
    tt.PFStability(1).shuffleCorrectedSSI     = shuffleCorrectedSSI;
    tt.PFStability(1).SSIsOfShuffles          = SSIsOfShuffles;
    
    
%% JOIN NQ AND NEW TUN TO A SINGLE STRUCTURE?
    mergestructs = @(x,y) cell2struct([struct2cell(x);struct2cell(y)],[fieldnames(x);fieldnames(y)]);
    tt = mergestructs(nq,tt);
    
end