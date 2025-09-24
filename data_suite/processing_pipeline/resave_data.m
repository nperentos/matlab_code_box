function resave_data(data)

filebase = data.info.fn;
infofn = get_lfp_filename(filebase,'info');
statesfn = get_lfp_filename(filebase,'states');

info = data.info;
save(infofn,'info')

states = data.states;
save(statesfn,'states','-v7.3')