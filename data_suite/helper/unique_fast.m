% This is a faster implementation of unique.m
% It has only the basic options, not all the features of unique.
%
% Author : Nikolas Karalis
% Date : 03/12/2013

function x=unique_fast(x)
    x=sort(x(:)); 
    x=x([true;logical(diff(x))]); 
    
    
    % TO ADD THE EXTRA OUTPUTS LIKE UNIQUE