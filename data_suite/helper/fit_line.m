function [rsq,yfit, p, rsq_adj]=fit_line(x,y,order)
if nargin<3; order = 1; end;

p = polyfit(x,y,order);
yfit = polyval(p,x);

yresid=y-yfit;
SSresid = nansum(yresid.^2);
SStotal = (length(y)-1)*var(y);
rsq = 1-SSresid/SStotal;
rsq_adj = 1 - SSresid/SStotal * (length(y)-1)/(length(y)-length(p));
