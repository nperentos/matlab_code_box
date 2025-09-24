%% Find not clustered files
T = load_recording_db;
idx = strcmp(T.Clustered,'TODO') & strcmp(T.AnimalName,'op04'); fn = fn_from_db(idx);

for f=1:length(fn);
    tmp = [fn{f} '/spikes'];
    if isempty(list_files(tmp))
        disp(fn{f});
    end
end;

%% Create clustered column
T = load_recording_db;
idx = 1:size(T,1);
fn = fn_from_db(idx);

clustered = cell(size(idx))';
for f=1:length(fn);
    f
    tmp = [fn{f} '/spikes'];
    if isempty(list_files(tmp))
        out = readlines(get_lfp_filename(fn{f},'map'));        
        if length(out)==0;
            disp(fn{f});
            clustered{f} = '';
        else
            clustered{f} = 'TODO';
        end
    else
        clustered{f} = 'YES';
    end
end;


%% Move every pdf to plots folder
T = load_recording_db;
idx = 1:size(T,1); fn = fn_from_db(idx);

for f=1:length(fn);
    %tmp = [fn{f} '/spikes'];
    if ~isempty(list_files(fn{f},'*.pdf'))
        disp(fn{f});
        %mkdir([fn{f} '/plots'])
        %cellfun(@(x) movefile(x,[fn{f} '/plots']),list_files(fn{f},'*.pdf'))
    end
end;

%% Replace xml
T = load_recording_db;

idx = strcmp(T.SessionName,'pfc02_day1_homecage'); fn = fn_from_db(idx);
template = fn{1};

idx = strcmp(T.AnimalName,'pfc02'); fn = fn_from_db(idx);

for f=11:14;
    apply_neuroscope_template(fn{f},template);
end;

%% Cleanup raw
T = load_recording_db;
idx = strcmp(T.AnimalName,'ras08'); fn = fn_from_db(idx);

for f=1:length(fn);
    if ~exist(get_lfp_filename(fn{f},'dat'));
        try;
            openephys2dat_cleanup(fn{f});
        catch;
            disp(fn{f});
        end
    end;
end

%% Missing dat file
T = load_recording_db;
idx = 1:size(T,1); fn = fn_from_db(idx);

for f=1:length(fn);
    if ~exist(get_lfp_filename(fn{f},'dat')) & ~strcmp(T.Converted{f},'TODO');
        disp(fn{f});
    end
end;

%% Find todel folder

T = load_recording_db;
idx = 1:size(T,1); fn = fn_from_db(idx);

for f=1:length(fn);
    target = [fn{f} '/processed_detection'];
    if exist(target)
        disp(fn{f});
        %if isempty(target)
        %    rmdir(target,'s')
        %end
    end
end

%% Find files not containing filebase
T = load_recording_db;
idx = 1:size(T,1); fn = fn_from_db(idx);

ss = 0;
for f=1:length(fn);
    tmp = list_files(fn{f});
    [~,filebase]=get_lfp_filename(fn{f});
    filebase = filebase{1};
    s=0;
    for c=1:length(tmp);
        [~,fp]=fileparts(tmp{c});
        if ~contains(fp,filebase) & ~strcmp(fp,'processed') & ~strcmp(fp,'todel') & ~strcmp(fp,'closedloop') & ~strcmp(fp,'plots') & ~strcmp(fp,'miniscope') & ~strcmp(fp,'spikes') & ~contains(fp,'adc');
            %disp(tmp{c})
            s=s+1;
        end
    end
    if s>0  & ~strcmp(T.Converted{f},'TODO');
        disp(fn{f})
        f
        ls(fn{f})
        ss = ss+1;
    end
end;

%% Missing channelmaps

%% Missing rippleref

%% Perform state detection
%target = 'hf01';

%T = load_recording_db;
%idx = strcmp(T.StateDetection,'TODO'); fn = fn_from_db(idx);

%fn = files;
for f=1:length(fn);
    disp(fn{f})
    
    statesfn = get_lfp_filename(fn{f},'states');
    if ~exist(statesfn);
        state_detection(fn{f},[],1);
    end
end

%% Check state detection

T = load_recording_db;
idx = 1:size(T,1); fn = fn_from_db(idx);

statedetect = cell(size(idx))';
for f=1:length(fn);
    %disp(fn{f})
    
    statesfn = get_lfp_filename(fn{f},'states');
    if exist(statesfn)
        statedetect{f}='YES';
    end
end

%% Fix info files and re-run SWR detection
T = load_recording_db;
idx = 1:size(T,1); fn = fn_from_db(idx);
idx = strcmp(T.AnimalName,'ob02');
fn = fn_from_db(idx);

