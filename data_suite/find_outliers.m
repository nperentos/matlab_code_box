function out = find_outliers(A)
c = -1/(sqrt(2)*erfcinv(3/2));
MAD = c*median(abs(A-median(A)));
out = find(abs(A-MAD)>=3);