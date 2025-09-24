function [thetaperiods,thetadelta,t] = find_theta_periods(x,refsig,varargin)

if nargin<2; refsig = []; end;

%% Input parsing
options = {'sr',1000,'thr',80};
options = inputparser(varargin,options);

if strcmp(options,'error'); return; end;

% Reference the signal
if ~isempty(refsig) && length(refsig)==length(x);
    x = x - refsig;
end


%% Find theta periods
%s = specmt(x,'windowsize',1,'nw',1.5,'overlap',80,'fpass',[1 20],'padding',2,'smooth',0,'normalize',0,'plot',0);
s = specmt(x,'defaults','theta','smooth',0,'normalize',0,'plot',0);
t = s.t;

%%
sigma = 20;
kernelsize = round(20 / mean(diff(t)));
gaussFilter = gausswin(kernelsize,(kernelsize-1)/(2*sigma));
gaussFilter = gaussFilter / sum(gaussFilter); % Normalize.

%%
%thetadelta = smoothn(nansum(s.Sxy(:,s.f>4 & s.f<12),2)./nansum(s.Sxy(:,s.f<4),2),10*options.sr);
thetadelta = nansum(s.Sxy(:,s.f>4 & s.f<12),2)./nansum(s.Sxy(:,s.f<4),2);
%%
thetadelta1 = conv(thetadelta, gaussFilter,'same');

%%
tmp = find(thetadelta>prctile(thetadelta,options.thr))';
jump_points = find(abs(diff([-1000 tmp -1000]))>1);

thetaperiods = options.sr*s.t([tmp(jump_points(1:end-1)) ; tmp(jump_points(2:end)-1)])'; % taking the actual timestamps (because the calculation is done on the spectrogram bins

