function term_char=set_term()

if ismac || isunix
    term_char = '/';
else
    term_char = '\';
end;