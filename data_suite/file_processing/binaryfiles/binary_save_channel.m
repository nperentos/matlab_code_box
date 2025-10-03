function binary_save_channel(filename,data, channel, nchannels)

if ~exist(filename);
    fid = fopen(filename,'w');
    tmp = zeros(nchannels, length(data),'int16');   
    tmp(channel,:) = data;
    
    fwrite(fid,tmp,'short');
    fclose(fid);

else
    fid = fopen(filename,'r+');
    szINT16 = 2; % sizeof(int16)=2    
    skipBytes = (nchannels-1)*szINT16;    
    fseek(fid, szINT16*(channel-1), 'bof');
    fwrite(fid, data(1), 'short');
    fwrite(fid, data(2:end), 'short', skipBytes);
    fclose(fid);
end