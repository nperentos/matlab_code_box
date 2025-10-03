function [units, mua, clusters]=read_phy(filebase)

%% Load data
info = get_datfile_info(filebase);

st = readNPY([filebase '/spikes/spike_times.npy']); % these are in samples, not seconds
clu = readNPY([filebase '/spikes/spike_clusters.npy']);
spike_templates = readNPY([filebase '/spikes/spike_templates.npy']);
templates = readNPY([filebase '/spikes/templates.npy']);
original_ch = find(readNPY([filebase '/spikes/connected.npy']));
%%
try;
    fid = fopen([filebase '/spikes/cluster_group.tsv']); 
    csvdata = textscan(fid,'%f %s','HeaderLines',1,'Delimiter','\t'); 
    fclose(fid); 
catch
    error('No clusters classified yet.')
end;

% Old alternative way to load original channels
%rez = load([filebase '/spikes/rez.mat']);
%rez = rez.rez;
%original_ch = find(rez.connected);

%% Find template channel (to correct)
template_ch = [];
for c=1:size(templates,1);
    tmp = squeeze(templates(c,:,:));
    [~,template_ch(c)]=min(min(tmp(20:60,:),[],1));
end

%% Create clusters table
clusters = table();
clusters.id = double(unique(clu));
clusters.type = repmat({''},length(clusters.id),1);
clusters.channel_phy = double(nan(length(clusters.id),1));
clusters.channel = double(nan(length(clusters.id),1));
clusters.spikes = cell(length(clusters.id),1);
clusters.waveform = cell(length(clusters.id),1);

for c=1:length(clusters.id)
    idx = find(csvdata{1} == clusters.id(c));
    if ~isempty(idx); 
        clusters.type{c} = csvdata{2}{idx};
    end;
    clusters.channel_phy(c) = mode(template_ch(spike_templates(clu == clusters.id(c))+1)); % to correct and eventually I will keep only the original
    clusters.channel(c) = original_ch(clusters.channel_phy(c)); % to correct
    clusters.spikes{c} = double(st(clu == clusters.id(c)));
end

%% Create units table
units = clusters(strcmp(clusters.type,'good'),:);

%% Create MUA table
mua_ch = clusters.channel(strcmp(clusters.type,'mua'));
mua_ch = unique(mua_ch);

mua = table();
for ch=1:length(mua_ch);
    mua.channel(ch,1) = mua_ch(ch);
    mua.spikes{ch,1} = cell2mat(clusters.spikes(clusters.channel == mua_ch(ch))); % merge all spikes
end

muafn = get_lfp_filename(filebase,'mua');
save(muafn,'mua');

%% Calculate average waveform
nspikes = 1000;
filter_window = 1000;
spike_window = 30;

m = memmap_datfile(filebase,'dat');
maxtime = size(m.Data.m,2);

waveform = {};
for c = 1:length(units.id);
    disp(['Processing cluster ' num2str(c) '/' num2str(length(units.id))]);
    tic;
    % Not filtered - improper
    %spikes((spikes<spike_window) | (spikes>maxtime - spike_window) )=[]; % ensure we get spikes that fit the window
    %idx = periodindices(spikes,spike_window); idx = idx(:);
    %sig = double(m.Data.m(clusters.channel(c),idx));
    %sig = reshape(sig(:),2*spike_window+1,length(spikes))';
    %waveform{c} = mean(sig,2);
    %%
    spikes = units.spikes{c};
    spikes = spikes(randi(length(spikes),min(nspikes,length(spikes)),1)); % random 1000 spikes (or all spikes if less than 1000);    
    spikes((spikes<filter_window) | (spikes>maxtime - filter_window) )=[]; % ensure we get spikes that fit the window
    idx = periodindices(spikes,filter_window); idx = idx(:);
    sig = double(m.Data.m(units.channel(c),idx));
    sig = filter_lfp(double(sig),info.fs,[600 8000]);    
    sig = reshape(sig(:),2*filter_window+1,length(spikes))';
    sample_idx = (filter_window-spike_window+1):(filter_window+spike_window+1); % keep samples from the middle
    sig = sig(:,sample_idx);
    waveform{c} = [mean(sig,1) ; sem(sig,1)];
    toc;
end

for c=1:length(waveform); units.waveform{c} = waveform{c}; end;



%% Calculate auto-correlations
T = [];
G = [];
for c = 1:length(units.id);
    T = cat(1,T,units.spikes{c}(:));
    G = cat(1,G,c*ones(length(units.spikes{c}),1));
end
%%
for c=1:size(units,1)
    units.autocorr{c} = CCG(double(T),double(G),0.001*info.fs,0.5/0.001,info.fs,c,'scale');
end

%% Save
unitsfn = get_lfp_filename(filebase,'units');
save(unitsfn,'units');

%% Create Clu-Res
try;
    clures_from_units(filebase);
catch
end