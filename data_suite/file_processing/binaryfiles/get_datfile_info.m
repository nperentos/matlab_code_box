function info = get_datfile_info(filebase)
xmlfn = get_lfp_filename(filebase,'xml');
settings = xml2struct(xmlfn);

info.nchannels = str2num(settings.parameters.acquisitionSystem.nChannels.Text);
info.fs = str2num(settings.parameters.acquisitionSystem.samplingRate.Text); % sampling frequency
info.fn = get_lfp_filename(filebase,'dat');