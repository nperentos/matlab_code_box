function h = loghist(x, bins,base)
if nargin<2; bins=10; end;
if nargin<3; base='e'; end;

if strcmp(base,'e');
    x=log(x);
elseif base==10;
    x=log10(x);
elseif base==2;
    x=log2(x);
end;

h = histogram(x,bins); box off; set(gca,'TickDir','out');
%set(gca,'Xscale','log')
if strcmp(base,'e');
    set(gca,'XTickLabel',arrayfun(@num2str,round(exp(get(gca,'XTick')),2),'un',0))
else
    set(gca,'XTickLabel',arrayfun(@num2str,round(base.^(get(gca,'XTick')),2),'un',0))
end