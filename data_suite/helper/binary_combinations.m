% this function produces a matrix, whose rows are all possible combinations
% for a length n_t binary vector, e.g. [0 0; 0 1; 1 0; 1 1] for n_t = 2
% Written by Swaprava Nath, Nov 29, 2008

function M = binary_combinations(n_t)

if n_t > 1
    L = binary_combinations(n_t - 1);
    row = size(L,1);
    M = [zeros(row,1) L; ones(row,1) L];
else
    M = [0;1];
end