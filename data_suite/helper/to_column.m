% This is an attempt to standardize the input to a function
% If the input is column vector, it is converted to row vector and the flag
% 1 is returned.
% If the input is row, nothing is done (flag=0) and if it is 2D array,
% nothing is done (flag = -1).
% 
% At the end of the code, the following should be performed : 
% if flag; x=x'; end;

function [x, flag]=to_column(x)
if isvector(x)
    if isrow(x)
        x=x(:);
        flag=1;
    else
        flag=0;
    end;
else
    flag = -1;
end