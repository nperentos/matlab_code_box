function tun = getPlaceTuningNew(fileBase,flag,pth)
display('this function was modified to generate circular place field plots')
set(0, 'defaultFigurePosition',  [3841 1361 970 460]);
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
ifPlot = 0;
% check for type of carousel protocol
    if nargin < 2
        display('no task flag supplied - assuming continuous uni-direction');
        flag = 1;
        display('no data path provided assuming default:: ''/storage2/perentos/data/recordings/''');
        processedPath = getfullpath(fileBase);
    end

    if nargin == 3
        processedPath = getfullpath(fileBase,pth);
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

% load the nq structure so as to extract the shank property?
    load([fileBase,'.nq.mat']); % nq structure
    shnk = nq.cluAnatGroup;
    shnk_clu_ID = nq.cids;
    
%% UNIDIRECTIONAL PROTOCOL
if flag == 1
    incr = 1;
    for U = 1:2 % unit type (MUA or SUA)
        
        if U == 1; display('processing multi unit clusters...'); end
        if U == 2; display('processing putative single unit clusters...'); end

        figure;
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
            
    % now cell tuning split in trials    
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
            tun(incr).cellTunings(:,:) = cellTuning;
            tun(incr).meanCellTunings(:) = meanCellTuning;
            tun(incr).meanFR = muFR;
            tun(incr).SSI = SSI;
            tun(incr).cellID = gU(i);
            tun(incr).cellType = U;
            % please verify the following line in a different sort
    tun(incr).cellShnk = nq.cluAnatGroup(find(nq.cids == gU(i))); %% this seems to be wrong but only for the first cell???
            tun(incr).CC = CC';
            tun(incr).muCC = nanmean(CC);
            tun(incr).cellTuningSm(:,:) = cellTuningSm;
            tun(incr).CV = CV;
            incr = incr + 1;
        
        
    % conventional raster plot
        if ifPlot
            ax(1) = axes('pos',[.4 .14 .5 .75]);
            imagesc(3*locEdges,1:1:size(cellTuning,2),cellTuning');  axis xy;
            clm = flipud(colormap('gray'));
            hold on;box off; set(gca,'TickDir','out');
            ylabel('trial number (#)'); xlabel('carousel position (^o)')
            colormap(clm);hold on;xlim([0 360]);
            % add another axis with mean firing rate
            pos = get(gca,'pos');
            axes('pos',pos, 'YAxisLocation','right','color','none');
            lineClr = [1 0 0 0.5;0 1 0 0.5];
            plot(3*(locEdges(1:end-1)+(locEdges(2)-locEdges(1))),smooth(meanCellTuning,4),'linewidth',3,'color',lineClr(U,:));
            set(gca, 'YAxisLocation','right','color','none');
            xlim([0 360]);
            ylabel('firing rate (Hz)'); box off; set(gca,'TickDir','out');
            title([tit{U},' clu:',num2str(gU(i)),' FR=',num2str(muFR,'%0.2f'), ' {\itI}=',num2str(SSI,'%0.2f'),' bits/spike, similarity:',num2str(nanmedian(CC),'%0.2f')]);
            
    % violin plot of the trial corcoef with the mean response
            axes('pos',[.08 .52 .14 .36]);
            violinplot(CC(find(~isnan(CC)))); ylabel('cross-cor'); grid on;
            
    % trial by trial covariance matrix  
            axes('pos',[.05 .12 .28 .28]);

            imagesc((CV)); % imagesc(triu(CV));
            axis square; set(gca,'color','w','YTick',[1, round(length(CV)/2), length(CV)],'XTick',[1, round(length(CV)/2), length(CV)]); axis xy;
            xlabel('trial (#)'); ylabel('trial (#)'); colormap(gca,'jet'); clb = colorbar; ylabel(clb,'covariance');
            print(gcf,[processedPath,tit{U},'_',num2str(gU(i)),'_position_raster'],'-djpeg');
        end
            
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
        %mtit(tit{U});
        
    end
end


%% CUED DIRECTION
if flag == 2
    error('you did not fix the tuning curve units here, the SSI is not available and this will lead to problems - fix before using!!!!!');
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


%% PASSIVE ROTATIONS 
if flag == 3
   display 'not implemented yet'; 
end


%% SAVE THE TUN STRUCTURE
tun(1).note = {'pos x trial x cluster'; 'cellType: 1 for MUA, 2 for SU'; 'CC: corr coef b/w trial  and mean of all trials'; 'CV: trial-by-trial covariance matrix';'cellTuningSm: smoothed tuning rasters'};
tun(1).occupancy = occupancy;
tun(1).position = locEdges;
test = [tun.cellTunings];
test = reshape(test,[size(tun(1).cellTunings,1),size(tun(1).cellTunings,2),length(test)/size(tun(1).cellTunings,2)]);
tun(1).allTun = test;
save('place_cell_tunings.mat','tun');%save('place_cell_tunings.mat','tun','tunNote','tunOccupancy','tunAll');


%% ADD PLACE FIELD STABILITY

