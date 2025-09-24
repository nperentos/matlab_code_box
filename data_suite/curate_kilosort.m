function curate_kilosort(filebase)

clustersfn = get_lfp_filename(filebase,'clusters');
load(clustersfn,'clusters','-mat');

%% Curation GUI
t = linspace(-(length(clusters.acc{1})-1)/2,(length(clusters.acc{1})-1)/2,length(clusters.acc{1}));
h = fig;
set(h, 'WindowKeyPressFcn', @get_keypress)
global keyp
for c=1:length(clusters.id)
    subplot(1,3,[1 2]);
    bar(t,clusters.acc{c}); xlim([-100 100]); box off;
    subplot(1,3,3);
    jplot(clusters.template{c}','k');
    xlim([1 60])
    removeaxis('xy')
    proceed=0;    
    while ~proceed
        keyp = [];
        waitforbuttonpress;
        if strcmp(keyp,'d');
            clusters.type{c} = 'delete';
            proceed = 1;
        elseif strcmp(keyp,'g');
            clusters.type{c} = 'good';
            proceed = 1;
        elseif strcmp(keyp,'m');
            clusters.type{c} = 'mua';
            proceed = 1;            
        end
    end
end

close(h)

%% Save
clustersfn = get_lfp_filename(filebase,'clusters');
save(clustersfn,'clusters');

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

%% Create units table
units = clusters(strcmp(clusters.type,'good'),:);
unitsfn = get_lfp_filename(filebase,'units');
save(unitsfn,'units');

%% Create Clu-Res
try;
    clures_from_units(filebase);
catch
end