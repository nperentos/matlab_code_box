function [data, timestamps, info ofsOut] = readContinuousUpTo(filename,ofsIn)

% secs is how many seconds to read from the end of the file
if nargin < 2
    ofsIn = 0;
end
[~,~,filetype] = fileparts(filename);
if ~any(strcmp(filetype,{'.events','.continuous','.spikes'}))
    error('File extension not recognized. Please use a ''.continuous'', ''.spikes'', or ''.events'' file.');
end


bInt16Out = true;
fid = fopen(filename);
fseek(fid,0,'eof');
filesize = ftell(fid);

NUM_HEADER_BYTES = 1024;
fseek(fid,0,'bof');
hdr = fread(fid, NUM_HEADER_BYTES, 'char*1');
info = getHeader(hdr);
if isfield(info.header, 'version')
    version = info.header.version;
else
    version = 0.0;
end

SAMPLES_PER_RECORD = 1024;
bStr = {'ts' 'nsamples' 'recNum' 'data' 'recordMarker'};
bTypes = {'int64' 'uint16' 'uint16' 'int16' 'uint8'};
bRepeat = {1 1 1 SAMPLES_PER_RECORD 10};
dblock = struct('Repeat',bRepeat,'Types', bTypes,'Str',bStr);
if version < 0.2, dblock(3) = []; end
if version < 0.1, dblock(1).Types = 'uint64'; dblock(2).Types = 'int16'; end

blockBytes = str2double(regexp({dblock.Types},'\d{1,2}$','match', 'once')) ./8 .* cell2mat({dblock.Repeat});
numIdx = floor((filesize - NUM_HEADER_BYTES)/sum(blockBytes));


if nargout>1
    info.ts = segRead('ts');
end            
info.nsamples = segRead('nsamples');
if ~all(info.nsamples == SAMPLES_PER_RECORD)&& version >= 0.1, error('Found corrupted record'); end
if version >= 0.2, info.recNum = segRead('recNum'); end

% read in continuous data
data = segRead_int16('data', 'b');


if nargout>1 % do not create timestamp arrays unless they are requested
    timestamps = nan(size(data));
    current_sample = 0;
    for record = 1:length(info.ts)
        timestamps(current_sample+1:current_sample+info.nsamples(record)) = info.ts(record):info.ts(record)+info.nsamples(record)-1;
        current_sample = current_sample + info.nsamples(record);
    end
    timestamps = timestamps./info.header.sampleRate;
end
        
fclose(fid);

%%
function seg = segRead_int16(segName, mf)
    if nargin == 1, mf = 'l'; end
    segNum = find(strcmp({dblock.Str},segName));
    fseek(fid, sum(blockBytes(1:segNum-1))+NUM_HEADER_BYTES, 'bof'); % go to the begging of the data
    %fseek(fid, sum(blockBytes(1:segNum-1))+NUM_HEADER_BYTES + (numIdx-31)*dblock(segNum).Repeat, 'bof');% go to 30 from last block equivalent to 1s @30KHz
    %fseek(fid, filesize - secs*16*30e3, 'bof');% this is the begging of the last 5 seconds of the data
    if ofsIn > 0
        fseek(fid, ofsIn, 'bof');
    end
    
    seg = fread(fid, (numIdx)*dblock(segNum).Repeat, [sprintf('%d*%s', ...
        dblock(segNum).Repeat,dblock(segNum).Types) '=>int16'], sum(blockBytes) - blockBytes(segNum), mf);

    ofsOut = ftell(fid);
    %seg = fread(fid, (30)*dblock(segNum).Repeat, [sprintf('%d*%s', ...
    %dblock(segNum).Repeat,dblock(segNum).Types) '=>int16'], sum(blockBytes) - blockBytes(segNum), mf);
end

%%
function seg = segRead(segName, mf)
    if nargin == 1, mf = 'l'; end
    segNum = find(strcmp({dblock.Str},segName));
    fseek(fid, sum(blockBytes(1:segNum-1))+NUM_HEADER_BYTES, 'bof'); 
    seg = fread(fid, numIdx*dblock(segNum).Repeat, sprintf('%d*%s', ...
        dblock(segNum).Repeat,dblock(segNum).Types), sum(blockBytes) - blockBytes(segNum), mf);
    
end

end