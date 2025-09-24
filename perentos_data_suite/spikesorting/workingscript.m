% lets try and design a pipeline using Elenas functions for spike loading
% the main aim is to extra the features we need for neuron classification

fileBase = 'NP39_2019-09-04_13-25-48';


% write KS curated output into .res and .clu in the processed directory
GetCluResFromNPY(fileBase);

% load them just to check what we get
[T,G,Map,Par]=LoadCluRes(fileBase);

% derive various variables for each cluster. This runs on all clusters
% irrespective of label (noise, good, MUA or other)
tic;
nq = NeuronQualityKilosort(fileBase); toc
burst = SplitClustersIntoBursts(fileBase); toc
ComputeBurstiness(fileBase); toc
% below needs state detection so will be skipped for now
% fr = FiringRatePeriods(fileBase);

% collect all quality features into one structure 
CellQualitySummary(fileBase)