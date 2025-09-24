function remove_date_from_fn(fn)

%%
if ismac || isunix
    term_char = '/';
else
    term_char = '\';
end;

tmp = split_string(fn,term_char);
filebase = [strjoin(tmp(1:end-1),term_char) term_char];
sessionname = tmp{end};
tmp = split_string(sessionname,'_');

newname = [];
for c=1:length(tmp)
    if ~(length(strfind(tmp{c},'-')) == 2);
        newname = cat(2,newname,[tmp{c} '_']); % Find the dates by counting the number of dashes that in the dates are 2
    end
end
newname = [filebase newname(1:end-1)]

if ~exist(newname); 
    movefile(fn,newname); 
else
    disp('New filename exists. Please rename and try again.');
end;
