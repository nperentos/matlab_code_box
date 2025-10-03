function openephys2dat_mapped(filepath, varargin)
% Author: Nikolas Karalis

% Major update: 30/04/2017
% I changed the processing to utilize memory mapping. This makes it slower
% but now it utilizes less memory and can work for any number of channels.
%
% Update: 23/09/2016: 
% Replaced the way that huge files are downsampled. Now the dat2lfp
% function is invoked and the problem is solved there.
% Add a fix in case of channels with different length (finding the minimum
% length and keep that for all the channels - not sure if this is the
% correct approach though).
%
% Update: 10/02/2016: 
%  Added the possibility of loading a period of the data (provided in seconds)
%  Added jump detection (multiple recordings in one file).
%
% Major update 23/11/2015: simplified script - not caring about TTLs etc - much faster
% now (using loadOE.m)
%
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

%% Input parsing
options = {'outpath',[],'lfpSR',1000,'mapping',[],'numcores',[],'downsampleparallel',1,'period',[],'step',5,'appendchannels',1};
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

%% Preparation
[files,channames] = list_files(filepath,[processor,'_*.continuous']);

fileinfo = dir(files{end});
header = load_open_ephys_header(files{end});

period = options.period*header.sampleRate;

if length(files)>length(options.mapping) & options.appendchannels;;
    options.mapping = [options.mapping length(options.mapping)+1:length(files)]; % If there is more channels than in the mapping, just put them in the natural order at the end
end

%% Sort filenames to natural order (arithmetic and CH - AUX - ADC)
[files,channames] = list_files(filepath,[processor,'_*.continuous']);
channames = split_string(channames,'.continuous');
channames = cellfun(@(x) x{1},channames,'un',0);
channames = split_string(channames,'_');
channames = cellfun(@(x) x{2},channames,'un',0);

ephysch = logical(cellfun(@length,strfind(channames,'CH')));
auxch = logical(cellfun(@length,strfind(channames,'AUX')));
adcch = logical(cellfun(@length,strfind(channames,'ADC')));

[~,idx1] = sort(cellfun(@(x) str2num(x(3:end)), channames(ephysch)));
[~,idx2] = sort(cellfun(@(x) str2num(x(4:end)), channames(auxch)));
[~,idx3] = sort(cellfun(@(x) str2num(x(4:end)), channames(adcch)));

idx = [idx1 ; idx2+length(idx1) ; idx3+length(idx1)+length(idx2)];
files = files(idx);

files = files(options.mapping); % Apply mapping

%% Check filestamps
[d, nf,ts] = loadOE(files{end});
if length(unique(diff(ts)))~=1; disp('There is an issue with the timestamps. Contact Nikolas.'); end;
ts_diff = mean(diff(ts(1:10)));
jumps = find(diff(ts)>ts_diff);

if ~isempty(period) & period(1)==0; period(1) = 1; end;
if ~isempty(period) & period(2)==0; period(2) = length(d); end;

if ~isempty(jumps) && isempty(period); 
    disp('There are the following jumps in the recording (times in seconds).');
    disp('Please provide a period as an input to proceed.');
    disp(jumps/header.sampleRate);
    disp(['Total duration:' num2str(length(ts)/header.sampleRate)]);
    return
end;

%% Create empty file
datfn = [options.outpath filebase '.dat'];
nchannels = length(files);
len = length(ts);

if ~isempty(period); len = length(d(period(1):period(2))); end;

filesize = 2 * len * nchannels;
fid=fopen(datfn,'w'); fwrite(fid,0,'short', filesize-2); fclose(fid);

% Map the dat file
%m = memmapfile(datfn,'Format',{'int16',[nchannels len],'m'},'writable',true);

%% Convert
disp('Starting parfor');

% Run groups of step (default: 10) channels (x number of parallel cores)
% If you run into memory problems (for very long sessions), reduce the step
% or do it without parfor.
% The lower the step, the less memory needed

l = length(files);
start = 1:options.step:l;
stop = options.step:options.step:l;
if length(stop)<length(start)
    stop = cat(2,stop,l);
end;
idx = arrayfun(@(x,y) x:y,start,stop,'un',0);

parfor c=1:length(idx)
    disp([num2str(c) '/' num2str(length(idx))])
    m = memmapfile(datfn,'Format',{'int16',[nchannels len],'m'},'writable',true);
    fileidx = idx{c};
    d_all = zeros(length(fileidx),len);
    
    for f = 1:length(fileidx)            
        d = loadOE(files{fileidx(f)})';
        if ~isempty(period); d = d(period(1):period(2)); end;
        d_all(f,:) = d;
    end
    m.Data.m(idx{c},:) = d_all;
end

%% Saving XML
nchannels = length(files); 
neuroscope_xml_creator([options.outpath filebase], header.sampleRate, nchannels, options.lfpSR);

%% Copy settings file
files = list_files(filepath,'settings*.xml');
try; copyfile(files{1},[options.outpath filebase '.oe.xml']); catch; disp('No settings file'); end;
files = list_files(filepath,'*all_channels*.events*');
try; copyfile(files{1},[options.outpath filebase '.events']); catch; disp('No events file'); end;
files = list_files(filepath,'*messages*.events*');
try; copyfile(files{1},[options.outpath filebase '.messages']); catch; disp('No messages file'); end;

%% Convert LFP

datfn = [options.outpath filebase '.dat'];
f = dir(datfn);

% Check if datfile is larger than 60GB. 
% In that case, we are not doing the downsampling in the parfor, because it will eat up the memory. 
% Instead we do it later, not in parallel (slow, but at least gets the job done).
if f.bytes/1e9 > 60; options.downsampleparallel = 0; end; 

disp('Converting LFPs')
ratio = header.sampleRate/options.lfpSR;
if options.downsampleparallel;   
    dat2lfp(datfn,ratio,1);
else    
    dat2lfp(datfn,ratio,2);
end

disp('Finished')


