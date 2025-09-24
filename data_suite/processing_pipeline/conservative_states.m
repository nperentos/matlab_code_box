function states = conservative_states(data)

states = data.states;

quiet = data.states.quiet;
quiet = quiet(diff(quiet,[],2)>5,:);
sleep = data.states.sleep;
sleep = sleep(diff(sleep,[],2)>30,:);

states.quiet = period_nooverlap(quiet,data.states.micromotions);
sleep = period_nooverlap(sleep,data.states.micromotions);
states.sleep = period_nooverlap(sleep,data.states.rem);