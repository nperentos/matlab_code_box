function out = PFStability(fileBase,varargin)
% place cell stability quantified using NMF fields and the coefficient of
% variation. At present it uses smooth firing rates (tun.tuningSm)
% INPUT: fileBase: but relies on the presence of fileBase.tun.mat
%        clu_idx:  clusters subset      (optional)
%        trs:      trial IDS to include (optional)
%        verbose:  to plot or not       (optional)
% OUTPUT: ?

options = {'clu_idx',[],'trs',[],'verbose',0};
options = inputparser(varargin,options);


nComp = 4;
cluType = {'MUA','SU'};

%fileBase = 'NP46_2019-12-02_18-47-02';
cd(getfullpath(fileBase));
disp('loading data');
load([fileBase,'.tun.mat']);
nBins = size(tun(1).tuningSm,1);

[session, behavior] = loadSession(fileBase);
if strcmp(session.info.taskType, 'continuous')
    trs = 1:size([tun(1).tuningSm],2) - 1; % exclude the last trial as it always looks empty - but why?!!
elseif strcmp(session.info.taskType, 'controlled')
    trs = 1:size([tun(1).tuningSm],2); %
elseif strcmp(session.info.taskType == 'cued')
    error('cued direction (which is a continuous -type protocol) not implemented yet');
end

if isempty(options.clu_idx) 
    clu_idx = [tun(:).cids]; % process all cells
else
    clu_idx = options.clu_idx;
end
if ~isempty(options.trs) 
    trs = options.trs;
end

if options.verbose
    figure('pos',[10 10 1000 500]); 
end



%% MAIN
for i = 1:length(clu_idx)
% get the data    
    j = find([tun(:).cids] == clu_idx(i));
    r = tun(j).tuningSm(:,trs); % remove last trial why?

% compute the NNMF    
    opt = statset('MaxIter',100,'Display','off');
    if any(isnan(r(:))); r(isnan(r)) = eps; end;
    [W,H] = nnmf((r),nComp,'options',opt);
    [~,I] = sort(max(W),'descend');
    W = W(:,I);
    Wn = W./max(W(:)); % normalised weights

% find a peak in the first component
    [pk,idx,wdth] = findpeaks(Wn(:,1),'minpeakheight',0.5);
    if length(pk) > 1 % keep only biggest
        [pk loc] = max(pk);
        idx  = idx(loc);
        wdth = wdth(loc);
    end

% take the data inside this position slice for all trials
    dtmp = r(max([1,idx-round(wdth/2)]):min([nBins,idx+round(wdth/2)]),:);
    dtmp = mean(dtmp,1);


% detect change point based on component activations (chpnt along trials)
    [a,b] = findchangepts(dtmp,'Statistic','linear');


% validate changepoint
    if a == 0 | isempty(a)
        display('perfect fit?');
    else
        % validate the change point with an unpaired ttest
        mu1 = median(dtmp(1:a-1));
        mu2 = median(dtmp(a:end));
        gr = [zeros(1,length(dtmp(1:a-1))),ones(1,length(dtmp(a:end)))];
        % ttest
        [~,P,o,df] = ttest2(dtmp(1:a-1),dtmp(a:end));        
    end

% coefficient of variation    
    coefVar = std(dtmp)/mean(dtmp);

% spit out the result for this cell   
    if options.verbose
        disp([' ']);
        disp(['******cell# ',int2str(tun(j).cids),'******']);
        disp(['CV= ', num2str(coefVar)]);
        %display(['chgpnt signif.= ', num2str(P)]);
        disp(['chgpnt location= ', int2str(a-1),', P=',num2str(P)]);
        disp(['**********************']);
        disp([' ']);
    end


%% PLOTS    
    if options.verbose
        clf;
        subplot(331);imagesc(r'); 
            xlabel('trial #'); ylabel('position');
        subplot(332);plot(Wn,'linewidth',2); % W(:,I)./norm(W,2) the norm        
            xlabel('position'); ylabel('normalised activity'); 
            if to == 4; xlim([min(tun(i,cx).locs2Keep) max(tun(i,cx).locs2Keep)]); end
        subplot(333); imagesc(H);
            xlabel('trial #'); ylabel('component');
        subplot(334); plot(dtmp); hold on;        
        plot(a,dtmp(a),'or','markersize',6,'markerfacecolor','r');
            xlabel('trial #'); ylabel('in-field 1st comp. activ.');
        subplot(335);
        boxplot(dtmp,gr);
            xlabel('before-after changepoint'); ylabel('in-field 1st comp. activ.');

            set(all_subplots(gcf),'Xlimspec','tight','Ylimspec','tight','fontsize',10)
        axes('pos',[0 0 1 1]); 
        txt = {['cell# = ' int2str(clu_idx(i)), '  ',cluType{tun(j).cellType}];
               ['chgpnt location= ', int2str(a-1),', P=',num2str(P)];
               ['coef. of variation= ', num2str(coefVar)]};
        text(0.4,0.3,txt); axis off; 
        drawnow; pause(0.5);           
    end

%% STORE VARIABLES IN THE OUTPUT STRUCTURE
    out(i).cids = clu_idx(i);
    out(i).nmfW = W;
    out(i).nmfH = H;
    out(i).mainFieldActivity = dtmp;
    out(i).chPnt = a;
    out(i).chPnt_pval = P;
    out(i).coefVar = coefVar;
    % sort according to cids
end    
    [~,I] = sort([out(:).cids]); % [~,I] = sort([out.cids]);
    out = out(I);
    out(1).trials = trs;
    out(1).note = {'trs:trials included in this analysis';
                    'mainFieldActivity: NMF 1st component activity within the field '};
    