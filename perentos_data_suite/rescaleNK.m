function x = rescaleNK(x, range)
x(x<range(1)) = range(1);
x(x>range(2)) = range(2);
% (x-range(1))/(range)