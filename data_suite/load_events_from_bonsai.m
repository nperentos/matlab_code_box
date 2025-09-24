function events = load_events_from_bonsai(filebase)
%%
tmp = get_lfp_filename(filebase,'events.csv');
tmp = readlines(tmp);
tmp = split_string(tmp',' ');

events = cellfun(@(x) str2num(x{2}),tmp);

%% Load start time
tmp = get_lfp_filename(filebase,'mov.csv');
tmp = readlines(tmp,2);
tmp = split_string(tmp(:,2)',' ');
t_start = str2num(tmp{1}{1});

%%
events = events - t_start;
events = events/1000; % return seconds
