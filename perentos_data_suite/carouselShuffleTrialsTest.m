function [pvalue] = carouselShuffleTrialsTest(fileBase,nPerm)


% shuffle trials across all first two blocks irrespective of condition.
% Repeat the test statistic of interest to form the null distribution
% Convert the null distribution plus the real value to z scores
% Significance exists if the real z value corresponds to p < 0.05 (z>1.96)

goto(fileBase);
session = loadSession(fileBase);
side = session.info.manipulationPosition;
load([fileBase,'.PlotBehaviorByTrials.mat'])

if nargin <2
    nPerm = 1000;
end

% choose arc of interest - we will average over this arc
if strcmp(side,'L')
    arc = [-30 +30] + 240;% left ROI(cage) at 240 - almost always the manipulation site
elseif strcmp(side,'R')
    arc = [-30 +30] + 120;% right ROI(cage) at 120 - rarely used as manipulation site
else    
    arc = [-30 +30] + 240; % in case of no manipulation use left arc
end


for v = 1:out.nVar % variable on interest - should be 14 but I see only 7?
    test = [out.data(:,:,1,v)';out.data(:,:,2,v)'];

    nTrPerBlock = size(out.data,2);
    for i = 1:nPerm
        sh = randperm(size(test,1));
        sh_data = test(sh,:);
        mm = mean(sh_data(:,arc),2);
        df(i) = mean(mm(1:nTrPerBlock)) - mean(mm(nTrPerBlock+1:end));
    end

    mm = mean(test(:,arc),2);
    realDiff = mean(mm(1:nTrPerBlock)) - mean(mm(nTrPerBlock+1:end));

    zD = zscore([df,realDiff]);

    [pvalue(v)] =  pvaluefromz(zD(end));
    clear zD sh mm df
end

disp('***p values of real data wrt the shuffle distribution***');
format compact;
disp(pvalue');
format