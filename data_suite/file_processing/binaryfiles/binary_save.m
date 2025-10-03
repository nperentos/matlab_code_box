% For unknow reasons, the cell version works find on mac but crashes on
% linux. It cannot be used for the moment.

function binary_save(filename,matrix)

if iscell(matrix)    
    fid = fopen(filename,'w');
    fclose(fid);
    
    szINT16 = 2; % sizeof(int16)=2
    nchannels = length(matrix);
    skipBytes = (nchannels-1)*szINT16;
     
    t=0;
    for c=1:nchannels;
        tic;        
        disp(['Saving channel ' num2str(c) ' of ' num2str(nchannels)]);
        fid = fopen(filename,'r+');  
        fseek(fid, szINT16*(c-1), 'bof');
        fwrite(fid, matrix{c}(1), 'short');
        fwrite(fid, matrix{c}(2:end), 'short', skipBytes);
        fclose(fid);
        t = t+toc;
        disp(['Expected remaining time: ' num2str((t/c)*(nchannels-c))]);         
    end;
    fclose(fid);
else
    fid = fopen(filename,'w');
    fwrite(fid,matrix,'short');
    fclose(fid);
end