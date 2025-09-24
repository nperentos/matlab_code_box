function cell = regressBehaviorOntoPlaceField(fileBase,varargin)

% regressBehaviorOntoPlaceField regresses behavioral variables onto place
% field activities as a function of trials. This is meant to generate a
% first overview of linear relationships between behavioral variables such
% as pupil size, speed, whisker pad etc. It uses the behavioral design matrix 
% and the tun structure.


%% PREREQUISITES
    options = {'trials',[],'pth',[],'verbose',1};
    options = inputparser(varargin,options);

    if ~isempty(options.pth)
        processedPath = getfullpath(fileBase,options.pth);
    else
        processedPath = getfullpath(fileBase);
    end

% bring in peripherals and spikes
    cd(processedPath)
    disp 'loading peripherals and tuning curves ...'; 
    if exist(fullfile(pwd,'peripheralsPP.mat')) & exist(fullfile(pwd,[fileBase,'.tun1.mat']))
        load('peripheralsPP.mat'); 
        load([fileBase,'.tun1.mat']); tun = tun1; clear tun1;
        % some essential variables
        idxMov = carouselGetVar(fileBase,{'idxMov'},ppp,pppNames); %3degree bins...
        pos = carouselGetVar(fileBase,{'posDiscr'},ppp,pppNames); %3degree bins...
        trialI = carouselGetVar(fileBase,{'idxTrials'},ppp,pppNames); %3degree bins...
        if isempty(options.trials)
            trials = unique(trialI);
            trials([1,end]) = []; % remove the first elements not a trial and the last which seems to be predominantly empty across sessions - this hasnt been fully confirmed yet
        end
    else
        error('the design matrix does not exist. Please check (peripheralsPP.mat???)')
    end

%% REGRESS
% cycle through behavioral variables
% cycle trough behavioral variables    
    for j = 1:4%length(tun.cids)  
        display(['cell: ',num2str(j),'/',num2str(length(tun.cids))]);
    % neural activity in specified cell and position extent
        nmfComp = sq(tun.PFStability(1).nmfW(j,:,:)); %zNmfComp = zscore(nmfComp);
        [~, pk] = max(nmfComp(:,1));
        extents = [pk-10:pk+10]; % automate the boundaries of the field!
        extents(extents<1 | extents> length(tun.locEdges)-1) = [];
        neur = sq(tun.tuningSm(j,extents,trials));
        
        % three different ways to summarise the activity of the field
        muNeur = mean(neur,1);
        mxNeur = max(neur,[],1);
        sdNeur = std(neur);
        
        % package the data
        cell(j).extents      = extents;
        cell(j).neural.mu    = muNeur;
        cell(j).neural.stdev = sdNeur;  
        cell(j).neural.mx    = mxNeur;
        
        cnt = 0;
        for i = 1:length(pppNames) 
            ignore = IgnoreVar(pppNames(i));
            if ignore; continue; end;
            var = carouselGetVar(fileBase,pppNames(i),ppp,pppNames);
            cnt = cnt + 1;

        % behavior variable activity in specified cell and position extent
            sz = zeros(1,length(trials));        
            muBeh = zeros(1,length(trials));
            sdBeh = zeros(1,length(trials));
            mxBeh = zeros(1,length(trials));
            for k = 1:length(trials)
