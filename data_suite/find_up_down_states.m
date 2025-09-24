function out = find_up_down_states(spikes,periods)
if nargin<2; periods = []; end;
%%
out = struct();
datsr = 30000;
binsize = 10;

maxt = max(cellfun(@max,spikes));
bins = 0:binsize:(maxt/(datsr/1000));
bins = bins*(datsr/1000);

s_all = [];
for c=1:length(spikes);
    s_all(c,:) = histc(spikes{c},bins);
end
s_all0 = sum(s_all); % non-z-scored
s_all = zscore(s_all,[],2);
s_all1 = sum(s_all);
s_all2 = s_all;
for c=1:size(s_all2,1);
    s_all2(c,:) = smooth_gauss(s_all2(c,:),500/binsize,20/binsize); % 0.5 sec, 20 ms sd
end
s_all2 = sum(s_all2); % average of smoothed
s_all2 = s_all2 - min(s_all2);
%%
% Find DOWN states
tmp = s_all1 == min(s_all1);
%tmp = s_all0 == 0;
tmp1 = find_consecutive(tmp);
val = [];
for c=1:size(tmp1,1);
    val(c) = sum(tmp(tmp1(c,1):tmp1(c,2)));
end
tmp1 = tmp1(val > 0,:);

tmp = tmp1(diff(tmp1,[],2)>=5,:);
%%
bins = bins/(datsr/1000);
down_onset = tmp(:,1);
down_offset = tmp(:,2);

% Set threshold
if ~isempty(periods); 
    [~,bins1] = spikes_in_periods(bins,periods*1000);
    tmp = s_all2(bins1);
    thr1 = prctile(tmp,70);
else;
    thr1 = prctile(s_all2,70);
end

% Putative UP states
up_periods = [down_offset(1:end-1) down_onset(2:end)];
tmp = diff(up_periods,[],2);
up_periods = up_periods(tmp>=10 & tmp<=200,:);

up_pow = [];
for c=1:size(up_periods,1)
    up_pow(c) = mean(s_all2(up_periods(c,1):up_periods(c,2)));
end

idx = up_pow>thr1;
up_periods = up_periods(idx,:);
up_onset = up_periods(:,1);
up_offset = up_periods(:,2);
up_pow = up_pow(idx);

up_onset = up_onset * binsize + binsize/2;
up_offset = up_offset * binsize + binsize/2;
down_onset = down_onset * binsize + binsize/2;
down_offset = down_offset * binsize + binsize/2;

up_preceeding_down_onset = [];
up_following_down_offset = [];
for c=1:size(up_periods,1);
    up_preceeding_down_onset(c,1) = down_onset(down_offset == up_onset(c));
    up_following_down_offset(c,1) = down_offset(down_onset == up_offset(c));
end

out.up_onset = up_onset ;
out.up_offset = up_offset;
out.up_pow = up_pow';
out.up_dur = up_offset - up_onset;
out.up_preceeding_down_onset = up_preceeding_down_onset;
out.up_following_down_offset = up_following_down_offset;
out.preceeding_down_dur = up_onset - up_preceeding_down_onset;
out.following_down_dur = up_following_down_offset - up_offset;
%%
% t = linspace(0, max(bins), length(bins))/1000;
% fig; 
% sp;
% jplot(t,s_all2,'k'); 
% %hold on; jplot(t(down_onset),s_all2(down_onset),'*r');
% %hold on; jplot(t(down_offset),s_all2(down_offset),'*y');
% hold on; jplot(up_onset/1000,s_all2((up_onset - binsize/2)/binsize),'or');
% hold on; jplot(up_offset/1000,s_all2((up_offset - binsize/2)/binsize),'og');
% sp;
% jplot(t,s_all1,'k'); 
% link_axes('x')
% xlim([404 410])