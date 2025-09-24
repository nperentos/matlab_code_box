function spindles = find_spindles(sig,periods,sr)
if nargin<3; sr = 1000; end;
if nargin<3; periods = []; end;
%%
sig0 = filter_lfp(sig,sr,[9 15]);
sig1 = abs(hilbert(sig0));

thr = 1.5; % # std
if ~isempty(periods);
    tmp = spikes_in_periods(sig1,periods*sr);
    thr = mean(tmp)+thr*std(tmp);
else    
    thr = mean(sig1)+thr*std(sig1);
end
[sig1,gk] = smooth_gauss(sig1,sr*0.5,0.1*sr);

[p1,p2] = find_ttl_periods(sig1,0.1,sr,thr,1);
p = [p1' p2'];
p = p(diff(p,[],2)>0.4*sr,:); % above threshold for 400ms
%[~,idx]=spikes_in_periods(mean(p,2),data.states.sws*sr);
%p = p(idx,:);

if ~isempty(periods)
    p = spikes_in_periods(p(:,1),periods*sr);
end

spindle_power = [];
for c=1:size(p,1)
    spindle_power(c) = max(sig1(p(c,1):p(c,2)));
end

[spindle_power,idx] = sort(spindle_power);
spindles.amp = spindle_power;
spindles.period = p(idx,:);
spindles.thr = thr;

%% Find center trough
spindles.trough = [];
for c=1:size(spindles.period,1)
    tmp = sig0(spindles.period(c,1):spindles.period(c,2));
    tmp1 = LocalMinima(tmp);
    [~,m]=min(abs(tmp1 - length(tmp)/2));
    spindles.trough(c) = spindles.period(c,1)+tmp1(m);    
    tmp = sig1(spindles.period(c,1):spindles.period(c,2));
    [~,idx]=max(tmp);
    spindles.t(c) = spindles.period(c,1) + idx;
end
% Plot
%t = make_time(sig);
%fig; jplot(t,sig);
%plot_events(p/sr,'r',10,'min')
%fig; sp; jplot(t,sig); sp; jplot(t,sig1); hold on; jplot(t,s); link_axes('x')