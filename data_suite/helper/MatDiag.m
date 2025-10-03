%function y = MatDiag(x, DiagDims)
% get's diagonal entries of the matrix x for those dimensions which are
% square (e.g. in cross-spectrum matrix it's last 2, in coherogram - last
% two. Or can provide dims yourself
function y = MatDiag(x, dims)
sz =size(x); n = length(sz);
if nargin<2 || isempty(dims)
    
    %find equal dims
    %[~, ~, ui] = unique(sz);
    
    for i=1:n-1
        for j=i+1:n
            if sz(i)==sz(j)
                dims =[i j];
                break
            end
        end
    end
end
indstrx = repmat([':,'],1,n);
indstry = repmat([':,'],1,n-2);
indstrx(end)=')';
indstry(end:end+2)=',k)';
indstrx(1+(dims-1)*2)='k';
indstr = ['y(' indstry '=x(' indstrx ';'];
%fprintf('%s\n',indstr);
for k=1:sz(dims(1))
    eval(indstr);
end
     

