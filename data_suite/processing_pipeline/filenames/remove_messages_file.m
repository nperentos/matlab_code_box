function remove_messages_file(fn)
%%
messagesfn = get_lfp_filename(fn,'messages');

try;
    out = readlines(messagesfn);
catch;
    return
end

try;
    header = [];
    header(1) = find(cellfun(@(x) sum(strfind(x,'Software time')),out));
    header(2) = find(cellfun(@(x) sum(strfind(x,'Processor:')),out));
catch;
    header
end
    
try; header(3) = find(cellfun(@(x) sum(strfind(x,'StartRecord')),out)); catch; end;

if length(out)<=length(header)
    delete(messagesfn)
end
