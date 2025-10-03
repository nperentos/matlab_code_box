function run_kilosort(filebase)

%% Extract info from xml file
xmlfn = get_lfp_filename(filebase,'xml');
settings = xml2struct(xmlfn);

Nchannels = str2num(settings.parameters.acquisitionSystem.nChannels.Text);
fs = str2num(settings.parameters.acquisitionSystem.samplingRate.Text); % sampling frequency

%% Extract spike groups from file
[xcoords,ycoords,kcoords,connected] = read_map_file(filebase);

% No remapping needed in our case
chanMap   = 1:Nchannels;
chanMap0ind = chanMap - 1;

%% Set config options
codebase = '/storage2/nikolas/code/external/KiloSort';
cudabase = '/usr/local/KiloSort/CUDA';

addpath(genpath(codebase))
rmpath(genpath([codebase '/CUDA/']))
addpath(genpath(cudabase))

filebase = directory_sanitizer(filebase);

ops.GPU                 = 1;        % whether to run this code on an Nvidia GPU (much faster, mexGPUall first)		
ops.parfor              = 1;        % whether to use parfor to accelerate some parts of the algorithm		
ops.verbose             = 0;        % whether to print command line progress		
ops.showfigures         = 0;        % whether to plot figures during optimization	

ops.datatype            = 'dat';    % binary ('dat', 'bin') or 'openEphys'
ops.criterionNoiseChannels = 0.2; % fraction of "noise" templates allowed to span all channel groups (see createChannelMapFile for more info). 		

ops.chanMap = [filebase 'chanMap.mat'];
ops.fs                  = fs;                   % sampling rate		(omit if already in chanMap file)
ops.NchanTOT            = Nchannels;           % total number of channels (omit if already in chanMap file)
ops.Nchan               = sum(~isnan(kcoords));           % number of active channels (omit if already in chanMap file)
ops.Nfilt               = ceil(ops.Nchan  * 4 / 32) * 32; % number of clusters to use (2-4 times more than Nchan, should be a multiple of 32)     		
ops.nNeighPC            = 12;           % visualization only (Phy): number of channnels to mask the PCs, leave empty to skip (12)		
ops.nNeigh              = 8;           % visualization only (Phy): number of neighboring templates to retain projections of (16)

% options for channel whitening		
ops.whitening           = 'full'; % type of whitening (default 'full', for 'noSpikes' set options for spike detection below)		
ops.nSkipCov            = 1; % compute whitening matrix from every N-th batch (1)		
ops.whiteningRange      = 32; % how many channels to whiten together (Inf for whole probe whitening, should be fine if Nchan<=32)		

% other options for controlling the model and optimization		
ops.Nrank               = 3;    % matrix rank of spike template model (3)		
ops.nfullpasses         = 6;    % number of complete passes through data during optimization (6)		
ops.maxFR               = 20000;  % maximum number of spikes to extract per batch (20000)		
ops.fshigh              = 400;   % frequency for high pass filtering		
ops.fslow               = 8000;   % frequency for low pass filtering (optional)
ops.ntbuff              = 64;    % samples of symmetrical buffer for whitening and spike detection		
ops.scaleproc           = 200;   % int16 scaling of whitened data		
ops.NT                  = 32*1024+ ops.ntbuff;% this is the batch size (try decreasing if out of memory) - for GPU should be multiple of 32 + ntbuff

% the following options can improve/deteriorate results. 		
% when multiple values are provided for an option, the first two are beginning and ending anneal values, 		
% the third is the value used in the final pass. 		
ops.Th               = [4 10 10];    % threshold for detecting spikes on template-filtered data ([6 12 12])		
ops.lam              = [5 20 20];   % large means amplitudes are forced around the mean ([10 30 30])		
ops.nannealpasses    = 4;            % should be less than nfullpasses (4)		
ops.momentum         = 1./[20 400];  % start with high momentum and anneal (1./[20 1000])		
ops.shuffle_clusters = 1;            % allow merges and splits during optimization (1)		
ops.mergeT           = .1;           % upper threshold for merging (.1)		
ops.splitT           = .1;           % lower threshold for splitting (.1)		
		
