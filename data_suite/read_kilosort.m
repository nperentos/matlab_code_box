function read_kilosort(filebase)

%% Load data
info = get_datfile_info(filebase);

st = readNPY([filebase '/spikes/spike_times.npy']); % these are in samples, not seconds
clu = readNPY([filebase '/spikes/spike_clusters.npy']);
spike_templates = readNPY([filebase '/spikes/spike_templates.npy']);
templates = readNPY([filebase '/spikes/templates.npy']);
original_ch = find(readNPY([filebase '/spikes/connected.npy']));

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
    clusters.channel_phy(c) = mode(template_ch(spike_templates(clu == clusters.id(c))+1)); % to correct and eventually I will keep only the original
    clusters.channel(c) = original_ch(clusters.channel_phy(c)); % to correct
    clusters.spikes{c} = double(st(clu == clusters.id(c)));
end

%%
clusters.autocorr = cell(length(clusters.id),1);
for c=1:length(clusters.id)    
    T = clusters.spikes{c};
    G = ones(length(T),1);
    [clusters.autocorr{c},t] = CCG(T,G,0.001*info.fs,0.1/0.001,info.fs,1,'count');    
end

%% Calculate waveforms and templates
nspikes = 1000;
filter_window = 1000;
spike_window = 30;

m = memmap_datfile(filebase,'dat');
maxtime = size(m.Data.m,2);

%%
template = cell(length(clusters.id),1);
waveform = cell(length(clusters.id),1);
ids = clusters.id;
parfor c=1:length(ids)
    disp(['Calculating template ' num2str(c) '/' num2str(length(ids))]);
    spikes = clusters.spikes{c};
    spikes = spikes(randi(length(spikes),min(nspikes,length(spikes)),1)); % random 1000 spikes (or all spikes if less than 1000);    
    spikes((spikes<filter_window) | (spikes>maxtime - filter_window) )=[]; % ensure we get spikes that fit the window
    idx = periodindices(spikes,filter_window); idx = idx(:);
    chans = clusters.channel(c);
    chans = chans-5:chans+5;
    chans = spikes_in_periods(chans,[1 size(m.Data.m,1)]);
    sig = double(m.Data.m(chans,idx));
    sigout = [];
    for ch=1:size(sig,1);
        sig1 = filter_lfp(double(sig(ch,:)),info.fs,[600 8000]);    
        sig1 = reshape(sig1(:),2*filter_window+1,length(spikes))';
        sample_idx = (filter_window-spike_window+1):(filter_window+spike_window+1); % keep samples from the middle
        sigout(:,:,ch) = sig1(:,sample_idx);
    end
    sigout = squeeze(mean(sigout,1))';
    for ch=1:size(sigout,1); sigout(ch,:) = sigout(ch,:)+ch*1000; end;
    template{c} = sigout;
    waveform{c} = sigout(find(chans==clusters.channel(c)),:);  
end
clusters.template = template;
clusters.waveform = waveform;

%% Save
clustersfn = get_lfp_filename(filebase,'clusters');
save(clustersfn,'clusters');


