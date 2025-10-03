function out = cell2mat_pad(C)
maxLength=max(cellfun(@(x)numel(x),C));

if size(C{1},1) <= size(C{1},2);
    out=cell2mat(cellfun(@(x)cat(2,x,zeros(1,maxLength-length(x))),C,'UniformOutput',false));
else
    out=cell2mat(cellfun(@(x)cat(1,x,zeros(maxLength-length(x),1)),C,'UniformOutput',false));
end;



