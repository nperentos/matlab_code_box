% ev in seconds

function [out,t,f] = trig_spec(S,ev, d)
if nargin<3; d=0.5; end; % default: 0.5 sec

t = S.t;
n = round(d/mean(diff(t)));

if isfield(S,'Sxy');
    out = zeros(2*n+1,size(S.Sxy,2),length(ev));
elseif isfield(S,'S');
    out = zeros(2*n+1,size(S.S,1),length(ev));
end
%%
for c=1:length(ev);
    [~,idx]=min(abs(t - ev(c)));
    try;
        if isfield(S,'Sxy');
            out(:,:,c) = S.Sxy((idx - n):(idx+n),:);
        elseif isfield(S,'S');
            out(:,:,c) = S.S(:,(idx - n):(idx+n))';
        end
    catch;
        out(:,:,c) = NaN;
    end;
end

t = linspace(-d,d,n);
f = S.f;