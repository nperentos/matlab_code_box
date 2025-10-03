function t = make_time(x,trig,sr)
if nargin<2; trig = 0; end;
if nargin<3; sr = 1000; end;

if trig~=0;
    t = linspace(-trig,trig,length(x));
else
    t = linspace(0,length(x)/sr,length(x));
end