%                 tic;idx = intersect(find(trialI == trials(k)), find(idxMov == 1));
%                 tmpBins = find(pos >= extents(1) & pos <= extents(end));
%                 idx = intersect(idx, tmpBins); toc % the indices of trial k spent inside the spatial position around spatial position 41
%                 
                idx = trialI == trials(k) & idxMov == 1 & pos >= extents(1) & pos <= extents(end);
                
                beh = var(idx);
                sz(1,k) = length(beh);
                muBeh(1,k) = mean(beh);
                sdBeh(1,k) = std(beh);
                mxBeh(1,k) = max(beh);
            end
            
        % resort neural space by the magnitude of the behavioral variable
            [~,I1] = sort(muBeh);
            [~,I2] = sort(sdBeh);
            [~,I3] = sort(mxBeh);
    
        % package the data
            cell(j).behavior(cnt).mu          = muBeh;
            cell(j).behavior(cnt).stdev       = sdBeh;
            cell(j).behavior(cnt).mx          = mxBeh;            

            cell(j).behavior(cnt).muI  = I1;
            cell(j).behavior(cnt).stdevI      = I2;
            cell(j).behavior(cnt).mxI         = I3;

            cell(j).behavior(cnt).nPoints     = sz; % can this be used as a regressor?
            cell(j).behavior(cnt).varName     = pppNames{i}; % can this be used as a regressor?
        end            
    end
    save([fileBase,'.regr.mat'],'cell');
    
    % plots
%     if options.verbose
%         generatePlots;
%     end
end

%% SKIP IRRELEVANT PERIPHERAL DATA STREAMS
function ign = IgnoreVar(varIn)
    varNot = {'tScale'    'posDiscr'    'carouselSpeed'  'idxMov'    'idxTrials'};
    ign = 0;
    for l = 1:length(varNot)
        if strcmp(varNot{l},varIn)
            ign = 1;
            break;
        end
    end
end

