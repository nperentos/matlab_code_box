function data = load_binary_noxml(fn, nchannels, channels, maxlen)

%% Process input and filename
if ismac || isunix
    term_char = '/';
else
    term_char = '\';
end;

if nargin<3 || isempty(channels);
    channels = 1:nchannels;
elseif channels == 0;
    data = [];
    return
end

%% Try to open file
try;
    file = fopen(fn,'r');
catch;
    disp('Could not read data file.');
    return;
end;

%% Get file length
fseek(file,0,'eof');
len = ftell(file)/2; % Because short is 16 bit (2 byte)
len = len/nchannels;
fseek(file,0,'bof');

if nargin>3 & ~isempty(maxlen); 
    if maxlen<=len; len = maxlen; end;        
end

%% Load file
szINT16 = 2; % sizeof(int16)=2
%nSamples = Inf;
skipBytes = (nchannels-1)*szINT16;

data = zeros(length(channels),len,'int16'); % ???
for c=1:length(channels);
    ch = channels(c);
    fseek(file,(ch-1)*szINT16,'bof');
    data(c,:) = fread(file, [1 len], 'short=>int16', skipBytes);
end

fclose(file);