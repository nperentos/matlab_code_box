function run_mountainsort(filename)

tmp = dir(get_lfp_filename(filename,'dat')); 
tmp = round(tmp.bytes/(1024^3),2);
if tmp>=40; % more than 40GB dat file
    error('File is too big. Please run the run_mountainsort_big.m instead.');
end

%% Fix Matlab path
%tmp = getenv('LD_LIBRARY_PATH'); 
%setenv('LD_LIBRARY_PATH',['/lib/x86_64-linux-gnu:' tmp]);
setenv('LD_LIBRARY_PATH','/lib/x86_64-linux-gnu');

%% Clear tmp file (/scratch)
system('rm -r /bigscratch/mountainsort/mountainlab')

%% Create folder structure
mtsortdir = [directory_sanitizer(filename) 'mtsort/'];
mkdir(mtsortdir);
mkdir([mtsortdir 'datasets']);
mkdir([mtsortdir 'datasets/dataset1']);

%% Create curation.script file
tmp = which('curation.script');
try; copyfile(tmp,mtsortdir); catch; end;

%% Create datasets.txt file
tmp = 'ds1 datasets/dataset1';
tmpfid = fopen([mtsortdir 'datasets.txt'], 'w');
fwrite(tmpfid,tmp);
fclose(tmpfid);

%% Set geometry
% Extract spike groups from file
[xcoords,ycoords,kcoords,connected] = read_map_file(filename);

% Place the bad channels really far away (and will not use them for sorting
% anyway
xcoords(isnan(xcoords)) = 100000;
ycoords(isnan(ycoords)) = 100000;

% Find good channels
channels = find(connected);

% Create geom.csv
dlmwrite([mtsortdir 'datasets/dataset1/geom.csv'],[xcoords ycoords],'precision','%i')

%% Create pipelines.txt file
tmp = 'ms3 ms3.pipeline --whiten=true --detect_sign=-1 --multineighborhood=true --merge_across_channels=true --adjacency_radius=150 --mask_out_artifacts=true --compute_metrics=true --curation=curation.script';

chanstr = strrep(mat2str(channels(:)),';',',');

% Select channels to sort
tmp = [tmp ' --channels=' chanstr(2:end-1)];

tmpfid = fopen([mtsortdir 'pipelines.txt'], 'w');
fwrite(tmpfid,tmp);
fclose(tmpfid);

%% Create params.json file
tmp = '{"samplerate":30000,"sign":0}';
tmpfid = fopen([mtsortdir 'datasets/dataset1/params.json'], 'w');
fwrite(tmpfid,tmp);
fclose(tmpfid);

%% Convert .dat to .mda and .mda.prv
[fn,sessionname] = get_lfp_filename(filename,'xml');
sessionname = sessionname{1};
settings = xml2struct(fn);
nchannels = str2num(settings.parameters.acquisitionSystem.nChannels.Text);
if ~exist([mtsortdir 'datasets/dataset1/' sessionname '.mda']);
    cmd = ['mdaconvert ' get_lfp_filename(filename,'dat') ' ' [mtsortdir 'datasets/dataset1/' sessionname '.mda'] ' --dtype=int16 --num_channels=' num2str(nchannels) ' --input_format=raw_timeseries'];
    [s]=system(cmd);
    %movefile(get_lfp_filename(filename,'mda'),[mtsortdir 'datasets/dataset1/']);
end

tmp1 = [mtsortdir 'datasets/dataset1/' sessionname '.mda'];
tmp2 = [mtsortdir 'datasets/dataset1/raw.mda.prv'];    
if ~exist(tmp2);    
    cmd = ['prv-create ' tmp1 ' ' tmp2];
    [s]=system(cmd);
end

%% Run clustering
disp('Running clustering');
cd(mtsortdir);
system('kron-run ms3 ds1 --_nodaemon >> clusteringlog.txt')

disp('=========================================')
disp('Clustering complete')

%% Create units table
read_mountainsort(filename)

%% Clean-up .mda file
system(['rm ' mtsortdir 'datasets/dataset1/' sessionname '.mda'])

%% Clean-up tmp
system('rm -r /bigscratch/mountainsort/mountainlab')
    
