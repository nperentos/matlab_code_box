% rescale or normalize values to be between the new limits a and b
% If dim = 0, it linearizes the array and applies the new limits on all
% values.
% If dim>0, applies the new limits using the min/max of the corresponding
% row/column. --> like normalizing to the corresponding dimension but for
% min and max.
% If provided, a1 and b1 are the original limits
% If ommited, the min/max are set.
function x=rescale_values(x,a,b,dim, a1,b1)

if nargin < 4; dim = 0;  end;

if dim==0;   
    if ~isvector(x); original_shape = size(x); x=x(:); reshape_flag=1; else; reshape_flag=0; end;
    if nargin < 5; a1 = min(x); b1 = max(x); end;
    x = (x - a1) * (b - a)/(b1 - a1) + a;
    if reshape_flag; x=reshape(x,original_shape); end;
elseif dim==1;
    x=(x - repmat(min(x,[],1),size(x,1),1)).* (repmat(b,size(x))-repmat(a,size(x))) ./(repmat(max(x,[],1),size(x,1),1) - repmat(min(x,[],1),size(x,1),1)) + a;
else % dim==2;
    x=(x - repmat(min(x,[],2),1,size(x,2))).* (repmat(b,size(x))-repmat(a,size(x))) ./(repmat(max(x,[],2),1,size(x,2)) - repmat(min(x,[],2),1,size(x,2))) + a;       
end;