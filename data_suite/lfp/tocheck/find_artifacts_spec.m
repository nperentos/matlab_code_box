% Seems to work fine, but it relies on which signals are used for the
% detection.
% Watch out for ripples (preferrably don't use pyramidal layer as input)
% Date: 24 Feb. 2016
function [artifacts,power, thr] = find_artifacts_spec(x, y)

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
    power = sum(sum(specs1,3),2);
    
else
    [~,f1]=spikes_in_periods(x.f,[20 200]);
    power = sum(x.Sxy(:,f1),2);
    t = x.t;    
end

sr = 1/mean(diff(t));

% Low-pass filter
sigma = 0.1;
kernelsize = 1 * sr; % 1 sec
gaussFilter = gausswin(kernelsize,1/(2.5*sigma));
gaussFilter = gaussFilter / sum(gaussFilter); % Normalize.

power = conv(power, gaussFilter,'same');

fig; 

if nargin>1 & ~isempty(y);
    %subplot(2,1,1);
    jplot(linspace(0, length(y)/1000,length(y)),y);
    %subplot(2,1,2);
    hold on;
end;

jplot(t,power); link_axes;
thr = setthreshold(round(prctile(power,99))); % set as default the 99th percentile

tmp = find(power>thr);
[~,periods] = find_consecutive(tmp');

dt = mean(diff(t));

period_start = cellfun(@(x) x(1), periods);
period_end = cellfun(@(x) x(end), periods);

% Go 0.5 sec before and after periods
period_start = period_start - 0.5/dt;
period_end = period_end + 0.5/dt;

periods2 = {};
for c=1:length(period_start);
    periods2{c} = period_start(c):period_end(c);
end

period_start = cellfun(@(x) x(1), periods2);
period_end = cellfun(@(x) x(end), periods2);

periods3 = find_no_freeze_periods([period_start' period_end']);
tmp = diff(periods3,[],2);
periods3 = periods3(tmp<1/dt & tmp>0,:);

periods4 = [];
for c=1:size(periods3,1);
    periods4 = cat(2,periods4, periods3(c,1):periods3(c,2));
end

tmp = [cell2mat(periods2) periods4];
tmp = sort(unique(tmp));

[~,periods2] = find_consecutive(tmp);

period_start = cellfun(@(x) round(x(1)), periods2);
period_end = cellfun(@(x) round(x(end)), periods2);

period_start(period_start<1)=1;
period_end(period_end>length(t))=length(t);

period_start = t(period_start);
period_end = t(period_end);

artifacts = [period_start' ; period_end']';
close