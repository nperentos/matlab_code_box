function tun = getTuningCurves(fileBase,varargin)
%function tun = getPlaceTuningNew(fileBase,flag,pth)

% getTuningCurves extract trial resolve place fields and computes tuning 
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
    options = {'flag',1,'pth',[],'verbose',1};
    options = inputparser(varargin,options);

    ifPlot = 0;
    % % check for type of carousel protocol
    %     if nargin < 2
    %         display('no task flag supplied - assuming continuous uni-direction');
    %         flag = 1;
    %         display('no data path provided assuming default:: ''/storage2/perentos/data/recordings/''');
    %         processedPath = getfullpath(fileBase);
    %     end

    if ~isempty(options.pth)
        processedPath = getfullpath(fileBase,options.pth);
    else
        processedPath = getfullpath(fileBase);
    end

% bring in peripherals and spikes
    cd(processedPath)
    disp 'attempting to load peripherals'; 
    if exist('peripheralsPP.mat')
        load('peripheralsPP.mat');
        carouselSpeed = carouselGetVar(fileBase,{'carouselSpeed'},ppp,pppNames);
        tScale = carouselGetVar(fileBase,{'tScale'},ppp,pppNames);
        location = carouselGetVar(fileBase,{'posDiscr'},ppp,pppNames); %3degree bins...
        load('peripherals.mat');
        rewards = peripherals.events;
    else
        load('peripherals.mat');
    end
% load KS/phy output
    if exist(fullfile(processedPath,'KS'),'dir')
        cd KS;
        warning(' please consider moving the KS data into the main processed folder for compatibility');
    end
    sp = loadKSdir(pwd);
    tit = {'MUA','SU'};
    display('in kilosort neurons labelled with a ''1'' are multiunit clusters. Those labeled with 2 are putative single units');

% load the nq structure so as to extract the shank and channel number?
    load([fileBase,'.nq.mat']); % nq structure
    
