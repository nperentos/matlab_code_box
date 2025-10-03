function reorder_datfile(filebase,neworder,filetype)

%% Rename
fn = get_lfp_filename(filebase,filetype);
newfn = [fn '.old'];
movefile(fn,newfn);

oldfile = newfn;
newfile = fn;

%% Load old file
info = get_datfile_info(filebase);
filesize = dir(oldfile);
filesize = filesize.bytes;
nchannels = info.nchannels;
len = filesize/nchannels/2;
m = memmapfile(oldfile,'Format',{'int16',[nchannels len],'m'},'writable',false);

%% Make sure the neworder has same channel number
if length(neworder)<nchannels;
    tmp = 1:nchannels;
    tmp(1:length(neworder))=neworder;
    neworder = tmp;
end

%% Create empty file
fid=fopen(newfile,'w'); fwrite(fid,0,'short', filesize-2); fclose(fid);

%% Reorder
m1 = memmapfile(newfile,'Format',{'int16',[nchannels len],'m'},'writable',true);

for ch=1:nchannels
    disp(ch);
    m1.Data.m(ch,:) = m.Data.m(neworder(ch),:);
end

