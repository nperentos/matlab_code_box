function [unit_table, noise] = dat_extract_units(fn)

%% Read spike groups
warning('off','all');
fn = directory_sanitizer(fn);

[spikegroups1,sessionname] = get_lfp_filename(fn,'spikegroups');
if ~exist(spikegroups1);
    disp('No spikegroups file found.');
    return;
end

spikegroups1 = fileread(spikegroups1);
spikegroups1 = split_string(spikegroups1,'\n');
spikegroups_channels = {};
comments = {};
for c=1:length(spikegroups1);
    l = spikegroups1{c};
    
    if isempty(l) | strcmp(l(1),'#'); % comment line
        continue;
    else
        tmp = split_string(l,'#');
        comments{c} = tmp{2};edir
        spikegroups_channels{c} = cellfun(@str2num,split_string(tmp{1},','));
    end; 
end
idx = cellfun(@(x) ~isempty(x), spikegroups_channels);
spikegroups_channels = spikegroups_channels(idx);
comments = comments(idx);


%% Extract units and calculate distances
fn1 = [fn 'spikesorting/' sessionname{1}];

spikegroups = struct();
for sg = 1:length(spikegroups_channels); 
    clufn = [fn1 '.clu.' num2str(sg)];
    resfn = [fn1 '.res.' num2str(sg)];
    fetfn = [fn1 '.fet.' num2str(sg)];
    disp(['Loading ' num2str(sg) '/' num2str(length(spikegroups_channels))]);
    % Load clu
    fid = fopen(clufn, 'r');
    nClusters = fscanf(fid, '%d', 1); % read first to skip the first byte
    clu = fscanf(fid, '%d');
    fclose(fid);        
    nClusters1 = length(unique(clu));
       
    % Load res
    fid = fopen(resfn, 'r');
    res = fscanf(fid, '%d');
    fclose(fid);
    
    % Load fet
    fid = fopen(fetfn, 'r');
    nFeatures = fscanf(fid, '%d', 1);
    fet = fscanf(fid, '%f', [nFeatures, inf])';    
    fclose(fid);

    spikegroups(sg).noise = sort(res(clu == 1));
    clusters = sort(unique(clu));
    
    units = struct();
    for c=2:length(clusters)
        clusteridx = (clu == clusters(c));
        noiseidx = (clu ~= clusters(c));

        units(c-1).spikes = sort(res(clusteridx));
        units(c-1).id = clusters(c);
        
        % Isolation distance
        mdist = mahal(fet,fet(clusteridx,:))';
        %mCluster = mdist(clusteridx);
        mNoise = mdist(noiseidx);
        
        % calculate point where mD of other spikes = n of this cell
        if (sum(clusteridx) < length(res)/2)
            s = sort(mNoise);
            IsolDist = s(sum(clusteridx));
        else
            IsolDist = NaN; % If there are more of this cell than every thing else, forget it.
        end
        
        L = sum(1-chi2cdf(mNoise,size(fet,2)));
        Lratio = L/sum(clusteridx);
        
        units(c-1).isolation_distance = IsolDist; 
        units(c-1).Lratio = Lratio;
    end
    
    spikegroups(sg).units = units;
    spikegroups(sg).channels = spikegroups_channels{sg};
    spikegroups(sg).comments = comments{sg};
end

%% Create units table
k=1;
unit_id = [];
cluster_id=[];
spike_group = [];
channels = {};
comments = {k};
type=[];
quality={};
spikes = {};
for sg=1:length(spikegroups);
    if ~isempty(fieldnames(spikegroups(sg).units))
        for c=1:length(spikegroups(sg).units);
            unit_id(k,1) = k;
            cluster_id(k,1) = spikegroups(sg).units(c).id;
            spike_group(k,1) = sg;
            spikes{k,1} = spikegroups(sg).units(c).spikes;
            channels{k,1} = spikegroups(sg).channels;
            comments{k,1} = spikegroups(sg).comments;
            type{k,1} = 'NaN';
            quality{k,1} = [spikegroups(sg).units(c).isolation_distance spikegroups(sg).units(c).Lratio];
            k=k+1;
        end
    end
end

unit_table = table(unit_id,spike_group,cluster_id,channels,type,quality,comments,spikes);

unit_table1 = unit_table(:,1:end-1);
unit_table1.channels = cellfun(@(x) num2str(x),unit_table1.channels,'un',0);

%% Noise
noise = {};
for c=1:length(spikegroups);
    noise{c} = spikegroups.noise;    
end

%% Save
save(get_lfp_filename(fn,'units'),'unit_table','noise')
writetable(unit_table1, get_lfp_filename(fn,'units.csv'))

disp('Units extracted');

