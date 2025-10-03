function split_units_multisort(filebase)

%% Prepare filenames
listfn  = get_lfp_filename(filebase,'list');
basedir = directory_sanitizer(fileparts(filebase));

files = readlines(listfn);
files = cellfun(@(x) [basedir x],files,'un',0);
datfiles = get_lfp_filename(files,'dat');

out_dat = get_lfp_filename(filebase,'dat');
out_xml = get_lfp_filename(filebase,'xml');

unitfiles = get_lfp_filename(files,'units');
muafiles = get_lfp_filename(files,'mua');

%% Find lengths
filelengths = [];
for f=1:length(files);
    settings = xml2struct(get_lfp_filename(files{f},'xml'));
    sr = str2num(settings.parameters.acquisitionSystem.samplingRate.Text);
    nchannels = str2num(settings.parameters.acquisitionSystem.nChannels.Text);
    
    filesize = dir(datfiles{f});
    filelengths(f) = filesize.bytes/nchannels/2;
end

maxt_file = cumsum(filelengths);
maxt_file = [[0 ; maxt_file(1:end-1)']+1 maxt_file'];

%% Load units 
[units_merge,mua_merge,clusters_merge]=read_phy(filebase);

%% Split units in files
for f=1:length(files);
    units = units_merge;
    for un=1:size(units,1);
        units.spikes{un} = units.spikes{un}(units.spikes{un}>=maxt_file(f,1) & units.spikes{un}<=maxt_file(f,2));
    end
    save(unitfiles{f},'units')    
end

%% Split MUA in files
for f=1:length(files);
    mua = mua_merge;
    for un=1:size(mua,1);
        mua.spikes{un} = mua.spikes{un}(mua.spikes{un}>=maxt_file(f,1) & mua.spikes{un}<=maxt_file(f,2));
    end
    save(muafiles{f},'mua')    
end
