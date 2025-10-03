function [files,toolboxes, filenames]=find_dependencies(fn)

[files, tmp2]=matlab.codetools.requiredFilesAndProducts(fn);

toolboxes = {};
for c=1:length(tmp2);
    toolboxes{c,1} = [tmp2(c).Name ' - ' tmp2(c).Version];
end

files = files';

if ismac || isunix
    term_char = '/';
else
    term_char = '\';
end;

filenames = '';
for c=1:length(files);
    tmp = strsplit(files{c},term_char);
    filenames = [filenames ', ' tmp{end}];
end
filenames = ['Dependencies: ' filenames(3:end)];
