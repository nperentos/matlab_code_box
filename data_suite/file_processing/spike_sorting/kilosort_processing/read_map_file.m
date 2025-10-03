function [xcoords,ycoords,kcoords,connected, spikegroups] = read_map_file(filebase);

%% Extract info from xml file
xmlfn = get_lfp_filename(filebase,'xml');
settings = xml2struct(xmlfn);

Nchannels = str2num(settings.parameters.acquisitionSystem.nChannels.Text);

%% Read .map file
out = readlines(get_lfp_filename(filebase,'map'));
ProbeMaps

if length(out)==0;
    xcoords = zeros(Nchannels,1);
    ycoords = 1:Nchannels;
    kcoords = ones(Nchannels,1);
    disp(filebase)
    disp('Map file was empty - Setting default values')
    return
end

xcoords   = NaN*ones(Nchannels,1);
ycoords   = NaN*[1:Nchannels]';
kcoords   = NaN*ones(Nchannels,1);
spikegroups = {};

for g=1:length(out)
    s = out{g};
    
    maxk = max(kcoords);
    maxx = max(xcoords);
    maxy = max(ycoords);
    
    if isnan(maxk); maxk=0; end;
    if isnan(maxy); maxy=0; end;
    
    if ~isempty(strfind(s,'probe'))  
        s = split_string(s,'probe');
        s = cellfun(@strtrim, s,'un',0);
        ch = eval(s{1});
        ch = ch(ch<=Nchannels);
        name = s{2};
              
        xcoords(ch) = probemaps.(name).xcoords + maxx + 1000;
        ycoords(ch) = probemaps.(name).ycoords + maxy + 1000; 
        kcoords(ch) = probemaps.(name).kcoords+maxk;
        probegroups = unique(probemaps.(name).kcoords);
        for c=1:length(probegroups);
            spikegroups = cat(1,spikegroups,ch(probemaps.(name).kcoords==c));
        end
        
    elseif ~isempty(strfind(s,'array'))
        s = split_string(s,'array');
        s = cellfun(@strtrim, s,'un',0);
        ch = eval(s{1});
        ch = ch(ch<=Nchannels);
        s = split_string(s{2},'h');
        hdist = str2num(s{2}); 
        vdist = str2num(s{1}(2:end));

        xcoords(ch) = ones(length(ch),1)*hdist;
        ycoords(ch) = [1:length(ch)]'*vdist + maxy + 1000;        
        kcoords(ch) = ones(length(ch),1) * (maxk+ 1);      
        spikegroups = cat(1,spikegroups,ch);
        
    elseif ~isempty(strfind(s,'bad'))
        s = split_string(s,'bad');
        s = cellfun(@strtrim, s,'un',0);
        ch = eval(s{1});        
        ch = ch(ch<=Nchannels);
        xcoords(ch) = NaN;
        ycoords(ch) = NaN;        
        kcoords(ch) = NaN;
    end    
end

ycoords = -ycoords; % Convention: I define in the probe definition the distances as positive (the deeper the higher the number) and reverse them here

goodchannels = find(~isnan(kcoords));
ignorechannels = setdiff(1:Nchannels,goodchannels);
connected = true(Nchannels, 1);
connected(ignorechannels) = false;
