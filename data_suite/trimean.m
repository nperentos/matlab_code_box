function y=trimean(x,DIM)
if nargin<2; DIM=1; end;
y = (quantile(x,0.25, DIM) + quantile(x,0.75, DIM) + 2*quantile(x,0.5, DIM))/4;

