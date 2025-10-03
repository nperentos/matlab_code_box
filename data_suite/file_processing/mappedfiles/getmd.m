% *Important* What is certainly faster is to load more channels in one go, rather than
% multiple runs with one channel each. You can read n channels in the same
% time as 1 channel.

% Speed comparison:
% 1 channel - 3.5 h duration LFP
% From SSD: 3.5 sec
% From External USB3 HD: 10 sec
% From SAMBA NAS (over WiFi): 40 sec
% From /storage2 over SSH/SAMBA: 120 sec

% Note: The first read is always the slow one, consecutive ones
% are very fast, as long as they are for <= maxtime.
% It somehow depends on the caching though, not always the case.

% Update: 24/09/2017: Small update to enable providing as an input directly
% the filebase (no need for data structure)
% Update: 20/09/2017: Fixed a bug of memmap reading, that made it impossibly show over network
% when not providing : instead of specific indexes for reading.
% Now it is still considerably slower over network, compared to local hard
% drive, but it is tolerable.

function out = getmd(data,chan,period,filetype,varcast)
%%
if nargin<2; return; end;
if nargin<3; period = []; end;
if nargin<4; filetype = 'lfp'; end;
if nargin<5; varcast = 'double'; end;
%%
if ischar(data);
    filebase = data;
elseif isstruct(data);
    filebase = data.info.fn;
end
m = memmap_datfile(filebase,filetype);

if ischar(chan) & isstruct(data);
    try
        channels = data.channels.(chan);
    catch
        disp('Channels do not exist');
        out = [];
        return;
    end
elseif iscell(chan) & isstruct(data);
    try
        channame = chan{1};
        chanidx = chan{2};
        channels = data.channels.(channame);
        channels = channels(chanidx);
    catch
        disp('Channels do not exist');
        out = [];
        return;
    end
else
    channels = chan;
end;

sr = 1000; % default in case of other filetype
switch filetype
    case 'lfp'
        if isstruct(data);
            sr = data.info.sr;
        elseif ischar(data);
            xmlfn = get_lfp_filename(filebase,'xml');
            settings = xml2struct(xmlfn);
            sr = str2num(settings.parameters.fieldPotentials.lfpSamplingRate.Text);
        end
    case 'dat'
        if isstruct(data);
            sr = data.info.datsr;
        elseif ischar(data);
            xmlfn = get_lfp_filename(filebase,'xml');
            settings = xml2struct(xmlfn);
            sr = str2num(settings.parameters.acquisitionSystem.samplingRate.Text);
        end
        
end

try
    if ~isempty(period) & length(period)==2;
        if period(1)==0;
            period(1) = 1;
        else
            period(1) = period(1)*sr;
        end;
        
        if period(2)==0;
            period(2) = m.Format{2}(2);
        else
            period(2) = period(2)*sr;
            if period(2)>m.Format{2}(2); % make sure it is not longer
                period(2) = m.Format{2}(2);
            end;
        end;
    else
        period=[];
        period(1) = 1;
        period(2) = m.Format{2}(2); % specifying the indexes, instead of :, to fix a bug that makes it very slow over network
    end
    out = m.Data.m(channels,period(1):period(2));
    
catch
    disp('Channels do not exist');
    out = [];
    return
end

switch varcast
    case 'int16'
        
    case 'single'
        out = single(out);
    case 'double'
        out = double(out);
end;
