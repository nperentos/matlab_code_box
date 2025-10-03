function s = path_splitter(path)
% Check if it works on a Mac or Windows and use the correct character for
% moving between folders.
if ismac || isunix
    term_char = '/';
else
    term_char = '\';
end;

s = regexp(path, '/', 'split');
s=s(~cellfun(@isempty,s)); %remove potential empty trailing or preceding values