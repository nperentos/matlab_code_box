% returns the split lfp (the parts between two consecutive maxima).
% returns also the indexes of these parts

function [cycles, lfp_cycle_indexes] = lfp_cycles(lfp, num_cycles)
cycles = {};
lfp_cycle_indexes = [];
[maxindex, minindex] = minimamaxima(lfp);

lfp_cycle_indexes = zeros(num_cycles,2);
for n=1:num_cycles
    cycles{n} = lfp(maxindex(n):maxindex(n+1));
    lfp_cycle_indexes(n,1) = maxindex(n);
    lfp_cycle_indexes(n,2) = maxindex(n+1);
end;

