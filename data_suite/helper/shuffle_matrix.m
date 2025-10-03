function y=shuffle_matrix(x,dim)
if nargin<2 || isempty(dim) || dim == 0
    y=x(randperm(size(x,1)*size(x,2)));
    y =reshape(y,size(x));

elseif dim==1
    s = size(x,dim);
    for c=1:s
        temp = x(c,:);
        idx = randperm(length(temp));
        temp=temp(idx);
        y(c,:) = temp;
    end;
elseif dim==2
    s = size(x,dim);
    for c=1:s
        temp = x(:,c);
        idx = randperm(length(temp));
        temp=temp(idx);
        y(:,c) = temp;
    end;    
    
end;