function generatePlots
    % a plot for each cluster
    close all;
    nr = length(cell(1).behavior) + 1;
    for p = 1:4%1length(tun.cids)
        figure('pos',[ 2         948        2558         385]);
        subplot(2,nr,[1]); 
        %imagesc(sq(tun.tuning(p,:,trials))'); 
        imagesc(sq(tun.tuning(p,cell(p).extents,trials))'); 
        subplot(2,nr,[nr+1]);
        imagesc(sq(tun.tuning(p,:,trials))'); 
        for r = 1:length(cell(1).behavior)
            o = sub2ind([nr,2],r,1)+1; subplot(2,nr,o);
            imagesc(sq(tun.tuning(p,cell(p).extents,cell(p).behavior(r).mxI))'); 
            o = sub2ind([nr,2],r,2)+1; subplot(2,nr,o);
            %scatter(cell(p).behavior(r).mx,cell(p).neural.mx); axis tight;
            LM = fitlm(cell(p).behavior(r).mx,cell(p).neural.mx);
            hold on; plot(LM,'marker','.'); legend off;axis tight;
            title(cell(p).behavior(r).varName);
        end
    end
end    
%% REGRESS untested backup faster but more convoluted
%{
% cycle through behavioral variables
    cnt = 0;
    for i = 1:length(pppNames) 
        tic;
        ignore = IgnoreVar(pppNames(i));
        if ignore; continue; end;
        var = carouselGetVar(fileBase,pppNames(i),ppp,pppNames);
        cnt = cnt + 1;
        display(['regressor: ',num2str(i),'/',num2str(length(pppNames))]);
        for j = 1:5%length(tun.cids)            
        % neural activity in specified cell and position extent
            nmfComp = sq(tun.PFStability(1).nmfW(j,:,:)); %zNmfComp = zscore(nmfComp);
            [~, pk] = max(nmfComp(:,1));
            extents = [pk-10:pk+10]; % automate the boundaries of the field!
            extents(extents<1 | extents> length(tun.locEdges)-1) = [];
            neur = sq(tun.tuningSm(j,extents,trials));
            % three different ways to summarise the activity of the field
            muNeur = mean(neur,1);
            mxNeur = max(neur,[],1);
            sdNeur = std(neur);
            
        % behavior variable activity in specified cell and position extent
            for k = 1:length(trials)
                idx = intersect(find(trialI == trials(k)), find(idxMov == 1));
                tmpBins = find(pos >= extents(1) & pos <= extents(end));
                idx = intersect(idx, tmpBins); % the indices of trial 1 spent inside the spatial position around spatial position 41
                beh{k} = var(idx);
                sz(k) = length(beh{k});
                muBeh(k) = mean(beh{k});
                sdBeh(k) = std(beh{k});
                mxBeh(k) = max(beh{k});
            end
            
        % re-sort neural space by the magnitude of the behavioral variable
            [~,I1] = sort(muBeh);
            [~,I2] = sort(sdBeh);
f            [~,I3] = sort(mxBeh);
            
        % package the data 
            regressor(cnt).cell(j).average.neural      = muNeur;
            regressor(cnt).cell(j).stdev.neural        = sdNeur;  
            regressor(cnt).cell(j).maximum.neural      = mxNeur;
            
            regressor(cnt).cell(j).average.behavior    = muBeh;
            regressor(cnt).cell(j).stdev.behavior      = sdBeh;
            regressor(cnt).cell(j).maximum.behavior    = mxBeh;            
            
            regressor(cnt).cell(j).average.behSorting  = I1;
            regressor(cnt).cell(j).stdev.behSorting    = I2;
            regressor(cnt).cell(j).maximum.behSorting  = I3;
            
            regressor(cnt).cell(j).nPoints             = sz; % can this be used as a regressor?
            
        end 
        regressor(cnt).BehVarName = pppNames{i};
        toc;
    end

%}

%{ 
% cycle trough behavioral variables    
    for j = 1:length(tun.cids)        
    % neural activity in specified cell and position extent
        nmfComp = sq(tun.PFStability(1).nmfW(j,:,:)); %zNmfComp = zscore(nmfComp);
        [~, pk] = max(nmfComp(:,1));
        extents = [pk-10:pk+10]; % automate the boundaries of the field!
        extents(extents<1 | extents> length(tun.locEdges)-1) = [];
        neur = sq(tun.tuningSm(j,extents,trials));
        % three different ways to summarise the activity of the field
        muNeur = mean(neur,1);
        mxNeur = max(neur,[],1);
        sdNeur = std(neur);
        
        % package the data 
        cell(j).average.neural    = muNeur;
        cell(j).stdev.neural      = sdNeur;  
        cell(j).maximum.neural    = mxNeur;
        
        cnt = 0;
        for i = 1:length(pppNames)        
            ignore = IgnoreVar(pppNames(i));
            if ignore; continue; end;
            display('processing ');
            var = carouselGetVar(fileBase,pppNames(i),ppp,pppNames);
            cnt = cnt + 1;

        % behavior variable activity in specified cell and position extent
            for k = 1:length(trials)
                idx = intersect(find(trialI == trials(k)), find(idxMov == 1));
                tmpBins = find(pos >= extents(1) & pos <= extents(end));
                idx = intersect(idx, tmpBins); % the indices of trial 1 spent inside the spatial position around spatial position 41
                beh{k} = var(idx);
                sz(k) = length(beh{k});
                muBeh(k) = mean(beh{k});
                sdBeh(k) = std(beh{k});
                mxBeh(k) = max(beh{k});
            end

        % resort neural space by the magnitude of the behavioral variable
            [~,I1] = sort(muBeh);
            [~,I2] = sort(sdBeh);
            [~,I3] = sort(mxBeh);

        % package the data
            cell(j).regressor(cnt).average.behavior    = muBeh;
            cell(j).regressor(cnt).stdev.behavior      = sdBeh;
            cell(j).regressor(cnt).maximum.behavior    = mxBeh;            

            cell(j).regressor(cnt).average.behSorting  = I1;
            cell(j).regressor(cnt).stdev.behSorting    = I2;
            cell(j).regressor(cnt).maximum.behSorting  = I3;

            cell(j).regressor(cnt).nPoints             = sz; % can this be used as a regressor?
            cell(j).regressor(cnt).varName                                    = sz; % can this be used as a regressor?

        end            
    end
    %}
