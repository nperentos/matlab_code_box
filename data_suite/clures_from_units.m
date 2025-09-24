function clures_from_units(filebase);

%% Load units
unitsfn = get_lfp_filename(filebase,'units');
units = load(unitsfn,'units','-mat');
units = units.units;

if isempty(units);
    return;
end;
%% Create clu - res files
out = readlines(get_lfp_filename(filebase,'map'));
out = cellfun(@(x) split_string(x,' '),out,'un',0);
spikegroups = cellfun(@(x) eval(x{1}),out,'un',0);

for s=1:length(spikegroups)  
    
    unitidx = ismember(units.channel,spikegroups{s});
    
    res = double(cell2mat(units.spikes(unitidx)))';
    clusters = cellfun(@length,units.spikes(unitidx));
    clu = zeros(length(res),1);
    idx = 0;
    for c=1:length(clusters)
        clu(idx+1:idx+clusters(c)) = c* ones(clusters(c),1);
        idx = idx + clusters(c);
    end

    [res,idx] = sort(res);
    clu = clu(idx);
    
    % Create res
    resfn = get_lfp_filename(filebase,['res.' num2str(s)]);
    fid = fopen(resfn, 'w');
    fprintf(fid,'%d\n',res);
    fclose(fid);

    % Create clu
    clufn = get_lfp_filename(filebase,['clu.' num2str(s)]);
    fid = fopen(clufn, 'w');
    fprintf(fid,'%d\n',length(unique(clu)));
    fprintf(fid,'%d\n',clu);
    fclose(fid);
end

%% Edit XML file
xmlfn = get_lfp_filename(filebase,'xml');
settings = xml2struct(xmlfn);

% Add spikegroups to xml
settings.parameters.spikeDetection.channelGroups = struct();
for c=1:length(spikegroups);
    settings.parameters.spikeDetection.channelGroups.group{c}.nSamples.Text = '48';
    settings.parameters.spikeDetection.channelGroups.group{c}.peakSampleIndex.Text = '16';
    settings.parameters.spikeDetection.channelGroups.group{c}.nFeatures.Text = '3';
    for ch=1:length(spikegroups{c})
        settings.parameters.spikeDetection.channelGroups.group{c}.channels.channel{ch}.Text = num2str(spikegroups{c}(ch)-1); % zero based numbering
    end
end

% Save xml
struct2xml(settings,xmlfn);