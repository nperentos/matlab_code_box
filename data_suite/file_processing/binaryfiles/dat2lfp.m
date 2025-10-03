% Give dat file as input

% Update: 18/06/2017
% Update: 09/06/2017
%

function dat2lfp(datfn,ratio, parallelflag)

if nargin<2; ratio = 30; end;
if nargin<3; parallelflag = 1; end;

filebase = datfn(1:end-4);
lfpfn = [filebase '.lfp'];

xmlfn = [filebase '.xml'];
settings = xml2struct(xmlfn);

nChannels = str2num(settings.parameters.acquisitionSystem.nChannels.Text);

% Load first channel and resample it
tic;
filesize = dir(datfn);
filesize = filesize.bytes;
datlen = filesize/nChannels/2;
m = memmapfile(datfn,'Format',{'int16',[nChannels datlen],'m'},'writable',false);
tmp = double(m.Data.m(1,:));
tmp1 = resample(tmp,1,ratio);

% Create the .lfp file using the length of the resampled first channel
lfplen = length(tmp1);
filesize = 2 * lfplen * nChannels;
if exist(lfpfn); delete(lfpfn); end;
fid=fopen(lfpfn,'w'); fwrite(fid,0,'short', filesize-2); fclose(fid);

% Save the first channel so that we do not have to convert it again.
m = memmapfile(lfpfn,'Format',{'int16',[nChannels lfplen],'m'},'writable',true);
m.Data.m(1,:) = tmp1;
clear tmp*
toc;

if parallelflag == 1
    start_parallel;
    % Resample the rest of the channels (ch2 onwards)
    parfor c=2:nChannels;
        disp(['Processing channel: ' num2str(c)]);
        tic;
        m = memmapfile(datfn,'Format',{'int16',[nChannels datlen],'m'},'writable',false);
        tmp = double(m.Data.m(c,:));
        tmp1 = resample(tmp,1,ratio);
        tmp1 = int16(tmp1);
        m = memmapfile(lfpfn,'Format',{'int16',[nChannels lfplen],'m'},'writable',true);
        m.Data.m(c,:) = tmp1;
        tmp=[]; tmp1=[]; % clear variables, but ensure transparency in parfor-loop
        toc;
    end
    
    % This option is 12 times slower than the parallel, but is quite ok in terms of memory, it holds at each time the following in memory (e.g. 100GB dat file with 32 channels):
    % single DAT channel 100GB * 4 / 32 = 13 GB
    % single LFP file: 500MB
elseif parallelflag == 0
    % Resample the rest of the channels (ch2 onwards)
    for c=2:nChannels;
        disp(['Processing channel: ' num2str(c)]);
        tic;
        m = memmapfile(datfn,'Format',{'int16',[nChannels datlen],'m'},'writable',false);
        tmp = double(m.Data.m(c,:));
        tmp1 = resample(tmp,1,ratio);
        tmp1 = int16(tmp1);
        m = memmapfile(lfpfn,'Format',{'int16',[nChannels lfplen],'m'},'writable',true);
        m.Data.m(c,:) = tmp1;
        tmp=[]; tmp1=[]; % clear variables, but ensure transparency in parfor-loop
        toc;
    end
end
