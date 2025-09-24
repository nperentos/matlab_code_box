function out = selectClusters(fileBase,varargin)

% selectClusters find clusters whos activity fulfills certain stability
% criteria. These criteria are defined using thresholds. 
% The output is the cell IDs as well as a figure with all the rasters
% of the cells colorcoded by shank number for visual inspection. More
% figures of rejected cells can be optionally generated. 
% Additionally the previously computed change points are used to decide if
% trials need to be ommitted becase of some coherent instability across
% cells. Same plots are generated and the new stability values are stored
% in the tun structure under tun.PFStability_2

% an alternative to the PFStability_2 option would be to go back to the
% begining and 

% change point for the NMF main field
% change point for the spike waveform peak
% coefficient of variation of NMF field across trials
% coefficient of variation of the spike amplitude across trials (periods)


%% DEFAULTS
    options = { 'SSI',0.01,...
                'nmfCV',[0.65],...
                'wvCV',[0.4],...            
                'fr_lim',[0.01],... % dont use to begin with
                'verbose',0,...
                'pth',[]};
    options = inputparser(varargin,options);

    
%% DATA

    if ~isempty(options.pth)
        processedPath = getfullpath(fileBase,options.pth);
        cd(processedPath);
    else
        processedPath = getfullpath(fileBase);
        cd(processedPath);
    end
    load([fileBase,'.tun1.mat']);
    tun = tun1; clear tun1;
    load('cluster_waveform_by_trial.mat'); 
    CWPT = cluWavePerTrial;
    clear cluWavePerTrial;
    % ensure there are no empty fields of interest
    for i = 1:length(CWPT)
        if isempty(CWPT(i).wvChPt)
            disp 'empty field'
            CWPT(i).wvChPt = nan;
        end
        if isempty(CWPT(i).wvChPtPval)
            CWPT(i).wvChPtPval = nan;
            disp 'empty field'
        end        
    end
    
    % third dimension is trials
    nTr = size(tun.tuning,3); %    nTr = size(tun(1).tuning,2);
    
    % verify that the cluster labels match
    lbls1 = vc(tun.cids);
    lbls2 = vc([CWPT.cids]);
    if length(lbls1) == length(lbls2)
        if any(lbls1 - lbls2)
            error('cluster labels dont match - investigate...')
        end
    end

    
