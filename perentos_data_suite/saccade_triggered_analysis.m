function out = saccade_triggered_analysis(fileBase)
%% out = saccade_triggered_analysis(fileBase) does a triggered analysis 
% around saccade timepoints. Currently, variables being considered are:
% position on carousel
%

% PRE
    try
        goto(fileBase);
    catch
        error('the fileBase you defined doesnt exist');
    end
    figure('pos',[10 10 1000 1200]); 
    index = vc(reshape(1:12, 3, 4)'); % 3 for X, Y or all saccades. 4 for the variables being considered
    
% LOAD BEHAVIORAL DATA AND GET SACCADES
    [session, behavior] = loadSession(fileBase);
    beh = behavior.data.data; 
    sac = beh(:,[end-1:end]);
    [i_sac{1},~] = find(sac(:,1) == 1); % X only
    [i_sac{2},~] = find(sac(:,2) == 1); % Y only
    [i_sac{3},~] = find(sac == 1); % both saccades
    
    
    xx = zeros(1,max(i_sac{1}));xx([i_sac{1}]) = 1;
    yy = zeros(1,max(i_sac{2}));yy([i_sac{2}]) = 1;

% DISTRIBUTION OF SACCADES ON 
    ipos = find(strcmp(behavior.name,'position'));
    sac_pos = beh(ix,ipos);
    histogram(sac_pos,100);


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