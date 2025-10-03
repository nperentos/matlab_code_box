function prepareforclustering(filebase, channels, varargin)

%%
%Need to modify in case of tetrodes etc

%%
filebase = '/storage/nikolas/data/CC/cc07/cc07_example2/processed/cc07_example2';

s = xml2struct([filebase '.xml']);

channels = [21 24 27 28];
s.parameters.spikeDetection.channelGroups.group = [];

for c=1:length(channels);
    fprintf('Processing channel %i of %i\n',c,length(channels));
    
    data = double(load_binary([filebase '.dat'],channels(c)));
    tic; out = detect_spikes(data,'plot',0); toc;
    
    Spk = permute(out.waveforms,[3 2 1]);
    bsave([filebase '.spk.' num2str(c)],sq(Spk),'short');
    
    Res = out.spiketimes;
    msave([filebase '.res.' num2str(c)],Res);
    
    Clu = zeros(length(Res),1);
    msave([filebase '.clu.' num2str(c)],[1; Clu(:)],'w');
    
    Fet = out.features;
    SaveFet([filebase '.fet.' num2str(c)],Fet);
    
    s.parameters.spikeDetection.channelGroups.group{c}.channels.channel.Text = num2str(channels(c)-1);
    s.parameters.spikeDetection.channelGroups.group{c}.nSamples.Text = num2str(size(out.waveforms,2));
    s.parameters.spikeDetection.channelGroups.group{1}.peakSampleIndex.Text = num2str(out.info.samples_pre+1);
    s.parameters.spikeDetection.channelGroups.group{1}.nFeatures.Text = num2str(size(features,2));
end

struct2xml(s,[filebase '.xml']);

