function unitProcessing(fileBase,varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% unitProcessing umbrella function for unit processing, from phy curated output to trial-resolved
% spatial tuning curves.
% calls: getClusterProperties.m
%      : getTuningCurves.m (calls PFStability.m getMeanSpikePerPeriod.m permutePlaceRasters.m )
%      : selectClusters.m
% INPUT: fileBase
%        flag (1: continuous unidirectional (default), 2: cued direction and 3: passive) optional
%        pth: if not default path/folder structure then provide path to folder with data
%        verbose: to plot or not to plot
%        OUTPUT: fileBase.nq.mat - various cluster properties
%                fileBase.tun.mat - trial resolved tuning curves for the whole recording
%                fileBase.selectedClusters.mat - labels for selected clusters at a couple of acecptance.rejection criteria
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
options = {'flag',[],'pth',[],'verbose',1};
options = inputparser(varargin,options);

%% RUN BASIC PROCESSING SCRIPTS
if ~isempty(options.pth)
    processedPath = getfullpath(fileBase,options.pth);
    cd(processedPath)
else
    processedPath = getfullpath(fileBase);
    cd(processedPath)
end

% to avoid conflicts and inconsistencies, run all scripts together
getClusterProperties(fileBase);
getTuningCurves(fileBase,{'flag',options.flag,'verbose',options.verbose});
placeCellCoverage(fileBase);
%selectClusters(fileBase); % nq and tun are now joined together in one structure