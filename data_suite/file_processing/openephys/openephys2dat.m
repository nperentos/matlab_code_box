function openephys2dat(filepath, varargin)
% Author: Nikolas Karalis


% Update: 09/06/2017:
% Changed the saving method to be based on memory mapping. Now it can work for huge files without running out of memory
% (no matrix duplication/inversion etc). However, it is much slower... need to fix.
%
% Update: 23/09/2016:
% Replaced the way that huge files are downsampled. Now the dat2lfp
% function is invoked and the problem is solved there.
% Add a fix in case of channels with different length (finding the minimum
% length and keep that for all the channels - not sure if this is the
% correct approach though).

% Update: 10/02/2016:
%  Added the possibility of loading a period of the data (provided in seconds)
%  Added jump detection (multiple recordings in one file).

% Major update 23/11/2015: simplified script - not caring about TTLs etc - much faster
% now (using loadOE.m)

% Major Update: 12/07/2015: I rewrote the function almost completely to be
% cleaner code and to be able to work with **big** files.
% It relies on a modified version of the load_open_ephys_data.m
% Major Update: 04/03/2015
%    All channel types saved in one file, xml changess
% Major Update: 06/11/2014
%    input parsing, messages, new OpenEphys filenames
%    for the moment I am ignoring aux channels
%    improved neuroscope xml creation
% Major Update: 10/10/2014
% Date: 18/09/2014
% Date: 08/01/2020 added an ignore AUX channels since its not needed for HF
% see line 92

%% Input parsing
options = {'outpath',[],'lfpSR',1000,'mapping',[],'numcores',[],'downsampleparallel',1,'period',[],'jumpoverride',0,'appendchannels',1};
options = inputparser(varargin,options);
if strcmp(options,'error'); return; end;

filepath = directory_sanitizer(filepath);
if ismac || isunix; term_char = '/'; else; term_char = '\'; end;

% Setting up parallel processing
myPool = start_parallel(options.numcores);

if isempty(options.outpath);
    options.outpath = directory_sanitizer([filepath 'processed/'],1);
else
    fn = path_splitter(filepath);
    options.outpath = cat(2,options.outpath,fn{end});
    options.outpath = directory_sanitizer(options.outpath,1);
end; % To create the path if it does not exist.

filebase = split_string(filepath,term_char);
filebase = filebase{end-1};

files = list_files(filepath,'*.continuous');
if length(files)<1;
    disp('No files found');
    return;
end;

disp(['Processing file: ' filepath]);

%% Find how many processor files are available
[~,fns] = list_files(filepath,'*CH*.continuous');
avail_proc = unique(cellfun(@(x)x{1},cellfun(@(x)split_string(x,'_CH'),fns,'un',0),'un',0));
if isempty(fns);
    [~,fns] = list_files(filepath,'*ADC*.continuous');
    avail_proc = unique(cellfun(@(x)x{1},cellfun(@(x)split_string(x,'_ADC'),fns,'un',0),'un',0));
end
if isempty(fns);
    [~,fns] = list_files(filepath,'*AUX*.continuous');
    avail_proc = unique(cellfun(@(x)x{1},cellfun(@(x)split_string(x,'_AUX'),fns,'un',0),'un',0));
end

if length(avail_proc)>1;
    disp(['The available processors are: ']);
    disp(avail_proc);
    
    processor = input('Please type in the processor you want to convert (nothing to exit): ','s');
    if isempty(processor); return; end;
else
    processor = avail_proc{1};
end;

%% Main computation
files = list_files(filepath,[processor,'_*.continuous']);
% ignore the auxiliary channels (for headfixed)
files(contains(files,'AUX'))=[];
warning('ignoring the auxiliary channels - modify openwphys2dat.m if you want to include them');
files
raw = cell(1,length(files)); ch_idx = {}; ch_type = {};

fileinfo = dir(files{end});
header = load_open_ephys_header(files{end});

period = options.period*header.sampleRate;
[d, nf,ts] = loadOE(files{end});
if length(unique(diff(ts)))~=1; disp('There is an issue with the timestamps. Contact Nikolas.'); end;
ts_diff = mean(diff(ts(1:10)));
jumps = find(diff(ts)>ts_diff);

if ~isempty(period) & period(1)==0; period(1) = 1; end;
if ~isempty(period) & period(2)==0; period(2) = length(d); end;


if ~isempty(jumps) && isempty(period) & ~options.jumpoverride;
    disp('There are the following jumps in the recording (times in seconds).');
    disp('Please provide a period as an input to proceed.');
    disp(jumps/header.sampleRate);
    disp(['Total duration:' num2str(length(ts)/header.sampleRate)]);
    return
end;

