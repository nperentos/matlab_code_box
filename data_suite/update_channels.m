function update_channels(filebase);

filebase = directory_sanitizer(filebase);
ChannelMaps % Load channel maps
fn = get_lfp_filename(filebase);

infofn = get_lfp_filename(filebase,'info');
tmp = load(infofn,'-mat');
info = tmp.info;

[~, session]=fileparts(fn);
if isfield(channelmaps,session)
    channels = channelmaps.(session);
end
if ~isempty(channels);
    info.channels = struct();
    for c = 1:2:length(channels);
        info.channels.(channels{c}) = channels{c+1};
    end
end

save(infofn,'info')