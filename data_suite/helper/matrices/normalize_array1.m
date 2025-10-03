function x = normalize_array1(x)
for c=1:size(x,1);
  tmp = x(c,:);
  x(c,:) = (tmp - min(tmp))/(max(tmp) - min(tmp));    
end

