function sws = find_sws(x,artifacts, binsize)

if nargin<3; binsize = 20; end;
if nargin<2; artifacts = []; end;

if ~isstruct(x);
    specs={};
    for ch=1:size(x,1);    
       specs{ch} = specmt(x(ch,:),'defaults','gamma');    
    end

    specs1 = [];
    for c=1:size(x,1)
       specs1(:,:,c) = specs{ch}.Sxy; 
    end;

    t = specs{ch}.t;
    power = mean(mean(specs1,3),2);
    
else
    [~,f1]=spikes_in_periods(x.f,[20 200]);
    power = mean(x.Sxy(:,f1),2);
    t = x.t;    
end

t1 = 0:binsize:max(t);
bins = [t1(1:end-1)' t1(2:end)'];
[~,idx] = spikes_in_periods(t,bins,1);

[~,idx1] = spikes_in_periods(t,artifacts);
power1=power;
power1(idx1) = NaN;

sig = zeros(1,length(idx));
sig1 = zeros(1,length(idx));
for c=1:length(idx);
    sig(c) = mean(power(idx{c}));
    sig1(c) = mean(power1(idx{c}));
end


fig; 
subplot(2,1,1);
plot_spectra(x);
subplot(2,1,2);
jplot(bins(:,1),sig,'r'); hold on; jplot(bins(:,1),sig1); link_axes;
thr = setthreshold(round(prctile(sig,99))); % set as default the 99th percentile

tmp = find(sig>thr);
[~,periods] = find_consecutive(tmp);

periods = periods(cellfun(@length,periods)>1); % Have at least 2 bins, to prevent spurious artifacts/microawakenings from destroyng the states

period_start = cellfun(@(x) x(1), periods);
period_end = cellfun(@(x) x(end), periods);


periods3 = find_no_freeze_periods([period_start' period_end']);
tmp = diff(periods3,[],2);
periods3 = periods3(tmp<=2,:);
%periods3 = periods3(2:end,:); % to get rid of the first line that is 0.1 .. X, because of the find_no_freeze_periods
if periods3(1,1) == 0.1; periods3(1,1) = 1; end;

periods4 = zeros(1,max(max(periods3)));
for c=1:size(periods3,1);
    periods4(periods3(c,1):periods3(c,2)) = 1;
end
periods4 = find(periods4);

tmp = [cell2mat(periods) periods4];
tmp = sort(unique(tmp));

[~,periods2] = find_consecutive(tmp);

period_start = cellfun(@(x) round(x(1)), periods2);
period_end = cellfun(@(x) round(x(end)), periods2);

period_start(period_start<1)=1;
period_end(period_end>length(t))=length(t);

period_start(period_start==0)=[];
period_end(period_end==0)=[];

period_start = bins(period_start,1);
period_end = bins(period_end,2);

movement = [period_start' ; period_end']';
sws = find_no_freeze_periods(movement,max(t));

if (sws(1,1)==0 | sws(1,2)==0); sws=sws(2:end,:); end; % to get rid of the first line that is 0.1 .. X, because of the find_no_freeze_periods, in the case that there is movement in the beginning
close