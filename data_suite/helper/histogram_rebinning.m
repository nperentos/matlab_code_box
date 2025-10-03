% only for one dimension
function y = histogram_rebinning(x, new_length, normalize)
old_length = length(x);

if nargin<2
    new_length = old_length/2;
end;

ratio = old_length/new_length;
if old_length == new_length
    y=x;
    return
end;
y = sum(reshape(x,ratio,new_length));
if nargin>2 && normalize == 1
    y=normalize_array(y);
end;