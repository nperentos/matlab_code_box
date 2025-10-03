function [T,G] = genresclu(varargin)
data = varargin;
if nargin==1 && iscell(varargin); data=varargin{1}(:)';  end;

T = double(cell2mat(cellfun(@(x) double(x(:)), data,'un',0)'));
G = zeros(sum(cellfun(@length,data)),1);
cnt = 0;
for c=1:length(data);
    tmp = length(data{c});
    G(cnt+1:cnt+tmp)=c*ones(tmp,1);
    cnt = cnt + tmp;
end;