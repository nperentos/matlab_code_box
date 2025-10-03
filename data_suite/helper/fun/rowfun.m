function varargout = rowfun(func,x,nargsdef)

if nargin>2
    nargs = nargsdef;
else
    nargs = nargout(func);
    if nargs == -1
        nargs = 1;
    end
end

args=cell(1,nargs);
for c=1:size(x,1)    
    [args{:}]=func(x(c,:));
    for ar = 1:length(args)
        if c==1; varargout{ar} = zeros(size(x,1),length(args{ar})); end;
        varargout{ar}(c,:) =args{ar};
    end
end
