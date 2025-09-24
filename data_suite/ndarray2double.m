function x = ndarray2double(x);

sh = x.shape
sh1 = [];
for c=1:length(sh);
    sh1(c) = double(sh{c});
end
x = double(py.array.array('d',py.numpy.nditer(x)));
if length(sh1)>1; x = reshape(x,sh1(end:-1:1)); end;