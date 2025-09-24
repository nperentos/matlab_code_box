function remove_events_file(fn)
%%
eventsfn = get_lfp_filename(fn,'events');

out = readlines(eventsfn);
idx = cellfun(@(x) sum(strfind(x,'header.')),out);

events = sum(~idx);

if events<=1;
    delete(eventsfn)
end
