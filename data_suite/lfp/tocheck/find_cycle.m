function cycle_assignment = find_cycle(t, cycles_start, cycles_end)
cycle_assignment = nan(size(t));

m1 = arrayfun(@(x)find(x>=cycles_start,1,'last'), t,'un',0);
m2 = arrayfun(@(x)find(x<=cycles_end,1,'first'), t,'un',0);
m1(cellfun(@isempty, m1)) = {NaN};
m1 = cell2mat(m1);

m2(cellfun(@isempty, m2)) = {NaN};
m2 = cell2mat(m2);

cycle_assignment(m1==m2)=m1(m1==m2);