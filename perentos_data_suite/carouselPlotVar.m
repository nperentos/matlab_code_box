function h = carouselPlotVar(fileBase,varargin)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% h = carouselPlotVar plots behavioral variables of choice (or defaults to
% a subset of main ones as a function of position for periods of movement
% only. Plots can be circular or linear. 
% If blocks of trials are discovered through the session information then
% the plots will be split according to the trial blocks
% The function is primarily intended as a visualiser and its output
% is the figures.
% INPUTS:   fileBase (folder inside which the processed subfolder is found
%           varargin: circular (1 for circular plots(default), 0 for linear
%                     varList: cell array with behavioral variable names to
%                     plot. If they do not exist empty figures are create
%                     instead. e.g varList = {''}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% PRE
    options = {'circular',1,'varList',};
    options = inputparser(varargin,options);
    ROI = [];
    lastsize = 0;
    pr_pth = fullfile(getfullpath(fileBase));
    
    if ~isempty(options.session_pth)
        fullPath = getFullPath(fileBase,options.session_pth); % path to session
    else
        fullPath = getFullPath(fileBase); % path to session
    end









%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% plot a carousel behavioral variable for visual inspection
% relies on the presence of peripheralsPP.mat
% INPUTS:
% fileBase
% varList: a subset of the following in a cell array
% ('tScale','runSpeed','carouselSpeed','posDiscr','wholeROI','whiskerROI',
%  'snoutROI','tongueROI', 'earROI', 'eyeROI', 'pupilDiam', 'pupilX', 
%  'pupilY', 'licking', 'respRate', 'idxMov', 'idxTrials')
% withmanipulation: set to 0 if all trials are the same and 1 if first half
% is of one kind and second half of another (e.g. baseline first, followed
% by manipulation such as female exposure
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

figure;colororder = get(gca,'colororder');close;

if nargin <3; withmanipulation = 1; end
% first check that peripheralsPP.mat and varList exist
pppNames = {'tScale', 'runSpeed', 'carouselSpeed', 'posDiscr', 'wholeROI', 'whiskerROI'...
    'snoutROI', 'tongueROI', 'earROI', 'eyeROI', 'pupilDiam', 'pupilX', 'pupilY' ...
    'licking', 'respRate', 'idxMov', 'idxTrials'};  
if sum(~cellfun(@isempty,regexp(pppNames,strjoin({varList},'|'))))>0 % request variable likely exists
    try
        load(fullfile(getfullpath(fileBase),'peripheralsPP.mat'));
    catch
        disp('peripheralsPP is missing');
        disp('will try to generate');
        peripheralsPP(fileBase);
        load(fullfile(getfullpath(fileBase),'peripheralsPP.mat'));
    end
end

vars = ~cellfun(@isempty,regexp(pppNames,strjoin({varList},'|')));
vars = find(vars);

idxMov = find(ppp(find(strcmp(pppNames,'idxMov')==1),:) == 1);
x = find(strcmp(pppNames,'posDiscr')==1);

trials = find(strcmp(pppNames,'idxTrials')==1);
mov    = find(strcmp(pppNames,'idxMov')==1);
nTr = length(unique(ppp(trials,:)))-1;


%% 'polar' plottype (any variable as a function of position)  
for i = 1:length(vars)
% plot first and second halves as two polar plots with error bars on same axis
%figure('pos',[200 645 1521 1109]);  
figure('pos',[67 1 792 821]);

%% trial resolved trajectories
for pl = 1:2
        if pl == 1; subplot(2,2,1,polaraxes); else subplot(2,2,2); end
        % different tones for each trial and different color for each set
        % by default there should be two sets only per recording
        %colorMap1 = [0.*ones(round(nTr),1), linspace(0.5,1,round(nTr))' 1.*ones(round(nTr),1)];
        colorMap1 = [0.*ones(round(nTr),1), linspace(0,1,round(nTr))', linspace(0,1,round(nTr))'];
        %colorMap2 = [1.*ones(round(nTr),1), 0.*ones(round(nTr),1), linspace(0.5,1,round(nTr))' ];         
        colorMap2 = [linspace(0,1,round(nTr))',0.*ones(round(nTr),1), linspace(0,1,round(nTr))'];
        colorMap = colorMap1;
        %lets try this manually first
        for j = 1:nTr
            idx = find(ppp(trials,:) == j & ppp(mov,:) == 1); % indices of trial i 
            tun = accumarray(ppp(x,idx)',ppp(vars(i),idx),[numel(posEdges)-1,1],@mean);
            tun = [tun' tun(1)]; 
            
            if j >=round(nTr/2)+1 & withmanipulation; colorMap = colorMap2; end
            if pl == 1
                polarplot([binCenters binCenters(1)],tun,'color',[colorMap(j,:) 0.5],'linewidth',0.8);
            end
            if pl == 2
                plot([binCenters(1), binCenters]*360/(2*pi),tun-mean(tun),'color',[colorMap(j,:) 0.5],'linewidth',0.8);
                axis tight; box off;
            end                
            hold on;
        end
end

%% trial block averages (usually n of 30 or 40)
    for blk = 1:2
        if blk == 1; colorMap = colorMap1; idx = find(ppp(trials,:) <  nTr/2 & ppp(mov,:) == 1); end% indices of first block of trials  
        if blk == 2; colorMap = colorMap2; idx = find(ppp(trials,:) >= nTr/2 & ppp(mov,:) == 1); end
        tun = accumarray(ppp(x,idx)',ppp(vars(i),idx),[numel(posEdges)-1,1],@median); 
        tun = [tun' tun(1)];       
        tunSD = accumarray(ppp(x,idx)',ppp(vars(i),idx),[numel(posEdges)-1,1],@std);        
        tunSD = [tunSD' tunSD(1)]./sqrt(nTr/2-1); 
        if blk == 1; ax = subplot(2,2,3,polaraxes);  end%ax = subplot(2,2,2,polaraxes); hold on;        
        hold on;polarwitherrorbar(ax, [binCenters binCenters(1)],tun,tunSD,colorMap(end/2,:));hold on;%colororder(blk,:)
        subplot(2,2,4); hold on; %ax = subplot(2,2,2,polaraxes); hold on;        
        shadedErrorBar([binCenters]*360/(2*pi),tun(1:end-1),tunSD(1:end-1),{'color',colorMap(end/2,:)},1);%colororder(blk,:)
        axis tight; box off;
        %waitforbuttonpress
    end
    gcf;
    axes('position',[0 0 1 1]);
    text(0.5,0.95,['position resolved ',varList],'horizontalalignment','center','fontsize',20);xlim([0 1]);ylim([0 1]);axis off;
    text(0.35,0.5,'baseline trials','horizontalalignment','center','fontsize',12,'color',colorMap1(end/2,:)); xlim([0 1]);ylim([0 1]);axis off;
    text(0.6,0.5,'valenced trials','horizontalalignment','center','fontsize',12,'color',colorMap2(end/2,:));xlim([0 1]);ylim([0 1]);axis off;
    print(fullfile(getfullpath(fileBase),[varList,'_plt']),'-djpeg','-r300');
end