disp('Starting parfor');
% load channels with the default order (alphanumeric)
parfor c=1:length(files)
    %[d, ~, nf] = load_open_ephys_data_NK(files{c});
    [d, nf] = loadOE(files{c});
    
    if ~isempty(period); d = d(period(1):period(2)); end;
    
    ch = nf.header.channel;
    if strcmp(ch(1:3),'ADC') || strcmp(ch(1:3),'AUX'); datatype=ch(1:3); idx=4; else; datatype=ch(1:2); idx=3; end;
    
    ch = str2num(ch(idx:end));
    
    ch_type{c} = datatype;
    ch_idx{c} = ch;
    raw{c} = d;
end

% now reorder so that ADC and AUX are at the end
ch_idx = cell2mat(ch_idx);

tmp = find(strcmp(ch_type,'CH'));
[~,tmpidx]=sort(ch_idx(tmp));
idxCH = tmp(tmpidx);

tmp = find(strcmp(ch_type,'AUX'));
[~,tmpidx]=sort(ch_idx(tmp));
idxAUX = tmp(tmpidx);

tmp = find(strcmp(ch_type,'ADC'));
[~,tmpidx]=sort(ch_idx(tmp));
idxADC = tmp(tmpidx);

idx = cat(2,idxCH,idxAUX,idxADC);

raw = raw(idx);

% Mapping
if ~isempty(options.mapping)
    [Y,I]=sort(options.mapping);
    [~,I2]=sort(I);
    if length(raw)>length(options.mapping) & options.appendchannels        
        raw = raw([I2, length(options.mapping)+1:length(raw)]); % If there is more channels than in the mapping, just put them in the natural order at the end
    else
        raw=raw(I2');
    end;
    disp('Mapped successfully');
end;

channel_list = num2cell(ch_idx(idx)');
channel_list(:,2) = ch_type(idx);

%% Saving raw

disp('Loading finished. Saving...')
tmp = whos('raw');

mem = memorylinux;

tmplength = cellfun(@length,raw);
uniquetmp = unique(tmplength);
if numel(uniquetmp)>1;
    disp('Channels with different length!! - Please check!');
    
    disp('Lengths:')
    for c=1:length(uniquetmp);
        disp(uniquetmp(c));
    end
    minlength = min(tmplength);
    for c=1:length(raw);
        raw{c} = raw{c}(1:minlength);
    end
end

datfn = [options.outpath filebase '.dat'];

tic;

if mem/(tmp.bytes/1e9)>2;
    binary_save([options.outpath filebase '.dat'],cell2mat(raw)');
else % If we cannot afford to convert the cell to array (needs double memory), we do it channel by channel - slow.
    disp('Saving slow...');
    
    nchannels = length(raw);
    len = length(raw{1});
    filesize = 2 * len * nchannels;
    fid=fopen(datfn,'w'); fwrite(fid,0,'short', filesize-2); fclose(fid);
    
    parfor c=1:length(raw)
        tic;
        m = memmapfile(datfn,'Format',{'int16',[nchannels len],'m'},'writable',true);
        m.Data.m(c,:) = raw{c};
        disp(['Saved channel: ' num2str(c)]);
        toc;
    end
    
    %binary_save([options.outpath filebase '.dat'],raw); % old alternative very slow way
    
end;
toc;

%% Saving XML
nchannels = length(raw);
neuroscope_xml_creator([options.outpath filebase], header.sampleRate, nchannels, options.lfpSR);

%% Copy settings file
files = list_files(filepath,'settings*.xml');
try; copyfile(files{1},[options.outpath filebase '.oe.xml']); catch; disp('No settings file'); end;
files = list_files(filepath,'*all_channels*.events*');
try; copyfile(files{1},[options.outpath filebase '.events']); catch; disp('No events file'); end;
files = list_files(filepath,'*messages*.events*');
try; copyfile(files{1},[options.outpath filebase '.messages']); catch; disp('No messages file'); end;

fclose(fopen([options.outpath filebase '.map'], 'w')); % Create empty .map file


%% Convert LFP
datfn = [options.outpath filebase '.dat'];

% Disable parallel downsample if huge files
% Calculates the projected total memory usage by the parallelpool and makes sure it
% is <80% of the total system memory.
if options.downsampleparallel;
    distcomp.feature( 'LocalUseMpiexec', true);
    maxCores = feature('numCores');
    nchannels = length(raw);
    f = dir(datfn);
    if f.bytes/1e9/nchannels*maxCores>0.8*memorylinux;
        %options.downsampleparallel = 0;
    end
end

clear raw

disp('Converting LFPs')
ratio = header.sampleRate/options.lfpSR;
if options.downsampleparallel;
    dat2lfp(datfn,ratio,1);
else
    disp('Converting without parfor - 12x slower');
    dat2lfp(datfn,ratio,0);
end

disp('Finished')

