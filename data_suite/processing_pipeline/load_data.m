% Update 20/09/2017: Made loading states, mua and fbr optional, to make the
% usage of this function faster in the case of just checking files.
% Also, made the function to actually update the data.info.fn to match the
% filename by which it was called.
% Update 25/03/2017: Radically changed the usage. Now it involves memmaping
% and is much more efficient.

function data = load_data(filebase, varargin)

%% Input parsing
options = {'duration',[],'mua',0,'fbr',0,'states',1};
options = inputparser(varargin,options);

if strcmp(options,'error'); return; end;

%% Filenames
fn = get_lfp_filename(filebase);
datfn = get_lfp_filename(filebase,'dat');
fbrfn = get_lfp_filename(filebase,'fbr');
xmlfn = get_lfp_filename(filebase,'xml');
statesfn = get_lfp_filename(filebase,'states');
muafn = get_lfp_filename(filebase,'mua');
unitsfn = get_lfp_filename(filebase,'units');
[infofn,sessionname] = get_lfp_filename(filebase,'info');


%% Load channels
if ~exist(fn);
    data = [];
    disp('No file found');
    disp(fn);
    return;
end;

data = struct();

if exist(infofn);
    tmp = load(infofn,'-mat');    
    data.info = tmp.info;
    data.channels = data.info.channels;
    ChannelMaps % Load channel maps
    % Renew channels from ChannelMaps if available
    if isfield(channelmaps,sessionname{1})
        channels = channelmaps.(sessionname{1});
        if ~isempty(channels);
            info.channels = struct();
            for c = 1:2:length(channels);
                data.info.channels.(channels{c}) = channels{c+1};
            end
        end
        data.channels = data.info.channels;
    end
    data.info.sessionname = sessionname{1};
    % Update the filename to much filename that was called
    data.info.fn = filebase;
else
    error('Please run state_detection.m first');
    return;
end

%% Try to load states
if options.states;
    try;
        tmp = load(statesfn,'-mat','states');
        data.states = tmp.states;
    catch;
    end
end

%% Load units
try;
    tmp = load(unitsfn,'-mat','units');
    data.units = tmp.units;
catch;
end

%% Load MUA
if options.mua
    try;
        tmp = load(muafn,'-mat','mua');
        data.mua = tmp.mua;
    catch;
    end
end;

%% Load fbr
if options.fbr;
    try;
        tmp = load(fbrfn,'-mat','fbr','photo_time');
        data.fbr = tmp.fbr;
        data.info.photo_time = tmp.photo_time;
    catch;
    end
end