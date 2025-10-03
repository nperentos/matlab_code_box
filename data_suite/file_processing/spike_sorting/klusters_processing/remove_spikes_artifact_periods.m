function spk_remove_artifact_periods(fn)

fn = directory_sanitizer(fn);
%% Find spike channels
[spikegroups1,sessionname] = get_lfp_filename(fn,'spikegroups');
if ~exist(spikegroups1);
    disp('No spikegroups file found.');
    return;
end

spikegroups1 = fileread(spikegroups1);
spikegroups1 = split_string(spikegroups1,'\n');
spikegroups = {};
for c=1:length(spikegroups1);
    l = spikegroups1{c};
    
    if isempty(l) | strcmp(l(1),'#') | strcmp(l(1),' '); % comment line
        continue;
    else
        tmp = split_string(l,'#');
        comment = tmp{2};
        spikegroups{c} = cellfun(@str2num,split_string(tmp{1},','));
    end; 
end
spikegroups = spikegroups(cellfun(@(x) ~isempty(x), spikegroups));
channels = unique(cell2mat(spikegroups));

%% Find artifact periods
lfpfn = get_lfp_filename(fn,'fil');

hfpower = {};
parfor c=1:length(channels);
    tmp = load_binary(lfpfn,channels(c));
    tmp1 = resample(double(tmp),1,30);
    hfpower{c,1} = zscore(smooth_gauss(abs(tmp1),50,20));
end

hfpower = cell2mat(hfpower);
hfpower = mean(hfpower);
m = mean(hfpower,2);
s = std(hfpower,1,2);
thr = m + 1*s;
tmp = hfpower>thr;
artifact_periods = find_periods(tmp,20, 100);

save(get_lfp_filename(fn,'artifacts'),'artifact_periods','hfpower')

%% Remove spikes

fn1 = [fn 'spikesorting/' sessionname{1}];
for sg = 1:length(spikegroups); 
    clufn = [fn1 '.clu.' num2str(sg)];
    resfn = [fn1 '.res.' num2str(sg)];
    fetfn = [fn1 '.fet.' num2str(sg)];
    spkfn = [fn1 '.spk.' num2str(sg)];
    
    % Load res
    fid = fopen(resfn, 'r');
    res = fscanf(fid, '%d');
    fclose(fid); 
    
    % Edit res
    fid = fopen([resfn 'a'], 'w');
    [res1,spkidx] = spikes_in_periods(res,artifact_periods*30);
    
    res1 = setdiff(res,res1);
    spkidx = setdiff(1:length(res),spkidx);
    
    fprintf(fid,'%d\n',res1)
    fclose(fid);
    
    % Loaf fet
    fid = fopen(fetfn, 'r');
    nFeatures = fscanf(fid, '%d', 1);
    fet = fscanf(fid, '%f', [nFeatures, inf])';    
    fclose(fid);
    
    % Edit fet
    fid = fopen([fetfn 'a'], 'w');
    fprintf(fid,'%d\n',nFeatures);
    
    fet = fet(spkidx,:);
    for c=1:size(fet,1)
        fmt = [repmat('%d ',1, nFeatures) '\n'];
        fprintf(fid,fmt,fet(c,:));
    end
    fclose(fid);
    
    %% Fix .spk files
    elnum = length(spikegroups{sg});    
end

