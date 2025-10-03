% Update 25/03/2017: Changed to using memmapfile. Accelerated the loading by 5x
% Update 26/10/2016: Added option to load partial file

function data = load_binary(filename, channels, maxlen)

%% Process input and filename
if ismac || isunix
    term_char = '/';
else
    term_char = '\';
end;

try;
    filename = split_string(filename,term_char);
    tmp = split_string(filename{end},'.');
    if length(tmp)>2; tmp1 = {}; tmp1{1} = strjoin(tmp(1:end-1),'.'); tmp1{2} = tmp(end); tmp = tmp1; end; % This line takes care of the case that there can be a '.' somewhere in the filename    
    filebase = strjoin([filename(1:end-1) tmp(1)],term_char);
    signaltype = tmp{end};
    if iscell(filebase); filebase = filebase{1}; end;
    if iscell(signaltype); signaltype = signaltype{1}; end;
catch;
    disp('Please provide dat or lfp file');
    return;
end;

try;
    fn = [filebase '.xml'];
    settings = xml2struct(fn);
catch;
    disp('No xml file available.');
    return;
end;

if strcmp(signaltype,'dat') | strcmp(signaltype,'fil');
    SR = str2num(settings.parameters.acquisitionSystem.samplingRate.Text);
elseif strcmp(signaltype,'lfp')
    SR = str2num(settings.parameters.fieldPotentials.lfpSamplingRate.Text);
end;

nchannels = str2num(settings.parameters.acquisitionSystem.nChannels.Text);

if nargin<2 || isempty(channels);
    channels = 1:nchannels;
elseif channels == 0;
    data = [];
    return
end

fn = [filebase '.' signaltype];
% test if it is a symlink - need to do this ootherwise file size is wrong
cmd = (['!test -L ',fn]);
[a,b]=system(['ls -l ', fn, ' | cut -c 1']);
if strcmp(b(1),'l')
    cmd = ['readlink -f ',fn];
    [a,b]=system(cmd);
    b = regexprep(b,'\n+','');
    fn = b;
end

filesize = dir(fn);
filesize = filesize.bytes;
len = filesize/nchannels/2;

%% Try to open file
try;
    m = memmapfile(fn,'Format',{'int16',[nchannels len],'m'},'writable',false);
catch;
    disp('Could not read data file.');
    return;
end;

%% Get file length
if nargin>2 & ~isempty(maxlen); 
    maxlen = maxlen * SR;
    if maxlen<=len; len = maxlen; end;        
end

%% Load file
data = zeros(length(channels),len,'int16'); % ???
for c=1:length(channels);
    ch = channels(c);    
    data(c,:) = m.Data.m(ch,1:len);
end



    
    
    


