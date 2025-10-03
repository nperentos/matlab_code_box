% This function splits the input string based on the provided delimiter.
% It returns a cell.
% It gives exactly the same output as the strsplit in Matlab2013a but it
% works with all previous version of Matlab.
% 
% Author : Nikolas Karalis
% Date : 03/12/2013

function [x,matches]=split_string(x,delimiter)
% The delimiter conditioning is done for the case of some special
% characters, such as . (dot).
delimiter = strescape(delimiter);
delimiter = regexptranslate('escape', delimiter);
[x,matches]=regexp(x,delimiter,'split','match');
end


% The following are copied from the private folder of strfun in Matlab
% 2013a.
function escapedStr = strescape(str)

escapeFcn = @escapeChar;
escapedStr = regexprep(str, '\\(.|$)', '${escapeFcn($1)}');

end

function c = escapeChar(c)
    switch c
    case '0'  % Null.
        c = char(0);
    case 'a'  % Alarm.
        c = char(7);
    case 'b'  % Backspace.
        c = char(8);
    case 'f'  % Form feed.
        c = char(12);
    case 'n'  % New line.
        c = char(10);
    case 'r'  % Carriage return.
        c = char(13);
    case 't'  % Horizontal tab.
        c = char(9);
    case 'v'  % Vertical tab.
        c = char(11);
    case '\'  % Backslash.
    case ''   % Unescaped trailing backslash.
        c = '\';
    otherwise
        warning(message('MATLAB:strescape:InvalidEscapeSequence', c, c));
    end
end