%% DISCOVER COHERENT DRIFT ACROSS CLUSTERS

    chPnt1 = vc(tun.PFStability.chPnt);
    chPnt2 = vc([CWPT.wvChPt]);    
    
    % potential changepoint of trial tunings (nmf-based)
    hst1 = hist(chPnt1,nTr);
    zVal1 = zscore(hst1); %[pk,loc] = findpeaks(zVal, 'minpeakheight',4);
    p1 = 1 - (0.5 * erfc(-zVal1 ./ sqrt(2)));
    [Y,I] = min(p1);
    if p1(I) < 0.001; drft1 = I; else drft1 = inf; end
    
    % potential changepoint of spike amplitudes per period
    hst2 = hist(chPnt2,nTr);
    zVal2 = zscore(hst2); %[pk,loc] = findpeaks(zVal, 'minpeakheight',4);
    p2 = 1 - (0.5 * erfc(-zVal2 ./ sqrt(2)));
    [Y,I] = min(p2);
    if p2(I) < 0.001; drft2 = I; else drft2 = inf; end

    if abs(drft1-drft2) < 3
        drft = min(drft1,drft2);
        disp(['a valid change point was found at trial ',num2str(drft)]);        
        figure('pos',[96   847   978   460]); 
        bar(1:nTr,hst1','c'); hold on;
        bar(1:nTr,-hst2','b');
        plot([drft drft],[hst1(drft) -hst2(drft)],'r*','linewidth',3,'markersize',10);
        axis tight; xlabel('trial (#)'); ylabel('number of change points (#)');
    else
        drft = [];
        disp('no valid change point has been identified');
    end
    
    
%% IF THERE IS A VALID DRIFT POINT, GENERATE STABILITY VARS FOR THE TRIAL SPLITS
    % lets add waveform variables to the PFStability(2 and 3)
    st{1} = 1:nTr; 
if ~isempty(drft)
    st{2} = 1:drft; st{3} = drft+1:nTr;  
    for j = 1:3
        out = PFStability(fileBase,{'trs',st{j}});
        tun.PFStability(j).trials = out(1).trials;
        for i = 1:length(tun.cids)
            % find corresponding entries
            idx = find(vc([out(i).cids]) == tun.cids); % this matching of IDs might be reduntant but I will keep it as a safety

            if ~isempty(idx)
                if j > 1
                    tun.PFStability(j).nmfW(i,:,:)                 = out(idx).nmfW;
                    tun.PFStability(j).nmfH(i,:,:)                 = out(idx).nmfH;
                    tun.PFStability(j).mainFieldActivity(i,:,:)    = out(idx).mainFieldActivity;
                    tun.PFStability(j).chPnt(i,:,:)                = out(idx).chPnt;
                    tun.PFStability(j).chPnt_pval(i,:,:)           = out(idx).chPnt_pval;
                    tun.PFStability(j).coefVar(i,:,:)              = out(idx).coefVar;                     
                end
                % we must add the coefficient of variation for these
                % splits. There is no need to recompute the other variables
                % such as the change points etc since we are not making
                % more splits. We stop at one split. If there would be more
                % splits we would probably have to drop the dataset anyway.

                tmp1 = CWPT(i).wv; % waveforms for all the periods including breaks
                tmp2 = CWPT(i).nSpk; % number of spikes per period
                % find and remove the break periods
                df = size(tmp1,1) - nTr;
                if df == 3 % two block protocol
                    ix = fliplr([1 ceil(size(tmp1,1)/2) size(tmp1,1)]);
                    tmp1(ix,:) = [];
                    tmp2(ix) = [];
                end

                if df == 4 % three block protocol
                    ix = fliplr([1 ceil(size(tmp1,1)/3) ceil(size(tmp1,1)*2/3) size(tmp1,1)]); 
                    tmp1(ix,:) = [];
                    tmp2(ix) = [];
                end

                %
                x = min(tmp1(st{j},:),[],2);
                CVtmp = nanstd(x)./abs(nanmean(x));
                tun.PFStability(j).wvCV(i)    = CVtmp;
                tun.PFStability(j).nSpk(i,:)  = CWPT(idx).nSpk(st{j});
                clear tmp1 tmp2;
            end
        end
        clear out;
    end
end
%     % lets add waveform variables to the PFStability(1)
%     for i = 1:length(tun)
%         tmp1 = CWPT(i).wv; % waveforms for all the periods including breaks
%         tmp2 = CWPT(i).nSpk; % number of spikes per period
%         % find and remove the break periods
%         df = size(tmp1,1) - nTr;
%         if df == 3 % two block protocol
%             ix = fliplr([1 ceil(size(tmp1,1)/2) size(tmp1,1)]);            
%             tmp2(ix) = [];
%         end
% 
%         if df == 4 % three block protocol
%             ix = fliplr([1 ceil(size(tmp1,1)/3) ceil(size(tmp1,1)*2/3) size(tmp1,1)]);
%             tmp2(ix) = [];
%         end    
%         tun.PFStability(1).wvCV(i)               = tmp1;
%         tun.PFStability(1).nSpk(i,:)              = tmp2;
%     end

    
%% PICK CELLS     
ntp = {'mu','su'};
nW = {'IN','PC'};
close all;
for trialSet = 1:length(st)
    trialSet
    % coefficient of var.for the first nmf component field across trials
    kp1 = []; kp2 = []; ds = [];
    for i = 1:length(tun.cids)
        if tun.PFStability(trialSet).coefVar(i) < options.nmfCV
            kp1 = [kp1, tun.cids(i)];
        end
    end
    % coefficient of var.for the cluster waveforms binned by trials
    for i = 1:length(CWPT)
        %if CWPT(i).wvCV < options.wvCV
        if tun.PFStability(trialSet).wvCV(i) < options.wvCV && mean(tun.PFStability(trialSet).nSpk(i)) > 1
            kp2 = [kp2, CWPT(i).cids];
        end
    end 
    
    lst = intersect(kp1,kp2);
    
    if trialSet == 1
        % cells with changepoint near the drift location
        if ~isempty(drft)
            for i = 1:length(tun)
                if tun.PFStability(1).chPnt(i) > drft -2 && tun.PFStability(1).chPnt(i) < drft +2
                    if tun.PFStability(1).chPnt_pval(i) < 0.001
                        if CWPT(i).wvChPt	> drft -2 && CWPT(i).wvChPt < drft +2
                            if CWPT(i).wvChPtPval < 0.001
                                if ~isempty(find(lst == tun(i).cids))
                                    ds = [ds, tun(i).cids];
                                end
                            end
                        end                    
                    end
                end
            end
        end
    end
    
    
    if trialSet == 1; lst = setxor(lst,ds); end% remove those with valid switchpoint    
    lstx = setxor(lst,[tun.cids]);
    
    clr = distinguishable_colors(length(unique([tun.shank])),[1 1 1; 0 0 0]);
    mt = {'accepted cells, trials:','rejected cells, trials:'};
    for gr = 1:2
        if gr == 1; lstTmp = lst; shnk = zeros(length(lst),1); end
        if gr == 2; lstTmp = lstx; shnk = zeros(length(lstx),1);end
        if ~isempty(lstTmp)
            % sort cells by shank
            %clear shnk
            for i = 1:length(lstTmp)
                ix = find(tun.cids == lstTmp(i));
                try
                    shnk(i) = tun.shank(ix);
                    shnk(i) = tun.shank(ix);
                catch
                    warning(['empty shank field at tun(', num2str(ix),')']);
                    error('hah')
                end
            end
            [~,I] = sort(shnk);
            lstTmp = lstTmp(I);
            figure('units','normalized','outerposition',[0 0 1 1])
            clm = flipud(colormap('gray'));
            colormap(clm);
            totnum = length(lstTmp);
            xnum=ceil(totnum/sqrt(totnum));
            ynum=ceil(totnum/xnum);
            ax = tight_subplot(xnum, ynum, 0.005);
            for i = 1:length(lstTmp)
                axes(ax(i));
                j = find([tun.cids] == lstTmp(i));
                imagesc(sq(tun.tuningSm(j,:,st{trialSet}))'); hold on;
                axis tight; % axis xy;
                clri = clr(min([tun.shank(j) size(clr,1)]),:);
                set(ax(i),'ycolor',clri,'xcolor',clri,'xtick',[],'ytick',[],'linewidth',2);
                                
                phr = [num2str(lstTmp(i)),' ',ntp{(tun.cellType(j) == 2)+1},' ',nW{(tun.spkWidthR(j) > 0.525)+1}];
                
                text(max(xlim)/2,max(ylim)/2,phr,'color','k',...
                   'fontsize',7,'fontweight','bold','BackgroundColor', 'w','HorizontalAlignment', 'Center','edgecolor','k');           
            end
            mtit([mt{gr},num2str(st{trialSet}(1)),'-',num2str(st{trialSet}(end))],'fontsize',14);
            if gr == 1;
                print(gcf,[processedPath,'keptCells_trials_',num2str(st{trialSet}(1)),'-',num2str(st{trialSet}(end)),'.jpg'],'-djpeg');
            elseif gr == 2
                print(gcf,[processedPath,'rejectedCells_trials_',num2str(st{trialSet}(1)),'-',num2str(st{trialSet}(end)),'.jpg'],'-djpeg');
            end
        end
        out.cellList{trialSet,1} = lst;
        out.cellList{trialSet,2} = lstx;
        out.nCells(trialSet,1) = length(lst);
        out.nCells(trialSet,2) = length(lstx);
        out.trials{trialSet,1} = st{trialSet};
        out.trials{trialSet,2} = st{trialSet};        
        selectedClusters = out;
        save([fileBase,'.selectedClusters.mat'],'selectedClusters');
    end
end
close all;


%% SPATIAL COVERAGE REPORT FIGURES FOR THE SELECTED NEURONS
load([fileBase,'.selectedClusters.mat']);
load([fileBase,'.tun1.mat']);% load the tun structure
figure('pos',[ 380 7 1757 1233]); incr = 1;
cl = [0.0 0.5 0; 1 0 0];
q = {'accepted','rejected'};

% trial splits
for i = 1:size(selectedClusters.nCells,1)
    
    % accepted and rejected cells
    for j = 1:2 
        cells = selectedClusters.cellList{i,j};
        nC = length(cells);
        data = zeros(size(tun.tuning,2),size(tun.tuning,3),nC); % pre alocate
        
    % build an activities matrix (pos x trial x selected clusters)
        IDs = tun.cids;
        if length(tun.cids) ~= length(IDs)
            error('there are tun entries without a cluster number!');
        end
        
    % find clusters and build data matrix
        for k = 1:nC
            ix = find(IDs == cells(k));
            data(:,:,k) = tun.tuningSm(ix,:,:);
        end
        
    % sort tuning curves according to position
        % data: (pos x trial x selected clusters)
        pop_coverage = squeeze(mean(data,2)); % average across trials [position x cell]
        [~,I] = max(pop_coverage,[],1); % find max position of each place field
        [~,II] = sort(I); % get sorting order (early to late place field positions)    
        pop_coverage = pop_coverage; % ./max(pop_coverage,[],1)
        pop_coverage = pop_coverage(:,II); % sort by position
        
    % plot the coverage maps for each group
        subplot(3,2,incr);
        imagesc(linspace(1,360,size(pop_coverage,1)),[],(pop_coverage./max(pop_coverage,[],1))'); clb = colorbar;
        ylabel('putative unit (#)'); xlabel('carousel angular position (^o)');
        title([q{j},' cells, trials ',num2str(selectedClusters.trials{i,j}(1)),'-',num2str(selectedClusters.trials{i,j}(end))],'color',cl(j,:));
        drawnow;
        incr = incr + 1;
    end
end
set(all_subplots(gcf),'fontsize',11, 'box','off','tickdir','out','TitleFontSizeMultiplier',1.3);
print(gcf,[processedPath,'carousel_palce_cell_coverage_map.jpg'],'-djpeg');







%% BELOW IS A VERSION THAT WORKS GOOD WITH THE ORIGINAL TUN STRUCTURE ARRAY BEFORE ATTEMPTS TO JOIN THE TUN AND NQ INTO A STRUCT
%{

function out = selectClusters(fileBase,varargin)

% selectClusters find clusters whos activity fulfills certain stability
% criteria. These criteria are defined using thresholds. 
% The output is the cell IDs as well as a figure with all the rasters
% of the cells colorcoded by shank number for visual inspection. More
% figures of rejected cells can be optionally generated. 
% Additionally the previously computed change points are used to decide if
% trials need to be ommitted becase of some coherent instability across
% cells. Same plots are generated and the new stability values are stored
% in the tun structure under tun.PFStability_2

% an alternative to the PFStability_2 option would be to go back to the
% begining and 

% change point for the NMF main field
% change point for the spike waveform peak
% coefficient of variation of NMF field across trials
% coefficient of variation of the spike amplitude across trials (periods)


%% DEFAULTS
    options = { 'SSI',0.01,...
                'nmfCV',[0.65],...
                'wvCV',[0.4],...            
                'fr_lim',[0.01],... % dont use to begin with
                'verbose',0,...
                'pth',[]};
    options = inputparser(varargin,options);

    
%% DATA

    if ~isempty(options.pth)
        processedPath = getfullpath(fileBase,options.pth);
        cd(processedPath);
    else
        processedPath = getfullpath(fileBase);
        cd(processedPath);
    end
    load([fileBase,'.tun.mat']);
    load('cluster_waveform_by_trial.mat'); 
    CWPT = cluWavePerTrial;
    clear cluWavePerTrial;
    % ensure there are no empty fields of interest
    for i = 1:length(CWPT)
        if isempty(CWPT(i).wvChPt)
            disp 'empty field'
            CWPT(i).wvChPt = nan;
        end
        if isempty(CWPT(i).wvChPtPval)
            CWPT(i).wvChPtPval = nan;
            disp 'empty field'
        end        
    end
    
    % second dimension is trials
    nTr = size(tun(1).tuning,2);
    
    % verify that the cluster labels match
    lbls1 = [tun.cids];
    lbls2 = [CWPT.cids];
    if length(lbls1) == length(lbls2)
        if any(lbls1 - lbls2)
            error('cluster labels dont match - investigate...')
        end
    end

    
%% DISCOVER COHERENT DRIFT ACROSS CLUSTERS

    chPnt1 = [tun.PFStability]; chPnt1 = [chPnt1.chPnt]; 
    chPnt2 = [CWPT.wvChPt];    
    
    % potential changepoint of trial tunings (nmf-based)
    hst1 = hist(chPnt1,nTr);
    zVal1 = zscore(hst1); %[pk,loc] = findpeaks(zVal, 'minpeakheight',4);
    p1 = 1 - (0.5 * erfc(-zVal1 ./ sqrt(2)));
    [Y,I] = min(p1);
    if p1(I) < 0.001; drft1 = I; else drft1 = inf; end
    
    % potential changepoint of spike amplitudes per period
    hst2 = hist(chPnt2,nTr);
    zVal2 = zscore(hst2); %[pk,loc] = findpeaks(zVal, 'minpeakheight',4);
    p2 = 1 - (0.5 * erfc(-zVal2 ./ sqrt(2)));
    [Y,I] = min(p2);
    if p2(I) < 0.001; drft2 = I; else drft2 = inf; end

    if abs(drft1-drft2) < 3
        drft = min(drft1,drft2);
        disp(['a valid change point was found at trial ',num2str(drft)]);        
        figure('pos',[96   847   978   460]); 
        bar(1:nTr,hst1','c'); hold on;
        bar(1:nTr,-hst2','b');
        plot([drft drft],[hst1(drft) -hst2(drft)],'r*','linewidth',3,'markersize',10);
        axis tight; xlabel('trial (#)'); ylabel('number of change points (#)');
    else
        disp('no valid change point has been identified');
    end
    
    
%% IF THERE IS A VALID DRIFT POINT, GENERATE STABILITY VARS FOR THE TRIAL SPLITS
    % lets add waveform variables to the PFStability(2 and 3)
    st{1} = 1:nTr; 
    if ~isempty(drft)
        st{2} = 1:drft; st{3} = drft+1:nTr;    
        for j = 2:3
            out = PFStability(fileBase,{'trs',st{j}});
            for i = 1:length(tun)
                % find corresponding entries
                idx = find([out.cids] == tun(i).cids); % this matching of IDs might be reduntant but I will keep it as a safety
                if ~isempty(idx)
                    tun(i).PFStability(j).nmfW                 = out(idx).nmfW;
                    tun(i).PFStability(j).nmfH                 = out(idx).nmfH;
                    tun(i).PFStability(j).mainFieldActivity    = out(idx).mainFieldActivity;
                    tun(i).PFStability(j).chPnt                = out(idx).chPnt;
                    tun(i).PFStability(j).chPnt_pval           = out(idx).chPnt_pval;
                    tun(i).PFStability(j).coefVar              = out(idx).coefVar;
                    tun(i).PFStability(j).trials               = out(idx).trials; 

                    % we must add the coefficient of variation for these
                    % splits. There is no need to recompute the other variables
                    % such as the change points etc since we are not making
                    % more splits. We stop at one split. If there would be more
                    % splits we would probably have to drop the dataset anyway.

                    tmp1 = CWPT(i).wv; % all the periods including breaks
                    tmp2 = CWPT(i).nSpk; % number of spikes to use 
                    % find and remove the break periods
                    df = size(tmp1,1) - nTr;
                    if df == 3 % two block protocol
                        ix = [1 ceil(size(tmp1,1)/2) size(tmp1,1)];
                        tmp1(ix,:) = [];
                        tmp2(ix) = [];
                    end

                    if df == 4 % single block protocol
                        ix = [1 ceil(size(tmp1,1)/3) ceil(size(tmp1,1)*2/3) size(tmp1,1)];                                        
                        tmp1(ix,:) = [];
                        tmp2(ix) = [];
                    end

                    %
                    x = min(tmp1(st{j},:),[],2);
                    CVtmp = nanstd(x)./abs(nanmean(x));
                    tun(i).PFStability(j).wvCV               = CVtmp;
                    tun(i).PFStability(j).nSpk               = CWPT(idx).nSpk(st{j});
                    clear tmp1 tmp2;
                end
            end
            clear out;
        end
    end

    % lets add waveform variables to the PFStability(1)
    for i = 1:length(tun)
        tmp1 = CWPT(i).wvCV; % all the periods including breaks
        tmp2 = CWPT(i).nSpk; % number of spikes to use 
        % find and remove the break periods
        df = size(tmp1,1) - nTr;
        if df == 3 % two block protocol
            ix = fliplr([1 ceil(size(tmp1,1)/2) size(tmp1,1)]);            
            tmp2(ix) = [];
        end

        if df == 4 % single block protocol
            ix = [1 ceil(size(tmp1,1)/3) ceil(size(tmp1,1)*2/3) size(tmp1,1)];                                        
            tmp2(ix) = [];
        end    
        tun(i).PFStability(1).wvCV               = tmp1;
        tun(i).PFStability(1).nSpk               = tmp2;
    end

    
%% PICK CELLS     
ntp = {'mu','su'};
nW = {'IN','PC'};
close all;
for trialSet = 1:length(st)
    trialSet
    % coefficient of var.for the first nmf component field across trials
    kp1 = []; kp2 = []; ds = [];
    for i = 1:length(tun)
        if tun(i).PFStability(trialSet).coefVar < options.nmfCV
            kp1 = [kp1, tun(i).cids];
        end
    end
    % coefficient of var.for the cluster waveforms binend by trials
    for i = 1:length(CWPT)
        %if CWPT(i).wvCV < options.wvCV
        if tun(i).PFStability(trialSet).wvCV < options.wvCV && mean(tun(i).PFStability(trialSet).nSpk) > 1
            kp2 = [kp2, CWPT(i).cids];
        end
    end 
    
    lst = intersect(kp1,kp2);
    
    if trialSet == 1
        % cells with changepoint near the drift location
        if ~isempty(drft)
            for i = 1:length(tun)
                if tun(i).PFStability(1).chPnt > drft -2 && tun(i).PFStability(1).chPnt < drft +2
                    if tun(i).PFStability(1).chPnt_pval < 0.001
                        if CWPT(i).wvChPt	> drft -2 && CWPT(i).wvChPt < drft +2
                            if CWPT(i).wvChPtPval < 0.001
                                if ~isempty(find(lst == tun(i).cids))
                                    ds = [ds, tun(i).cids];
                                end
                            end
                        end                    
                    end
                end
            end
        end
    end
    
    
    if trialSet == 1; lst = setxor(lst,ds); end% remove those with valid switchpoint    
    lstx = setxor(lst,[tun.cids]);
    
    clr = distinguishable_colors(length(unique([tun.shank])),[1 1 1; 0 0 0]);
    mt = {'accepted cells, trials:','rejected cells, trials:'};
    for gr = 1:2
        if gr == 1; lstTmp = lst; shnk = zeros(length(lst),1); end
        if gr == 2; lstTmp = lstx; shnk = zeros(length(lstx),1);end
        if ~isempty(lstTmp)
            % sort cells by shank
            %clear shnk
            for i = 1:length(lstTmp)
                ix = find([tun.cids] == lstTmp(i));
                try
                    shnk(i) = tun(ix).shank;
                    shnk(i) = tun(ix).shank;
                catch
                    warning(['empty shank field at tun(', num2str(ix),')']);
                    error('hah')
                end
            end
            [~,I] = sort(shnk);
            lstTmp = lstTmp(I);
            figure('units','normalized','outerposition',[0 0 1 1])
            clm = flipud(colormap('gray'));
            colormap(clm);
            totnum = length(lstTmp);
            xnum=ceil(totnum/sqrt(totnum));
            ynum=ceil(totnum/xnum);
            ax = tight_subplot(xnum, ynum, 0.005);
            for i = 1:length(lstTmp)
                axes(ax(i));
                j = find([tun.cids] == lstTmp(i));
                imagesc(tun(j).tuningSm(:,st{trialSet})'); hold on;
                axis tight; % axis xy;
                clri = clr(min([tun(j).shank size(clr,1)]),:);
                set(ax(i),'ycolor',clri,'xcolor',clri,'xtick',[],'ytick',[],'linewidth',2);
                                
                phr = [num2str(lstTmp(i)),' ',ntp{(tun(j).cellType == 2)+1},' ',nW{(tun(j).spkWidthR > 0.525)+1}];
                
                text(max(xlim)/2,max(ylim)/2,phr,'color','k',...
                   'fontsize',7,'fontweight','bold','BackgroundColor', 'w','HorizontalAlignment', 'Center','edgecolor','k');           
            end
            mtit([mt{gr},num2str(st{trialSet}(1)),'-',num2str(st{trialSet}(end))],'fontsize',14);
            if gr == 1;
                print(gcf,[processedPath,'keptCells_trials_',num2str(st{trialSet}(1)),'-',num2str(st{trialSet}(end)),'.jpg'],'-djpeg');
            elseif gr == 2
                print(gcf,[processedPath,'rejectedCells_trials_',num2str(st{trialSet}(1)),'-',num2str(st{trialSet}(end)),'.jpg'],'-djpeg');
            end
        end
        out.cellList{trialSet,1} = lst;
        out.cellList{trialSet,2} = lstx;
        out.nCells(trialSet,1) = length(lst);
        out.nCells(trialSet,2) = length(lstx);
        out.trials{trialSet,1} = st{trialSet};
        out.trials{trialSet,2} = st{trialSet};        
        selectedClusters = out;
        save([fileBase,'.selectedClusters.mat'],'selectedClusters');
    end
end
close all;


%% SPATIAL COVERAGE REPORT FIGURES FOR THE SELECTED NEURONS
load([fileBase,'.selectedClusters.mat']);
load([fileBase,'.tun.mat']);% load the tun structure
figure('pos',[ 380 7 1757 1233]); incr = 1;
cl = [0.0 0.5 0; 1 0 0];
q = {'accepted','rejected'};

% trial splits
for i = 1:size(selectedClusters.nCells,1)
    
    % accepted and rejected cells
    for j = 1:2 
        cells = selectedClusters.cellList{i,j};
        nC = length(cells);
        data = zeros(size(tun(1).tuning,1),size(tun(1).tuning,2),nC); % pre alocate
        
    % build an activities matrix (pos x trial x selected clusters)
        IDs = [tun.cids];
        if length(tun) ~= length(IDs)
            error('there are tun entries without a cluster number!');
        end
        
    % find clusters and build data matrix
        for k = 1:nC
            ix = find(IDs == cells(k));
            data(:,:,k) = tun(ix).tuningSm;            
        end
        
    % sort tuning curves according to position
        % data: (pos x trial x selected clusters)
        pop_coverage = squeeze(mean(data,2)); % average across trials [position x cell]
        [~,I] = max(pop_coverage,[],1); % find max position of each place field
        [~,II] = sort(I); % get sorting order (early to late place field positions)    
        pop_coverage = pop_coverage; % ./max(pop_coverage,[],1)
        pop_coverage = pop_coverage(:,II); % sort by position
        
    % plot the coverage maps for each group
        subplot(3,2,incr);
        imagesc(linspace(1,360,size(pop_coverage,1)),[],(pop_coverage./max(pop_coverage,[],1))'); clb = colorbar;
        ylabel('putative unit (#)'); xlabel('carousel angular position (^o)');
        title([q{j},' cells, trials ',num2str(selectedClusters.trials{i,j}(1)),'-',num2str(selectedClusters.trials{i,j}(end))],'color',cl(j,:));
        drawnow;
        incr = incr + 1;
    end
end
set(all_subplots(gcf),'fontsize',11, 'box','off','tickdir','out','TitleFontSizeMultiplier',1.3);
print(gcf,[processedPath,'carousel_palce_cell_coverage_map.jpg'],'-djpeg');

%%
%}