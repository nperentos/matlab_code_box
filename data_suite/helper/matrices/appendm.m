%%
% Essentially does the same as the cat function, but only works for vectors
% and takes care of doing the concatenation in the proper dimension.
% The result is always column

function x = appendm(x,y)
if isempty(x); x=y; return; end;
if isempty(y); return; end;

if ~(isvector(x) & isvector(y)) ; error('This function only works with vectors'); end;

x = x(:);
y = y(:);

x = [x ; y];