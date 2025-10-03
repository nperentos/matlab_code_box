function term_char = path_separator()

if ismac || isunix
    term_char = '/';
else
    term_char = '\';
end;