% options for initializing spikes from data		
ops.initialize      = 'fromData';    %'fromData' or 'no'		
ops.spkTh           = -6;      % spike threshold in standard deviations (4)		
ops.loc_range       = [3  1];  % ranges to detect peaks; plus/minus in time and channel ([3 1])		
ops.long_range      = [30  6]; % ranges to detect isolated peaks ([30 6])		
ops.maskMaxChannels = 5;       % how many channels to mask up/down ([5])		
ops.crit            = .65;     % upper criterion for discarding spike repeates (0.65)		
ops.nFiltMax        = 10000;   % maximum "unique" spikes to consider (10000)

% load predefined principal components (visualization only (Phy): used for features)		
dd                  = load('PCspikes2.mat'); % you might want to recompute this from your own data		
ops.wPCA            = dd.Wi(:,1:7);   % PCs 		
		
% options for posthoc merges (under construction)		
ops.fracse  = 0.1; % binning step along discriminant axis for posthoc merges (in units of sd)		
ops.epu     = Inf;		
		
ops.ForceMaxRAMforDat   = 30e9; % maximum RAM the algorithm will try to use; on Windows it will autodetect.
save(ops.chanMap, 'chanMap','connected', 'xcoords', 'ycoords', 'kcoords', 'chanMap0ind', 'fs')

% initialize GPU (will erase any existing GPU arrays)
if ops.GPU; 
    try; 
        system('export CUDA_CACHE_MAXSIZE=2147483647');
        system('export CUDA_CACHE_DISABLE=0'); % These export commands are used to solve the slow startup with CUDA 7.5
        tic; gpuDevice(1);  toc;
        disp('GPU initialized');
    catch; 
        disp('Problem with the GPU'); return; 
    end;
    
end  

ops.fbinary = get_lfp_filename(filebase,'dat');	
ops.fproc   = [filebase 'temp_wh.dat']; % residual from RAM of preprocessed data		
ops.root    = filebase;

%% Run main part
tic;
[rez, DATA, uproj] = preprocessData(ops);               % preprocess data and extract spikes for initialization
rez = fitTemplates(rez, DATA, uproj);    % fit templates iteratively
rez = fullMPMU(rez, DATA);               % extract final spike times (overlapping extraction)

save(fullfile(ops.root,  'rez_orig.mat'), 'rez', '-v7.3'); % save matlab results file

try;
    rez = merge_posthoc2(rez); % AutoMerge    
catch;
    disp('Auto-merging failed');
end

save(fullfile(ops.root,  'rez.mat'), 'rez', '-v7.3'); % save matlab results file

rezToPhy(rez, ops.root); % Save python results file for Phy
delete(ops.fproc); % remove temporary file

%% Cleanup
spikedir = directory_sanitizer([filebase 'spikes'],1);
files = list_files(filebase,'*.npy');
cellfun(@(x) movefile(x,spikedir),files);   
files = list_files(filebase,'*.py');
cellfun(@(x) movefile(x,spikedir),files);
files = list_files(filebase,'*rez*.mat');
cellfun(@(x) movefile(x,spikedir),files);
files = list_files(filebase,'*chanMap.mat');
cellfun(@(x) movefile(x,spikedir),files);

%% Fix params file
out = readlines([filebase '/spikes/params.py']);

out(3:end+1) = out(2:end);

% Fix path
tmp = split_string(out{1},'''');
out{1} = [tmp{1} '''' '../' tmp{2} ''''];

out{2} = 'dir_path = ''.''';

fid = fopen([filebase '/spikes/params.py'],'w');

for c=1:length(out);
    fprintf(fid,[out{c} '\n']);
end

fclose(fid)

