function [values, indices]=find_nearest(list1, list2, mode)
if nargin<3; mode = 'nearest'; end;

indices = zeros(length(list1),1);
values = zeros(length(list1),1);
for c=1:length(list1);
    d = list2 - list1(c);
    switch mode
        case 'nearest'
            [~,idx] = min(abs(d));
            
        case 'smaller'
            [~,idx] = min(-d); % to confirm
            
        case 'greater'            
            [~,idx] = min(d); % to confirm
    end
    indices(c) = idx;
    values(c) = list2(idx);
end