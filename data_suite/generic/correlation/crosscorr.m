function crosscorr(t1,t2,N_bins);
if nargin<3;
    N_bins = 50;
end;
if nargin<2; t2 = t1; end;

t1 = t1(:)';
t2 = t2(:)';

M1 = length(t1);
M2 = length(t2);
D = ones(M2,1)*t1 - t2'*ones(1,M1);
D = D(:);
hist(D,N_bins)
 