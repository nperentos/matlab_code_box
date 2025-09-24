% INPUT: a cell of filenames of type: '/storage/test
% OUTPUT: the lfp filename: /storage/test/test.lfp

function [filenames,names] = get_lfp_filename(filenames,filetype)
if nargin<2; filetype = 'lfp'; end;

term_char = set_term;

if isstr(filenames); filenames = {filenames}; tostring=1; else; tostring=0; end;
filenames = cellfun(@(x) directory_sanitizer(x),filenames,'un',0);

tmp = cellfun(@(x) split_string(x,term_char),filenames,'un',0);
names = cellfun(@(x) x{end-1},tmp,'un',0);


if strcmp(filetype,'')
    filenames = cellfun(@(x,y) [x y],filenames,names,'un',0);
else
    filenames = cellfun(@(x,y) [x y '.' filetype],filenames,names,'un',0);
end
if tostring==1; filenames = filenames{1}; end;

