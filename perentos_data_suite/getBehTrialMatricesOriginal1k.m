function getBehTrialMatrices(fileBase,varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% getBehTrialMatrices(fileBase,varargin) generates trial-resolved 
% activity for each behavioral variable of behavior.mat. The structure of 
% the output variable A depends on the type of behavioral protocol. Note
% that some matrices will be time- while others position- resolved. 
% e.g. in continuous protocols, matrices are given by position
% in controlled protocols, the matrices are given in position during
% carousel movement but in time during stops at the targets
% Works for both passive and active rotation tasks. cued direction not 
% implemented (yet)
% 13/09/2020 - created
% 30/09/2020 - change circular variables from @mean to @CircularMean_angle_only function (in accumarray)
% 22/10/2020 - readapting so that trial blocks are explicitly stated in
% spreadsheet thus avoiding troubles with automatic definition
% 04/11/2020 - more updates to allow for more special cases
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% PRE                       
    %fprintf('plotting position-resolved behavioral variables on carousel ...');
    options = {'varList',[],'polar',1}; % if varlist is empty all variables 
    options = inputparser(varargin,options);
    if strcmp(options,'error'); return; end;
    figure; clrs = get(gca,'colororder');close;
    
    
%% LOAD DATA                 
    [session, behavior] = loadSession(fileBase);
    % faster to load ALL data once rather than one by one through memmap
    tic;bdata = behavior.data.data;toc

    
%% GET GENERAL VARIABLES     
    SR_LFP = session.info.SR_LFP;
    SR_WB = session.info.SR_WB;
    SR_F = SR_WB/SR_LFP;
    nBlocks = session.info.nBlocks;
    nTrials = session.info.nTrials;
    nTrOfs = round(nTrials*0.9); % n of trials offset for vis only
    brk = 4; % num of trials to inject between blocks for vis only
    breakDurations = session.info.breakDurations;
    trialsPerBlock = session.info.trialsPerBlock;
    rejTrials = session.info.rejTrials;
    %pupil = nTrials/nBlocks; 
    if ~isempty(session.info.trialsPerBlock)
        blocks = session.info.trialsPerBlock;
    end
    tBreaks = session.info.breakDurations;
    conds = session.info.conditions;
    if strcmp(session.info.taskType,'continuous')
        taskType = 1; disp('task type is continuous (closed loop, carousel coupled to running).');
    elseif strcmp(session.info.taskType,'controlled')
        taskType = 0; disp('task type is controlled (open loop, carousel un-coupled to running).');
    else
        error('cannot plot for task types other than continuous and controlled...');
    end        
    if length(conds) ~= nBlocks
        error('the number of behavioral blocks does not match the number of conditions. Please check. Aborting');
    end
    position = bdata(:,find(strcmp('position',behavior.name))); % position in degrees
    posDiscr = bdata(:,find(strcmp('posDiscr',behavior.name))); % must keep as indices for accumarray
    % posDiscr = session.helper.positionBinCenters(posDiscr);     % discretised to 1 degree res
    idxMov = session.helper.idxMov;
    idxTrials = session.helper.idxTrials;
       
    if ~taskType
        ctx = session.helper.position_context.context; % the 'contexts'
        if any(ctx == 0)
            warning('there must have been a problem with the carousel location extraction. Please check...');
            fprintf(['trials marked for rejection: ',num2str(rejTrials),' \n']);
        end 
    end
    
    
%% MAIN - CONTINUOUS TASK    
if taskType == 1
    
% ensure protocol is unidirectional
    if false(length(strfind(session.events.direction','R')) == length(session.events.direction) ||...
            length(strfind(session.events.direction','L')) == length(session.events.direction))
        error('non unidirectional protocol ... please investigate');
    end
    
% extract variable's activity for each trial    
    for nV = 1:length(behavior.name)
        clear vals tmp idx;       
        x = bdata(:,nV);
        %name = behavior.name{nV}; fprintf([name,'\n']);
        %if strcmp(name,'lick_events')
        %   x = x+eps; 
        %end
        bnsz = 1; posEdges = [-360:bnsz:360];
        tun = zeros(length(posEdges)-1,nTrials);
        endTrials = cumsum(trialsPerBlock);% at end of blocks...
        if length(endTrials) == 1; endTrials = 0; else endTrials(end) = []; end
        for i = 1:nTrials
            %idx = find(idxTrials == i & idxMov == 1); % ignore data if carousel is not moving
            idx = find(idxTrials == i ); % carousel movement AND non movement periods    
            if ismember(i,endTrials) %need to guard against delayed (post break atStart 2-pulse TTL)
                idxI = find(idxMov(idx) == 1,1,'last');
                idx = idx(1:idxI);
            end

            tun(:,i) = [accumarray(posDiscr(idx),x(idx),[numel(posEdges)-1,1],@mean)];
            traj{i} = x(idx); % full trajectory - no averaging
            traj_pos{i} = posDiscr(idx);  % respective position
            traj_time{i} = [idx(1) idx(end)];
            if strfind(behavior.name{nV},'phase') % overwrite the linear means with circular means for the phase variables
                tun(:,i) = [accumarray(posDiscr(idx),x(idx),[numel(posEdges)-1,1],@CircularMean_angle_only)];
            end
        end
        Az = posEdges(361:end); Az = (360/(length(Az)-1))*Az; Az = [Az(2:end),Az(2)];
        tun = [tun(361:end,:); tun(361,:)];
        
        true_tun = tun(1:end-1,:);
        true_Az = Az(1:end-1);  
                
        % populate output variable
        blk_tmp = [0, cumsum(trialsPerBlock)];
        for i = 1:nBlocks
            thisBlock = [blk_tmp(i)+1:blk_tmp(i+1)];
            A(nV).ctx_lbl = 'position-resolved activity as a function of trial number separated in blocks';
            A(nV).varName = behavior.name{nV};
            A(nV).trialNum{i} = thisBlock;
            A(nV).tun{i} = true_tun(:,A(nV).trialNum{i}); % position resolved behavioral activity
            A(nV).traj{i} = traj(A(nV).trialNum{i}); % time resolved behavioral activity (one time series per trial)
            A(nV).traj_pos{i} = traj_pos(A(nV).trialNum{i}); % time resolved position (one time series per trial)
            A(nV).traj_time{i} = traj_time(A(nV).trialNum{i}); 
            A(nV).xax{i} = true_Az; % posiiton bins relating to A.tun variable
            A(nV).xax_lbl{i} = 'position (^o)'; % a label for the x-axis of the tun variable
        end
        
        % add break period activities
        for i = 1:nBlocks + 1 % there should be nBlocks+1 'breaks' all up
            if i == 1 % first
                A(nV).breakPeriods(i,:) = [1,min([session.events.TTL.atStart(1,1), find(session.helper.idxMov, 1, 'first')])];
            elseif i == nBlocks + 1 % last
                A(nV).breakPeriods(i,:) = [round(session.events.TTL.all(end,1)./SR_F), length(position)];
            else % need to guard against possible delayed (post break atStart 2-pulse TTL)
                % last momvent tpoint at or before the atOrigin TTL
                t1 = find(idxMov(1:session.events.TTL.atStart(endTrials(i-1))) == 1,1,'last');
                t2 = find(idxMov(session.events.TTL.atStart(endTrials(i-1)):end) == 1,1,'first') + session.events.TTL.atStart(endTrials(i-1));
                A(nV).breakPeriods(i,:) = [t1,t2];
            end
        end
        
% report figures
        close all;
        figure('pos',[30 30 1040 460]); 
        subplot(2,5,[1 2 3 6 7 8]);                
        brk = 6;% brk is to make a break between blocks
        ofs = (1.5*(nTrials+nBlocks*brk)); ofs = ofs - rem(ofs,10); %ofs is to make ring rather than circle
        % inject nans between blocks to aid with visualisation
        for k = 1:nBlocks - 1
            injAt = k*(nTrials/nBlocks) + 1 + brk*(k-1);
            inj = nan(size(tun,1),brk);
            %tun = [tun(:,1:nTrials/2), inj,tun(:,nTrials/2+1:end)];
            tun = [tun(:,1:injAt-1), inj,tun(:,injAt:end)];
        end

        %R = [1:nTrials+brk*nBlocks]+ofs; %[ofs:ofs+size(tun,2)-1];
        R = [1:nTrials+brk*(nBlocks-1)]+ofs; %[ofs:ofs+size(tun,2)-1];

        [h,c] = polarCarouselPlot(R, Az, tun,...
            'Nspokes', 3 ,...    
            'spokesPos', [0 120 240] ,...
            'Ncircles', 2,...
            'circlesPos',[R(1) R(end)],... 
            'RtickLabel',{'1^{st} trial', ['last trial']},... %,num2str(nTrials)
            'colBar',1,...
            'colormap','jet',...
            'direction','continuous');
        view([0 -90]);
        axis tight; 
        if strfind(behavior.name{nV},'phase')
           CircColormap;
           clmp=colormap(gca);
           clmp = [.8 .8 .8 ;clmp];
           colormap(gca,clmp)
        end
        
        ps = get(gca,'position');
        c.Position = [0.9*c.Position(1) c.Position(2) 0.7*c.Position(3) 0.4*c.Position(4)];
        set(gca,'Position', ps);
        axes('pos',[0 0 1 1]);


        % MEAN BEHAVIORAL ACTIVITY FOR EACH BEHAVIORAL BLOCK ON CARTESIAN COORDINATES
        subplot(2,5,[4 5]); hold on;
        for i = 1:nBlocks
            mus(:,i) = mean(true_tun(:,[1:nTrials/nBlocks]+(i-1)*(nTrials/nBlocks)),2);
            sds(:,i) = std(true_tun(:,[1:nTrials/nBlocks]+(i-1)*(nTrials/nBlocks)),[],2);
            if strfind(behavior.name{nV},'phase')
                [m,r] = CircularMean(true_tun(:,[1:nTrials/nBlocks]+(i-1)*(nTrials/nBlocks)),2);
                mus(:,i) = m;
                sds(:,i) = 1/r;%std(true_tun(:,[1:nTrials/nBlocks]+(i-1)*(nTrials/nBlocks)),[],2);
            end
            H(i) = shadedErrorBar(true_Az, mus(:,i),sds(:,i),{'color',clrs(i,:)},1);
        end
        if strfind(behavior.name{nV},'phase')
            for i = 1:nBlocks
                [m,r] = CircularMean(true_tun(:,[1:nTrials/nBlocks]+(i-1)*(nTrials/nBlocks)),2);
                mus(:,i) = m;
                sds(:,i) = 1/r;%std(true_tun(:,[1:nTrials/nBlocks]+(i-1)*(nTrials/nBlocks)),[],2);
                H(i) = shadedErrorBar(true_Az, mus(:,i),sds(:,i),{'color',clrs(i,:)},1);
            end
        end
        axis tight;
        xlim([0 360]);set(gca,'XTick',[0:60:360]); 
        xlabel('position (^o)'); ylabel('amplitude (a.u.)'); 
        lg = 'H(1).mainLine';
        for lgs = 1:nBlocks-1
            lg = [lg,',H(',num2str(lgs+1),').mainLine'];
        end
        eval(['legend([',lg,'],conds)']);
        legend boxoff;
        % add lines at cages
        ht = plot([120 120],ylim,'--k'); uistack(ht,'bottom');
        ht = plot(2.*[120 120],ylim,'--k');uistack(ht,'bottom');

        % BOX PLOTS OF ACTIVITY IN POSITIONS OF INTEREST ON CAROUSEL    
        clear vals; subplot(2,5,[9 10]); hold on;
        if isempty(strfind(behavior.name{nV},'phase'))
            % global
            for i = 1:nBlocks
                tmp = true_tun(:,[1:nTrials/nBlocks]+(i-1)*(nTrials/nBlocks));
                vals{1,i} = tmp(:)';
            end

            % origin
            for i = 1:1:nBlocks
                tmp = true_tun([340:360 1:20],[1:nTrials/nBlocks]+(i-1)*(nTrials/nBlocks));
                vals{2,i} = tmp(:)';
            end 

            % cage1
            for i = 1:nBlocks
                tmp = true_tun([100:140],[1:nTrials/nBlocks]+(i-1)*(nTrials/nBlocks));
                vals{3,i} = tmp(:)';
            end 

            % cage2
            for i = 1:nBlocks
                tmp = true_tun([220:260],[1:nTrials/nBlocks]+(i-1)*(nTrials/nBlocks));
                vals{4,i} = tmp(:)';
            end 

            pos = bsxfun(@plus,repmat([1:nBlocks],4,1),repmat([0 5 10 15]',1,nBlocks));

            for p1 = 1:size(vals,1)
                for p2 = 1:size(vals,2)
                    %if std(vals{p1,p2}) == 0 % lets add some jitter to avoid jamming the violin
                        vals{p1,p2} = vals{p1,p2} + eps*randi(2,1,size(vals{p1,p2},2));
                    %end
                    try
                        Violin(vals{p1,p2},pos(p1,p2),'ViolinColor',clrs(p2,:));
                    catch
                        plot(mean(vals{p1,p2}),pos(p1,p2),'color',clrs(p2,:));
                    end
                end
            end
            lbls = {{'0-';'360^o'},{'340-';'20^o'},{'100-';'140^o'},{'220-';'260^o'}};
            lbls = {'all','roi1','roi2','roi3'};
            set(gca,'XTick',mean(pos'),'XTickLabel',lbls,'xticklabelrotation',45);
        else
            text(.5,.5,{'intentionally blank', 'circular variable'},'horizontalalignment','center');
            xlim([0 1]); ylim([0 1]);
        end
        % ADD SOME LABELS TO THE FIGURE
        sh = stampFig(fileBase);    
        text(0.01, 0.8,{['feature',num2str(nV),':'],behavior.name{nV}},'fontweight','normal','interpreter','none','fontsize',12);    
        txt{1} = 'conditions:';
        for l = 1:nBlocks
            txt{l+1} = ['block',num2str(l),': ', session.info.conditions{l} ];
        end
        text(0.01, 0.6,txt,'fontweight','normal','interpreter','none','fontsize',12);
        xlim([0 1]); ylim([0 1]); axis off;

        ForAllLabels('fontsize', 12);
        ForAllSubplots('set(gca,''TickDir'',''out'')');

        % SAVE THE FIG    
        print(gcf,[fullfile(getfullpath(fileBase)),'beh', behavior.name{nV},'.jpg'],'-djpeg');    
        close;  
        
        % simple display of loop number on same line   
        if nV > 1
            for j=0:log10(nV-1)
                fprintf('\b'); % delete previous counter display
            end
        end
        pause(0.5); fprintf('%d', nV);
    end 
    fprintf('saving session''s final data structure in behTrialMatrices.mat...\n');
    fprintf('\n\n\n');
    save('behTrialsMatrices.mat','A','-v7.3');
end


%% MAIN - PASSIVE TASK       
if taskType == 0
    for nV = 1:length(behavior.name)                
%% generate output data        
        x = bdata(:,nV);
        posCenters = session.helper.positionBinCenters;
        if strcmp('1:toR2:fromR3:toL4:fromL5:atO6:atR7:atL',session.helper.position_context.labels);
            ctx_lbl = {'toR','fromR','toL','fromL','atO','atR','atL'}; 
        else
            error('please fix ''session.helper.position_context.labels'' variable. You probably need to (re)run updateSession(fileBase) function...');
        end

        ctx = session.helper.position_context.context; % the 'contexts'
        per = session.helper.position_context.segs;    % the idxs of the 'contexts'
              
        if any(ctx == 0)
            A(nV).warning = 'there are epochs with zero context';                        
            if ~isempty(rejTrials)
                tt = session.events.TTL.atStart(max(rejTrials));% in lfp sampling rate
                fr = find(per(:,1)<tt & per(:,2)>tt) + 1;                
            else
                fr = 1;
            end
        end
        
        ctx(ctx == 0) = 8;% pool unknown ctxs into an 8th category
        
        edges_tr = [1 cumsum(trialsPerBlock)];% block edges in trial space                
        edges_ctx = find(diff(session.helper.position_context.segs')'./SR_LFP > 30);% block edges inctxs space
                
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
        
        
        % grab the relevant timespans of the behavioral activity (dims are
        % blocks, contexts and number of trials. Data could be stored as
        % cells in cells or as matrices in cells depending if they are
        % position or time resolved
        clear cnt tmpV tmpP tmp xax xxx;
        cnt = ones(nBlocks,8); 
        for i = 1:nBlocks
            for j = 1:length(unique(ctx_lbl))
                idx{i,j} = find(and(blks(:,3) == i , blks(:,4) == j));% indices of trials in each category
                for k = 1:length(idx{i,j})
                    tmpV{i,j}{cnt(i,j)} =        x(blks(idx{i,j}(k),1):blks(idx{i,j}(k),2),1); % behavioral activity in this chunk
                    tmpP{i,j}{cnt(i,j)} = posDiscr(blks(idx{i,j}(k),1):blks(idx{i,j}(k),2),1); % carousel position (as indices into position bin array) in this chunk
                    tmpT{i,j}{cnt(i,j)} = [blks(idx{i,j}(k),1),blks(idx{i,j}(k),2)];           % first and last time points of this chunk
                    if  j < 5  % these are trajectories so bin data by posiion 
                        % **BUT** note that position extents will be different between trials due to carousel stopping inertia or other inaccuracies (e.g. missed pulsed or similar)
                        if strfind(behavior.name{nV},'phase') % use circular instead of linear means for the phase variables
                            tmpV{i,j}{cnt(i,j)} = accumarray(tmpP{i,j}{cnt(i,j)},tmpV{i,j}{cnt(i,j)},[numel(posCenters)-1,1],@CircularMean_angle_only);
                        else
                            tmpV{i,j}{cnt(i,j)} = accumarray(tmpP{i,j}{cnt(i,j)},tmpV{i,j}{cnt(i,j)},[numel(posCenters)-1,1],@mean);
                        end
                    end
                    cnt(i,j) = cnt(i,j) + 1; % keep a count of the number of trials in each context + block cell
                end                
                
                % to and from Right, to and from Left
                if j < 5 
                    tmpV{i,j} = cell2mat(tmpV{i,j}); % we can do this because we are accumulating across the whole -360:0.5:360 = 721 bins...
                    % skip the following step & deal with trimming later
                    % idx_x = find(mean(tmpV{i,j},2) ~= 0); % this fails when the variable is sparse (e.g. nV = 24 - lick_events)
                    % tmpV{i,j} = tmpV{i,j}(idx_x,:);
                    xax{i,j} = posCenters;%(idx_x); 
                    xax_lbl{i,j} = 'position (^o)';
                end
                % atO
                if j == 5 % atOs, unsplit as of yet
                    Ls = [cellfun(@(x) length(x), tmpV{i,j}, 'UniformOutput',true)]; % lengths of each 'atO' period
                    mdn = mode(Ls); 
                    LsLong = find(Ls > SR_LFP*20);       
                    % does LsLong list match what we expect from blks variable? just a precautionary check
                    if any(blks(idx{i,j}(LsLong),5) ~= LsLong); warning('an edge trial might have been skipped for the atO intervals'); end
                    for l = 1:length(LsLong)                        
                        if idx{i,5}(LsLong(l)) == 1
                            % last seconds of the first atO
                            tmpV{i,j}{LsLong(l)} = tmpV{i,j}{l}(end-mdn:end);    
                        elseif idx{i,5}(LsLong(l)) == blk_lims(end,end)
                            % first secs of the last atO
                            tmpV{i,j}{LsLong(l)} = tmpV{i,j}{LsLong(l)}(1:mdn); 
                        else
                            % breaks in between blocks. First mdn secs assigned last atO of previous block while last secs are assigned to the first atO of current block
                            tmp = tmpV{i,j}{LsLong(l)};
                            tmpV{i,j}{LsLong(l)}               = tmp([end-mdn:end]); % the end   of this array should be the pretrial atO for the current trial
                            tmpV{i-1,j}{size(tmpV{i-1,j},2)+1} = tmp([1:mdn]);% the start of this array should be the atO of the last trial of the previous block
                            idx{i-1,j}(length(idx{i-1,j})+1) = idx{i,j}(LsLong(l)); % similarly, update the idx variable which holds the context ids that make up each context+block
                            clear tmp;
                        end
                    end
                    xax{i,j} = [];%[1:1:size(tmpV{i,j},1)]; % its just sampling rate interval so dont waste space
                end
                %
                if j > 5 % stationary at the targets
                    pxp = nan(max(cellfun(@(x) length(x), tmpV{i,j}, 'UniformOutput',true)),length(tmpV{i,j}));
                    for  m = 1:length(tmpV{i,j})
                        pxp(1:length(tmpV{i,j}{m}),m) = tmpV{i,j}{m};
                    end
                    tmpV{i,j} = pxp;
                    xax{i,j} = [];%[1:1:size(tmpV{i,j},1)]; % its just sampling rate interval so dont waste space
                    xax_lbl{i,j} = 'time (s)';
                end
            end
        end

        % split the atOs into: with/without cue and where next/previous
        % trial was/is (atO_fromL atO_fromR atO_toL atO_toR)
        for i = 1:nBlocks
            j=5; %atO only
            pxp = nan(max(cellfun(@(x) length(x), tmpV{i,j}, 'UniformOutput',true)),length(tmpV{i,j})); % time trajectories atO
            for  m = 1:length(tmpV{i,j})
                pxp(1:length(tmpV{i,j}{m}),m) = tmpV{i,j}{m};
            end
            % lets keep max of (90% of pxp, up to where all cols are non-nan)
            upto = max([ round(0.90*size(pxp,1)),find(sum(isnan(pxp),2) > 0,1,'first')]);
            pxp = pxp(1:upto,:);
            tmpV{i,j} = pxp;            
            cameFrom = idx{i,5}-1;     % indices of trials preceding the atO's period
            cameFrom(cameFrom<1) = []; % remove first trial ('came' from nowhere)
            cameFromL = cameFrom(find(ctx(cameFrom) == 4)); 
            cameFromR = cameFrom(find(ctx(cameFrom) == 2)); 
            if length(cameFromL) + length(cameFromR) < length(cameFrom) & isempty(rejTrials) % forgive missing trials if rejTrials is defined by user in spreadsheet
                error('unexpected trial sequence around origin please check'); 
            end
            goingTo = idx{i,5}+1;
            goingTo(end) = [];% remove last b/c its dealt with in next block    
            goingToL = goingTo(find(ctx(goingTo) == 3));
            goingToR = goingTo(find(ctx(goingTo) == 1));    
            if length(goingToL) + length(goingToR) < length(goingTo) & isempty(rejTrials) % forgive missing trials if rejTrials is defined by user in spreadsheet
                error('unexpected trial sequence around origin please check'); 
            end
            
            % extract the first or second halves of appropriate trajectories
            [a_,b_,c_] = intersect(idx{i,j}, (goingToR - 1));
            tempAtO{i,1} = tmpV{i,j}(ceil(end/2):end,b_); % at atO (going to R)
            tempAtOIdx{i,1} = a_; % ctx indices
            
            [a_,b_,c_] = intersect(idx{i,j}, (goingToL - 1));
            tempAtO{i,2} = tmpV{i,j}(ceil(end/2):end,b_); % at atO (going to L)
            tempAtOIdx{i,2} = a_; % ctx indices
            
            [a_,b_,c_] = intersect(idx{i,j}, (cameFromR + 1));
            tempAtO{i,3} = tmpV{i,j}(1:floor(end/2),b_ );  % at atO (came from R)
            tempAtOIdx{i,3} = a_; % ctx indices
            
            [a_,b_,c_] = intersect(idx{i,j}, (cameFromL + 1));
            tempAtO{i,4} = tmpV{i,j}(1:floor(end/2),b_ );  % at atO (came from L)
            tempAtOIdx{i,4} = a_; % ctx indices
            
            for kk = 1:4
                xax_atO{i,kk} = [];% redunant really...linspace(0,size(tempAtO{i,kk},1)/session.info.SR_LFP,size(tempAtO{i,kk},1));
            end
            xax_lbl_atO(i,1:4) = deal({'time (s)'});
        end

        % final arrangement of variables
        ctx_lbl = {'toR','fromR','atR','toL','fromL','atL','atO_whole','atO_goingToR','atO_goingToL','atO_cameFromR','atO_cameFromL'}';
        A(nV).varName   = behavior.name{nV};
        A(nV).rejTrials = rejTrials;
        A(nV).ctx_lbl   = ctx_lbl;
        A(nV).ctx_idx   = [idx(:,    [1:2,6,3,4,7,5]), tempAtOIdx];        
        A(nV).tun       = [tmpV(:,   [1:2,6,3,4,7,5]), tempAtO];
        A(nV).xax       = [xax(:,    [1:2,6,3,4,7,5]), xax_atO];
        A(nV).trialNum  = [idx(:,    [1:2,6,3,4,7,5]), tempAtOIdx];
        A(nV).xax_lbl   = [xax_lbl(:,[1:2,6,3,4,7,5]), xax_lbl_atO];                

        % break period activities
        endTrials = cumsum(trialsPerBlock);% at end of blocks...
        if length(endTrials) == 1; endTrials = 0; else endTrials(end) = []; end
        for i = 1:nBlocks + 1 % there should be nBlocks+1 breaks periods all up
            if i == 1 % first
                A(nV).breakPeriods(i,:) = [1,min([session.events.TTL.atStart(1,1), find(session.helper.idxMov, 1, 'first')])];
            elseif i == nBlocks + 1 % last
                A(nV).breakPeriods(i,:) = [round(session.events.TTL.all(end,1)./SR_F), length(position)];
            else % need to guard against possible delayed (post break atStart 2-pulse TTL)
                % last momvent tpoint at or before the atOrigin TTL
                t1 = find(idxMov(1:session.events.TTL.atStart(endTrials(i-1))) == 1,1,'last');
                t2 = find(idxMov(session.events.TTL.atStart(endTrials(i-1)):end) == 1,1,'first') + session.events.TTL.atStart(endTrials(i-1));
                A(nV).breakPeriods_t(i,:) = [t1,t2];
                A(nV).breakPeriods(i,:) = [per(blk_lims(i,1),1),per(blk_lims(i,1),2)];
            end
        end
        
        
%%       - cartesian 
        % trial and context resolved activity plots   
        figure('pos',[27         554        2533         513]); 
        clims = [nan nan];
        for i = 1:nBlocks
            %atO_lbl = {'atO_goingToR','atO_goingToL','atO_cameFromR','atO_cameFromL'};
            for j = 1:size(A(nV).tun,2)
                xxx = sub2ind([size(A(nV).tun,2),nBlocks],j,i);
                subplot(nBlocks,size(A(nV).tun,2),xxx);
                imagesc(A(nV).xax{i,j},[],A(nV).tun{i,j}');
                cax = caxis;
                clims(1) = min(clims(1),cax(1));
                clims(2) = max(clims(2),cax(2));
                title([ctx_lbl{j}],'interpreter','none'); % ,',  ','blk:',num2str(i)
                if j == 1; ylabel({['block ', num2str(i)];['trial (#)']}); end
                xlabel(A(nV).xax_lbl{i,j});
            end
        end

        % make me pretty
        h = stampFig(fileBase,[]);
        text(0.01, 0.8,{['feature',num2str(nV),':'],behavior.name{nV}},'fontweight','normal','interpreter','none','fontsize',12);    
        txt{1} = 'conditions:';
        for l = 1:nBlocks
            txt{l+1} = ['block',num2str(l),': ', session.info.conditions{l} ];
        end
        text(0.01, 0.6,txt,'fontweight','normal','interpreter','none','fontsize',12);
        xlim([0 1]); ylim([0 1]); axis off;

        ForAllLabels('fontsize', 12, 'fontweight','normal');
        ForAllSubplots('set(gca,''TickDir'',''out'')');
        hdl=get(gcf,'children'); equaliseClims(hdl);
        % SAVE THE FIG    
        print(gcf,[fullfile(getfullpath(fileBase)),'beh_', behavior.name{nV},'.jpg'],'-djpeg');
        close;
        
        
%%       - polar 
        figure('pos',[77 442 1059 587]);
        colormap('jet');
        % inject spacers between blocks for circular plots      
              
        
%% to targets 
    % toR
        z = find(strcmp(ctx_lbl,'toR'));
        %b1 = min(cellfun(@min, {A(nV).xax{1:nBlocks,z}}));
        %b2 = max(cellfun(@max, {A(nV).xax{1:nBlocks,z}}));
        b1 = find(posCenters+125<0,1,'last');
        b2 = find(posCenters+1<0,1,'last');
        [~,nTr] = cellfun(@size, {A(nV).tun{1:nBlocks,z}});
        sub_xax = posCenters(b1:b2);
        toR = nan(numel(sub_xax), sum(nTr) + (nBlocks-1)*brk);
        % populate this matrix (offsets based on location)
        fr = 1;
        for i = 1:nBlocks
            [Is1,Is2] = intersect(sub_xax, A(nV).xax{i,z});
            to = fr-1+size(A(nV).tun{i,z},2);
            toR(Is2,fr:to) = A(nV).tun{i,z}(b1:b2,:);  
            if i ~= nBlocks
                toR(:,to+1:to+1+brk) = nan;
                fr = to+2+brk;
            end
        end
        toR_xax = sub_xax;
        % is the trajectory contiguous?
        %         if unique(diff(find(~any(isnan(toR'))))) == 1% positions where all trials have data shd be 0 120 or so
        %             disp helo
        %             ii = ~any(isnan(toR'));
        %             toR = toR(ii,:);
        %             toR_xax = sub_xax(ii);
        %         end
    % toL
        z = find(strcmp(ctx_lbl,'toL'));
        % b1 = min(cellfun(@min, {A(nV).xax{1:nBlocks,z}}));
        % b2 = max(cellfun(@max, {A(nV).xax{1:nBlocks,z}})); 
        b1 = find(posCenters-1>0,1,'first');
        b2 = find(posCenters-125>0,1,'first');
        [~,nTr] = cellfun(@size, {A(nV).tun{1:nBlocks,z}});
        sub_xax = posCenters(b1:b2);
        toL = nan(numel(sub_xax), sum(nTr) + (nBlocks-1)*brk);
        % populate this matrix (offsets based on location)
        fr = 1;
        for i = 1:nBlocks
            [Is1,Is2] = intersect(sub_xax, A(nV).xax{i,z});
            to = fr-1+size(A(nV).tun{i,z},2);
            toL(Is2,fr:to) = A(nV).tun{i,z}(b1:b2,:);  
            if i ~= nBlocks
                toL(:,to+1:to+1+brk) = nan;
                fr = to+2+brk;
            end
        end
        toL_xax = sub_xax;
        % is the trajectory contiguous?
        %         if unique(diff(find(~any(isnan(toL'))))) == 1% positions where all trials have data shd be 0 120 or so
        %             ii = ~any(isnan(toL'));
        %             toL = toL(ii,:);
        %             toL_xax = sub_xax(ii);
        %         end        ]
        
        % join toR and toL
        bns = posCenters(posCenters >= 0);
        outwards = nan(length(bns),max([size(toL,2),size(toR,2)]));
        toR_xax = toR_xax + 360;
        fr = find(bns == min(toR_xax)); to = find(bns == max(toR_xax));
        outwards(fr:to,1:size(toR,2)) = toR;
        fr = find(bns == min(toL_xax)); to = find(bns == max(toL_xax));
        outwards(fr:to,1:size(toL,2)) = toL;

        % outwards = outwards;
        %         % lets find nonzero angles to trim...
        %         keep = find(sum(outwards, 2) ~= eps*size(outwards,2)); keep = [min(keep):max(keep)];
        %         outwards = outwards(keep,:);
        
        %         outwards(outwards == eps) = nan;
        %         ang = -posCenters(keep);
        ang = posCenters(361:end);
        %         ang(ang<0) = ang(ang<0) + 360;
        R = [1:size(outwards,2)] + nTrOfs;
%         iii = find(ang<120 | ang>240);
%         outwards = outwards(iii,:);        
%         ang = ang(iii);

        % subplot(nBlocks,5,[2 3 7 8]);
        subplot(1,2,1);
        [h,c_out] = polarCarouselPlot(R, ang, outwards,...
            'Nspokes', 3 ,...    
            'spokesPos', [0 120 240] ,...
            'Ncircles', 2,...
            'circlesPos',[R(1) R(end)],... 
            'RtickLabel',{'1^{st} trial', ['last trial']},... % ,num2str(nTrials)
            'colBar',1,...
            'colormap','jet',...
            'direction','outbound');
        view([0 -90]);
        axis tight; 
        if strfind(behavior.name{nV},'phase')
           CircColormap;
        end        
        clmp=colormap;%(gca);
        clmp = [.6 .6 .6 ;clmp];
        colormap(gca,clmp);
        clmp_1 = clmp;
        ps = get(gca,'position');
        c_out.Position = [1*c_out.Position(1) c_out.Position(2) 0.7*c_out.Position(3) 0.1*c_out.Position(4)];
        set(gca,'Position', ps);
        text(0,0,'outbound','horizontalalignment','center');
        
%% from targets 
    % fromR
        z = find(strcmp(ctx_lbl,'fromR'));
        %b1 = min(cellfun(@min, {A(nV).xax{1:nBlocks,z}}));
        %b2 = max(cellfun(@max, {A(nV).xax{1:nBlocks,z}}));
        b1 = find(posCenters + 125 <0,1,'last');
        b2 = find(posCenters + 1   <0,1,'last');
        [~,nTr] = cellfun(@size, {A(nV).tun{1:nBlocks,z}});
        sub_xax = posCenters(b1:b2);
        fromR = nan(numel(sub_xax), sum(nTr) + (nBlocks-1)*brk);
        % populate this matrix (offsets based on location)
        fr = 1;
        for i = 1:nBlocks
            [Is1,Is2] = intersect(sub_xax, A(nV).xax{i,z});
            to = fr-1+size(A(nV).tun{i,z},2);
            fromR(Is2,fr:to) = A(nV).tun{i,z}(b1:b2,:);  
            if i ~= nBlocks
                fromR(:,to+1:to+1+brk) = nan;
                fr = to+2+brk;
            end
        end
        fromR_xax = sub_xax;
        % is the trajectory contiguous?
        %         if unique(diff(find(~any(isnan(toR'))))) == 1% positions where all trials have data shd be 0 120 or so
        %             disp helo
        %             ii = ~any(isnan(toR'));
        %             toR = toR(ii,:);
        %             toR_xax = sub_xax(ii);
        %         end
    % fromL
        z = find(strcmp(ctx_lbl,'fromL'));
        % b1 = min(cellfun(@min, {A(nV).xax{1:nBlocks,z}}));
        % b2 = max(cellfun(@max, {A(nV).xax{1:nBlocks,z}})); 
        b1 = find(posCenters-1>0,1,'first');
        b2 = find(posCenters-125>0,1,'first');
        [~,nTr] = cellfun(@size, {A(nV).tun{1:nBlocks,z}});
        sub_xax = posCenters(b1:b2);
        fromL = nan(numel(sub_xax), sum(nTr) + (nBlocks-1)*brk);
        % populate this matrix (offsets based on location)
        fr = 1;
        for i = 1:nBlocks
            [Is1,Is2] = intersect(sub_xax, A(nV).xax{i,z});
            to = fr-1+size(A(nV).tun{i,z},2);
            fromL(Is2,fr:to) = A(nV).tun{i,z}(b1:b2,:);  
            if i ~= nBlocks
                fromL(:,to+1:to+1+brk) = nan;
                fr = to+2+brk;
            end
        end
        fromL_xax = sub_xax;
        % is the trajectory contiguous?
        %         if unique(diff(find(~any(isnan(toL'))))) == 1% positions where all trials have data shd be 0 120 or so
        %             ii = ~any(isnan(toL'));
        %             toL = toL(ii,:);
        %             toL_xax = sub_xax(ii);
        %         end        ]
        
        % join fromR and fromL
        bns = posCenters(posCenters >= 0);
        inwards = nan(length(bns),max([size(fromL,2),size(fromR,2)]));
        fromR_xax = fromR_xax + 360;
        fr = find(bns == min(fromR_xax)); to = find(bns == max(fromR_xax));
        inwards(fr:to,1:size(fromR,2)) = fromR;
        fr = find(bns == min(fromL_xax)); to = find(bns == max(fromL_xax));
        inwards(fr:to,1:size(fromL,2)) = fromL;

        % inwards = inwards;
        %         % lets find nonzero angles to trim...
        %         keep = find(sum(outwards, 2) ~= eps*size(outwards,2)); keep = [min(keep):max(keep)];
        %         outwards = outwards(keep,:);
        
        %         outwards(outwards == eps) = nan;
        %         ang = -posCenters(keep);
        ang = posCenters(361:end);
        %         ang(ang<0) = ang(ang<0) + 360;
        R = [1:size(inwards,2)] + nTrOfs;
%         iii = find(ang<120 | ang>240);
%         inwards = inwards(iii,:);
%         ang = ang(iii);
        
        % subplot(nBlocks,5,[2 3 7 8]);
        subplot(1,2,2);
        [h,c_out] = polarCarouselPlot(R, ang, inwards,...
            'Nspokes', 3 ,...    
            'spokesPos', [0 120 240] ,...
            'Ncircles', 2,...
            'circlesPos',[R(1) R(end)],... 
            'RtickLabel',{'1^{st} trial', ['last trial']},... % ,num2str(nTrials)
            'colBar',1,...
            'colormap','jet',...
            'direction','inbound');
        view([0 -90]);
        axis tight; 
        if strfind(behavior.name{nV},'phase')
           CircColormap;
        end        
        %clmp=colormap(gca);
        %clmp = [.5 .5 .5 ;clmp];
        colormap(gca,clmp_1);
        ps = get(gca,'position');
        c_out.Position = [1*c_out.Position(1) c_out.Position(2) 0.7*c_out.Position(3) 0.1*c_out.Position(4)];
        set(gca,'Position', ps);
        text(0,0,'inbound','horizontalalignment','center');

        % make me pretty
        h = stampFig(fileBase,[]);
        text(0.01, 0.8,{['feature',num2str(nV),':'],behavior.name{nV}},'fontweight','normal','interpreter','none','fontsize',12);    
        txt{1} = 'conditions:';
        for l = 1:nBlocks
            txt{l+1} = ['block',num2str(l),': ', session.info.conditions{l} ];
        end
        text(0.01, 0.6,txt,'fontweight','normal','interpreter','none','fontsize',12);
        xlim([0 1]); ylim([0 1]); axis off;
        ForAllLabels('fontsize', 12, 'fontweight','normal');
        ForAllSubplots('set(gca,''TickDir'',''out'')');
        
        % SAVE THE FIG    
        print(gcf,[fullfile(getfullpath(fileBase)),'beh_circ_', behavior.name{nV},'.jpg'],'-djpeg');
        close;   
        
        % simple display of loop number on same line   
        if nV > 1
            for j=0:log10(nV-1)
                fprintf('\b'); % delete previous counter display
            end
        end
        pause(0.5); fprintf('%d', nV);
    end    
    fprintf('saving session''s final data structure in behTrialMatrices.mat...\n');
    fprintf('\n\n\n');
    save('behTrialsMatrices.mat','A','-v7.3');
end




%{

%% DESCRIPTION OF THEOUTPUT STRUCTURE CALLED 'A'



%%%%%%%%%%%%%%%%%%%
% CONTINUOUS CASE %
%%%%%%%%%%%%%%%%%%%

+++A.ctx_lbl: there are no meaningful contexts in the continuous case. Just a
statement - 'position-resolved activity as a function of trial number separated in blocks' 

+++A.varName: the names of the behavioral variables e.g. A(1).varName = 'theta_raw_phase'

+++A.trialNum: A cell array tha gives the trial number for this particular
block e.g. A(3).trialNum{1,2} gives the trial numbers associated with the
third behavioral variable for the second block of this experimental session  

+++A.tun: spatial tuning of behavioral variable e.g. A(4).tun(1,2) is the
tuning of the fourth behavioral variable during the second block. Its
dimensions will be 360 spatial bins by number of trials  

+++A.traj: behavioral activity as a function of time (NOT position) for the relevant block

+++A.pos:  corresponding positions to A.traj

+++A.traj_time: corresponding  start and stop times for the above traj

+++A.xax: only valid for spatial variables, NOT for time variables. Dimensions
will be 1 x 360, ranging from 0 360 degrees in a cell whose dimension will
be 1 x n_of_blocks

+++A.xax_lbl: the corresponding label to A.xax

+++A.breakPeriods: the start and stop indices into the behavioral array for
the breaks between blocks. E.g. if two blocks, there will be three breaks
which means a 3 x 2 matrix 


%%%%%%%%%%%%%%%%%%%
% CONTROLLED CASE %
%%%%%%%%%%%%%%%%%%%

+++A.rejTrials: trials that may need to be ignored due to problems of any kind

+++A.varName: variable names

+++A.ctx_lbl: contextual labels that can distinguish same positions on carousel
under different behaviorally relevant contextual conditions. E.g. toR and
fromR are same (but reversed) spatial trajectories, that define if the
interval of interest is one that leads to the right cage target or comes
from the right cage target

+++A.tun:behavioral tuning as a function of position or time depending on the
context type. E.g. A(1).tun{2,5} is the tuning of fromL contexts
trajectories for the second block of trials. Or another example is 
A(2).tun{1,6} is the behavioral activity of the second variable for the
first block of trials for the 6th contextual type which is A(2).ctx_lbl{6}
= atL. Since the carousel is stopped at the left cage then the data here is
in the time domain not the positional domain with dimensions timepoints x
number of trials. 



%}






























































