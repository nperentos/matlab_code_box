% Takes as input a cell of 2D arrays (should be the same size)
% and returns a 3d array

function data = cell2mat3(data)
data = data(:)';
data = cell2mat(arrayfun(@(x)permute(x{:},[3 1 2]),data,'un',0)'); 
data = permute(data,[2,3,1]);