for f=1:length(fn);
    [statesfn,sessionname] = get_lfp_filename(fn{f},'states');
    infofn = get_lfp_filename(fn{f},'info');
    sessionname = sessionname{1};
    
    try
        tmp = load(infofn,'-mat');
        info = tmp.info;
        info.fn = fn{f};
        channels = channelmaps.(sessionname);
        if ~isempty(channels);
            info.channels = struct();
            for c = 1:2:length(channels);
                info.channels.(channels{c}) = channels{c+1};
            end
        end
        save(infofn,'info')
        disp('Info saved')
    catch
    end;
    
    try;
        tmp = load(statesfn,'-mat','states');
        states = tmp.states;
    catch;
    end
    
    try;
        data = load_data(fn{f});
        
        pyrch = [];
        posib = {'pyr'};
        for c=posib
            if isfield(data.channels, c)
                pyrch = data.channels.(c{1})(1);
                pyrtmp = getmd(data,pyrch); % Only for the first channel
            end
        end
        
        if isfield(data.channels,'rippleref')
            ref = getmd(data,data.channels.rippleref);
        elseif isfield(data.channels, 'cortex')
            ref  = getmd(data,data.channels.cortex(1));
        elseif isfield(data.channels, 'eeg')
            ref  = getmd(data,data.channels.eeg(1));
        elseif isfield(data.channels, 'mpfc')
            ref = getmd(data,data.channels.mpfc(1));
        elseif isfield(data.channels, 'mPFC')
            ref = getmd(data,data.channels.mpfc(1));
        else
            ref=[];
        end
        
        if ~isempty(pyrch)
            if ~isempty(ref);
                states.swr = find_ripples(pyrtmp,'thr',2.5,'plot',0,'periods',[data.states.quiet ; data.states.sws],'refsig',ref); % Remove ripples inside theta periods
            else
                states.swr = find_ripples(pyrtmp,'thr',2.5,'plot',0,'periods',[data.states.quiet ; data.states.sws]); % Remove ripples inside theta periods
                disp('SWR calculated')
            end
        end
        
        clear ref
        save(statesfn,'states','-v7.3')
        disp('States saved')
    end
end

%% Missing lfp
T = load_recording_db;
idx = 1:size(T,1); fn = fn_from_db(idx);

for f=1:length(fn);
    if exist(get_lfp_filename(fn{f},'dat')) & ~exist(get_lfp_filename(fn{f},'lfp'));
        disp(fn{f});
        dat2lfp(get_lfp_filename(fn{f},'dat'))
    end
end;

%% Fix info file
T = load_recording_db;
idx = 1:size(T,1); fn = fn_from_db(idx);


for f=1:length(fn);
    
    try;
        [statesfn,sessionname] = get_lfp_filename(fn{f},'states');
        infofn = get_lfp_filename(fn{f},'info');
        tmp = load(infofn,'-mat');
        sessionname = sessionname{1};
        
        info = tmp.info;
        oldchannels = info.channels;
        channels = channelmaps.(sessionname);
        if ~isempty(channels);
            info.channels = struct();
            for c = 1:2:length(channels);
                info.channels.(channels{c}) = channels{c+1};
            end
        end
        
    catch;
        continue;
    end
    
    if contains(info.fn,'/storage/nikolas');
        info.fn = strrep(info.fn,'/storage/nikolas','/storage2/nikolas');
        save(infofn,'info')
        disp(fn{f});
        disp('Info saved')
    elseif contains(info.fn,'/storage/lu/data/rec/');
        info.fn = strrep(info.fn,'/storage/lu/data/rec/','/storage2/nikolas/data/Recordings/');
        save(infofn,'info')
        disp(fn{f});
        disp('Info saved')
    end
    
end

%% Re-SWR detection
parfor f=1:length(fn);
    disp(f)
    find_ripples_again(fn{f});
end

%% Update channel info for all sessions
T = load_recording_db; fn = fn_from_db(1:size(T,1));
ChannelMaps
for f=1:length(fn);
    try;
        [infofn,sessionname] = get_lfp_filename(fn{f},'info');
        tmp = load(infofn,'-mat');
        sessionname = sessionname{1};

        info = tmp.info;
        oldchannels = info.channels;
        channels = channelmaps.(sessionname);
        if ~isempty(channels);
            info.channels = struct();
            for c = 1:2:length(channels);
                info.channels.(channels{c}) = channels{c+1};
            end
        end
        info.channels;
        save(infofn,'info');
        %disp(fn{f});
    catch;
        %disp(f)
    end
end