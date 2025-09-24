function out = periodindices(x,d)
out = cell2mat(arrayfun(@(y,z)(y:z),x-d,x+d,'un',0)');