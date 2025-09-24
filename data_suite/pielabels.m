function pielabels(x,labs)

h = pie(x);

T = h(strcmpi(get(h,'Type'),'text'));
P = cell2mat(get(T,'Position'));
set(T,{'Position'},num2cell(P*0.6,2))
text(P(:,1),P(:,2),labs(:))
