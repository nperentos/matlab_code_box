% cell2mat_trunc
% 
% Description: Truncates each matrix contained in the cell array to the
% minimum of the matrices and converts to a matrix.
% It workes only on the principal dimension of the cell and for vector
% matrices.
% 
% 
% Input:
% 
% Ouput:
% 
% 
% Dependencies: 
% 
% Author: Nikolas Karalis
% Date: 26-Dec-2013
% 
% Copyright: 
% 
% 
% Updates: 


function M=cell2mat_trunc(C)

l = cellfun(@length, C);
if ~sum(diff(l))==0;
    m = min(l);
    for c=1:length(C)
        C{c} = C{c}(1:m);
    end;
end;
M = cell2mat(C);