%%      UNIDIRECTIONAL PROTOCOL
if options.flag == 1
    incr = 1;
    for U = 1:2 % unit type (MUA or SUA)
        
        if U == 1; display('processing multi unit clusters...'); end
        if U == 2; display('processing putative single unit clusters...'); end

        %figure;
        gU = sp.cids(sp.cgs == U);    
        p = numSubplots(length(gU));

        % sub select data where carousel or animal is moving
        % BUT idxMov should be taken from ppp since is already lodaded
        idxMv = find(carouselSpeed>1); % idxMv = find(runSpeed>1);
        tmpLoc = location(idxMv);
        % as it happens the position is already discretised within
        % peripheralsPP
        % locEdges = linspace(min(tmpLoc),max(tmpLoc),360/5); % 5 degree bins or 2*pi*25/(360/5)=2cm
        % positionInd = discretize(tmpLoc,locEdges);
        locEdges = [0 unique(tmpLoc)];
        positionInd = tmpLoc;
        tmptScale = tScale(idxMv);
        
        % this is not used but maybe it should unless accumarray corrects for this automatically(it should)        
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
            meanCellTuning = accumarray(positionInd',tmpSpikes,[numel(locEdges)-1,1],@mean).*(1/diff(tScale(1:2))); % thiis occupancy-normalised
            %sumCellTuning = accumarray(positionInd',tmpSpikes,[numel(locEdges)-1,1],@sum); % number of spikes in spatial bin
            muFR = (sum(tmpSpikes)/length(tmpSpikes)) * (1/diff(tScale(1:2))); % firing rate carousel movement periods (not overall for cluster)
    % Skaggs 1993 Information in bits per spike
            SSI = nansum(occupancy'.*meanCellTuning/muFR.*log2(meanCellTuning/muFR)); 
            
            
    % cell tuning split in trials    
            clear cellTuning; 
            cellTuning = zeros(numel(locEdges)-1, length(rewards.atStart));
            for j = 1:length(rewards.atStart)      
                % find the spikes that fall between carousel start points (per trial split)
                if j == 1
                    from = 1;
                else
                    from = find(tmptScale >= tScale( rewards.atStart(j))  ,1);
                end
                if j == length(rewards.atStart)
                    to = tmptScale(end);
                else
                    to = find(tmptScale >  tScale( rewards.atStart(j+1)),1) - 1;
                end                
                %cellTuning(:,j) = accumarray(positionInd(from:to)',tmpSpikes(from:to),[numel(locEdges)-1,1],@sum); 
                from = round(from); to = round(to);
                cellTuning(:,j) = accumarray(positionInd(from:to)',tmpSpikes(from:to),[numel(locEdges)-1,1],@mean).*(1/diff(tScale(1:2))); 
            end
                
            
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
            tun(1).fileBase = fileBase;
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


%%      CUED DIRECTION
if flag == 2
    error('THIS OPTION IS NOT IMPLEMENTED YET you did not fix the tuning curve units here, the SSI is not available and this will lead to problems - fix before using!!!!!');
    rewards.atStart = round(rewards.atStart); % /15.764
    rewards.atACW = round(rewards.atACW); % /15.764
    [idxLR,idxLR]=sort(direction);    
    for U = 1:2 % unit type (SU and MUA)
        %special case for IIT probe with autozeroing issue

        % is the direction variable available? % (should be if the protocol was bidirectional)        
        if ~exist('direction','var')            
            error('direction variable is missing - cannot proceed. Check if truly the  cued direction behavioral protocol was used in this session');
        end
        
        if U == 1; display('processing multi unit clusters...'); end
        if U == 2; display('processing putative single unit clusters...'); end

        figure;
        gU = sp.cids(sp.cgs == U);    
        p = numSubplots(length(gU));

        % sub select data where carousel or animal is moving
        idxMv = find(carouselSpeed>1); % idxMv = find(runSpeed>1);
        tmpLoc = location(idxMv);
        locEdges = linspace(min(tmpLoc),max(tmpLoc),360/5); % 5 degree bins or 2*pi*25/(360/5)=2cm
        positionInd = discretize(tmpLoc,locEdges);
        tmptScale = tScale(idxMv);
        
        % this is not used but maybe it should unless accumarray corrects for this automatically(it should)        
        [occupancy]=histc(tmpLoc,(unique(tmpLoc)));                
        occupancy = occupancy./sum(occupancy);
        
        % cycle through cells
        for i = 1:length(gU)   
            idxSp = find(sp.clu == gU(i));
            spT = round(sp.st(idxSp).*1000);
            res = zeros(size(tScale));
            res(spT) = 1; % spikes array as a series of 1s and 0s for the whole tScale
            tmpSpikes = res(idxMv); % keep spikes for movement periods

            % average cell tuning for carousel movement (or run?) periods only
            meanCellTuning = accumarray(positionInd',tmpSpikes,[numel(locEdges)-1,1],@mean); 

            % now cell tuning split in trials    
            clear cellTuning;    
            for j = 1:length(rewards.atStart)      
                % find the spikes that fall between carousel start points (per trial split)
                if j == 1
                    from = 1;
                else
                    from = find(tmptScale >= tScale( rewards.atStart(j))  ,1);
                end
                if j == length(rewards.atStart)
                    to = tmptScale(end);
                elseif j>1 & j~= length(rewards.atStart)
                    to = find(tmptScale >  tScale( rewards.atStart(j+1)),1) - 1;
                elseif j == 1
                    to = find(tmptScale >  tScale( rewards.atStart(j)),1);
                end
                display(['from ', num2str(from), ' to ',num2str(to)]);
                cellTuning(:,j) = accumarray(positionInd(from:to)',tmpSpikes(from:to),[numel(locEdges)-1,1],@sum);
                if strcmp(direction(j),'L')
                    cellTuning(:,j) = flipud(cellTuning(:,j));
                end
                
            end


            % plot
%             figure(10+10*U-1); 
            
            subplot(p(1),p(2),i);
%             imagesc( locEdges(2:end), [], cellTuning(:,strfind(direction,'R'))');  axis xy; hold on;
%             clm = flipud(colormap('gray'));
%             hold on;
%             colormap(clm);
%             figure(10+10*U+1);
%             subplot(p(1),p(2),i);
%             imagesc(locEdges(2:end), [], cellTuning(:,strfind(direction,'L'))');

            imagesc(locEdges(2:end), [], cellTuning(:,idxLR)');xlim([0 4400]);
            clm = flipud(colormap('gray'));
            hold on;
            colormap(clm);
            hold on;    
            plot(locEdges(1:end-1)+(locEdges(2)-locEdges(1)),...
                smooth((meanCellTuning./max(meanCellTuning)).*length(rewards.atStart),3));
            title(num2str(gU(i)));
        end
        mtit(tit{U});
    end
end


%%      PASSIVE ROTATIONS 
if flag == 3
    error('THIS OPTION IS NOT IMPLEMENTED YET you did not fix the tuning curve units here, the SSI is not available and this will lead to problems - fix before using!!!!!');
   display 'not implemented yet'; 
end


%% SAVE THE TUN STRUCTURE
    tun(1).note = {'pos x trial x cluster'; 'cellType: 1 for MUA, 2 for SU'; 'CC: corr coef b/w trial  and mean of all trials'; 'CV: trial-by-trial covariance matrix';};
    tun(1).occupancy = occupancy;
    tun(1).locEdges = locEdges;
    test = [tun.tuning];
    test = reshape(test,[size(tun(1).tuning,1),size(tun(1).tuning,2),length(test)/size(tun(1).tuning,2)]);
    tun(1).allTun = test;
    % resort cells according to their ID (cids)
    [~,I] = sort([tun.cids]);
    tun = tun(I);
    save([fileBase,'.tun.mat'],'tun');%save('[fileBase,'.tun.mat'].mat','tun','tunNote','tunOccupancy','tunAll');


%% ADD PLACE FIELD STABILITY (computed across all trials)
    out = PFStability(fileBase);
    % disp('here we create subfield PFStability(1), which details stability information on the ful trial set. PFStability2 could later encode those same variables but for a subset of trials. This could be invoked in selectCells.m');    
    % deal out variable to the tun structure
    for i = 1:length(tun)
        % find corresponding entries
        idx = find([out.cids] == tun(i).cids); % this matching of IDs might be reduntant but I will keep it as a safety
        if ~isempty(idx)
            tun(i).PFStability(1).nmfW                 = out(idx).nmfW;
            tun(i).PFStability(1).nmfH                 = out(idx).nmfH;
            tun(i).PFStability(1).mainFieldActivity    = out(idx).mainFieldActivity;
            tun(i).PFStability(1).chPnt                = out(idx).chPnt;
            tun(i).PFStability(1).chPnt_pval           = out(idx).chPnt_pval;
            tun(i).PFStability(1).coefVar              = out(idx).coefVar;
            tun(i).PFStability(1).trials               = out(idx).trials; 
        end
    end
    clear out;
    
    
%% ADD PERMUTATION TEST FOR THE SPATIAL SELECTIVITY INDEX    
    disp('performing permutation tests for spatial selectivity indices');
    fprintf('...');
    % deal out variable to the tun structure
    for i = 1:length(tun)        
        fprintf('\b');
        % find corresponding entries
        data = tun(i).tuningSm;
        out = permutePlaceRasters(data);
        %idx = find([out.clu_idx] == tun(i).cids);
        tun(i).PFStability(1).trueSSI              = out.trueSSI;
        tun(i).PFStability(1).nullMap              = out.nullMap;
        tun(i).PFStability(1).SSI_pval             = out.pval;
        tun(i).PFStability(1).shuffleCorrectedSSI  = out.shufCorSSI;
        tun(i).PFStability(1).SSIsOfShuffles       = out.shufflesSSI;
        fprintf('.'); pause(0.1);
    end    
       
    
%% COMPUTE MEAN CLUSTER WAVEFORMS SPLIT BY PERIOD $ MERGE INTO TUN STRUCT
    out = getMeanSpikePerPeriod(fileBase);
    
    
%% UPDATE THE TUN STRUCTURE
    save([fileBase,'.tun.mat'],'tun');    
    tun1 = joinTunNq(tun,nq);
    save([fileBase,'.tun1.mat'],'tun1');
   
    
%% GENERATE (AND SAVE) A FIGURE FOR EACH CLUSTER usings the intermediate tun structure... (convoluted and a bit risky, but means that I dont have to change the whole code)
    if options.verbose
        figure('pos',[2 30 876 1241]);
        processedPath = getfullpath(fileBase);
        tit = {'MUA','SU'};        
        locEdges = tun(1).locEdges;
        locEdges = 3*(locEdges(1:end-1)+(locEdges(2)-locEdges(1)));
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
            ax(1) = axes('pos',[.1 .42 .5 .2]);
            imagesc(locEdges,1:1:size(tun(i).tuning,2),tun(i).tuning');  
            %axis xy;
            clm = flipud(colormap('gray'));
            hold on;box off; set(gca,'TickDir','out');
            ylabel('trial number (#)'); xlabel('carousel position (^o)');
            colormap(clm);hold on;xlim([0 360]);
            % add another axis with mean firing rate
            pos = get(gca,'pos');
            axes('pos',pos, 'YAxisLocation','right','color','none');
            lineClr = [1 0 0 0.5;0 1 0 0.5];
            plot(locEdges,smooth(tun(i).muTuning,4),'linewidth',3,'color',lineClr(tun(i).cellType,:));
            set(gca, 'YAxisLocation','right','color','none');
            xlim([0 360]);
            ylabel('firing rate (Hz)'); box off; set(gca,'TickDir','out');
            %title([tit{tun(i).cellType},' clu:',num2str(tun(i).cids)),' FR=',num2str(tun(i).muFR,'%0.2f'), ' {\itI}=',num2str(tun(i).SSI,'%0.2f'),' bits/spike, similarity:',num2str(nanmedian(tun(i).CC),'%0.2f')]);


% violin plot of the trial corcoef with the mean response
            axes('pos',[.75 .53 .14 .09]);
            violinplot(tun(i).CC(find(~isnan(tun(i).CC)))); ylabel('cross-cor'); grid on;
            ylim([-0.5 1]);


% trial by trial covariance matrix  
            axes('pos',[.75 .39 .14 .14]);
            CV = tun(i).CV;
            imagesc((CV)); % imagesc(triu(CV));
            axis square; set(gca,'color','w','YTick',[1, round(length(CV)/2), length(CV)],'XTick',[1, round(length(CV)/2), length(CV)]); 
            %axis xy;
            xlabel('trial (#)'); ylabel('trial (#)'); colormap(gca,'jet'); %clb = colorbar; ylabel(clb,'covariance');

            
% nmfs across position (W)
            axes('pos',[.1 .24 .2 .1]);
            W = tun(i).PFStability(1).nmfW;
            plot(locEdges,W./max(W(:)),'linewidth',2); % W(:,I)./norm(W,2) the norm        
            xlabel('carousel position (^o)'); ylabel('normalised activity');
            title('nmf-W');

            
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
            imagesc(locEdges,[],tun(i).PFStability(1).nullMap);
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
function tt = joinTunNq(tun,nq)
% no need to lad anything
    if 1 == 0
        processedPath = getfullpath(fileBase); cd(processedPath);
    
        load([fileBase,'.nq.mat']);
        load([fileBase,'.tun.mat']);
    
        id1 = vc([tun.cids]);
        id2 = vc(nq.cids);
    
        if max(abs(id1(:)-id2(:))) ~=0
            error('cluster ids (cids) do not match eventhough they should!');
        else
            disp('cluster ids match between nq and tun so proceeding...');
        end
    end


% CONVERT TUN STRUCTURE ARRAY TO A STRUCTURE -EASIER TO HANDLE AND CONSISTENT WITH NQ
    % nan variables to be populated:
    nTun                                = length(tun);
    nTr                                 = size(tun(1).tuning,3);
    tuning                              = nan(nTun,size(tun(1).tuning,1),size(tun(1).tuning,2));
    muTuning                            = nan(nTun,size(tun(1).muTuning,2));
    muFR                                = nan(nTun,1);
    SSI                                 = nan(nTun,1);
    cids                                = nan(nTun,1);
    cellType                            = nan(nTun,1);
    shank                               = nan(nTun,1);
    cluCh                               = nan(nTun,1);
    spkWidthR                           = nan(nTun,1);
    CC                                  = nan(nTun,size(tun(1).CC,1));
    muCC                                = nan(nTun,1);
    tuningSm                            = nan(nTun,size(tun(1).tuningSm,1),size(tun(1).tuningSm,2));
    CV                                  = nan(nTun,size(tun(1).CV,1),size(tun(1).CV,2));
    note                                = tun(1).note;
    occupancy                           = tun(1).occupancy;
    locEdges                            = tun(1).locEdges;
    PFStability1_nmfW                   = nan(nTun,size(tun(1).PFStability.nmfW,1),size(tun(1).PFStability.nmfW,2));
    PFStability1_nmfH                   = nan(nTun,size(tun(1).PFStability.nmfH,1),size(tun(1).PFStability.nmfH,2));     
    PFStability1_mainFieldActivity      = nan(nTun,size(tun(1).PFStability.mainFieldActivity,2));                   
    PFStability1_chPnt                  = nan(nTun,1);
    PFStability1_chPnt_pval             = nan(nTun,1);
    PFStability1_coefVar                = nan(nTun,1);
    PFStability1_trials                 = tun(1).PFStability.trials;
    PFStability1_trueSSI                = nan(nTun,1);
    PFStability1_nullMap                = nan(nTun,size(tun(1).PFStability.nullMap,1),size(tun(1).PFStability.nullMap,2));
    PFStability1_SSI_pval               = nan(nTun,1);
    PFStability1_shuffleCorrectedSSI    = nan(nTun,1);
    PFStability1_SSIsOfShuffles         = nan(nTun,size(tun(1).PFStability.SSIsOfShuffles,1));


% POPULATE VARIABLES
    for ii = 1:nTun
        % verify the cid matches
        if nq.cids(ii) ~= tun(ii).cids
            error('problem with cids???');
        end
        tuning(ii,:,:)                  = tun(ii).tuning;
        muTuning(ii,:)                  = tun(ii).muTuning;
        muFR(ii)                        = tun(ii).muFR;
        SSI(ii)                         = tun(ii).SSI;
        cids(ii)                        = tun(ii).cids; 
        cellType(ii)                    = tun(ii).cellType;
        shank(ii)                       = tun(ii).shank;
        cluCh(ii)                       = tun(ii).cluCh;
        %spkWidthR(ii)                   = tun(ii).spkWidthR;
        CC(ii,:)                        = tun(ii).CC;
        muCC(ii)                        = tun(ii).muCC;
        tuningSm(ii,:,:)                = tun(ii).tuningSm;
        CV(ii,:,:)                      = tun(ii).CV;
        nmfW(ii,:,:)                    = tun(ii).PFStability.nmfW;
        nmfH(ii,:,:)                    = tun(ii).PFStability.nmfH;
        mainFieldActivity(ii,:)         = tun(ii).PFStability.mainFieldActivity;
        chPnt(ii)                       = tun(ii).PFStability.chPnt;
        chPnt_pval(ii)                  = tun(ii).PFStability.chPnt_pval;
        coefVar(ii)                     = tun(ii).PFStability.coefVar;    
        trueSSI(ii)                     = tun(ii).PFStability.trueSSI;
        nullMap(ii,:,:)                 = tun(ii).PFStability.nullMap;
        SSI_pval(ii)                    = tun(ii).PFStability.SSI_pval;
        shuffleCorrectedSSI(ii)         = tun(ii).PFStability.shuffleCorrectedSSI;
        SSIsOfShuffles(ii,:)            = tun(ii).PFStability.SSIsOfShuffles;
    end


% PUT INTO A NEW TUN STRUCTURE
    tt.note                                   = {'cluster x pos x trial'; 'cellType: 1 for MUA, 2 for SU'; 'CC: corr coef b/w trial  and mean of all trials'; 'CV: trial-by-trial covariance matrix';};
    tt.occupancy                              = tun(1).occupancy;
    tt.locEdges                               = tun(1).locEdges;
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