function merge_units(filename);

%%
[xcoords,ycoords,kcoords,connected,spikegroups] = read_map_file(filename);

%% Merge back units
for s=1:length(spikegroups);       
    tmp = load(get_lfp_filename(filename,['units' num2str(s)]),'-mat','units');
    tmp = tmp.units;
    chans = find(connected(spikegroups{s}));
    chans = spikegroups{s}(chans);
    chans = chans(:);
    tmp.channel = chans(tmp.rel_channel); %fix channels
    
    if s==1 | isempty(units);
        units = tmp;
    elseif ~isempty(tmp);
            units = cat(1,units,tmp);
    end    
end

units.rel_channel = [];
clustersfn = get_lfp_filename(filename,'units');
save(clustersfn,'units');

add_unit_template(filename);
clures_from_units(filename);
