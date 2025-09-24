function immobility = find_immobility(x,sr)

if nargin<2; sr=1000; end;

if isempty(x); 
    immobility = [];
    return
end


%%
% Low-pass filter
sigma = 0.1;
kernelsize = 0.5 * sr; % 100ms
gaussFilter = gausswin(kernelsize,1/(2.5*sigma));
gaussFilter = gaussFilter / sum(gaussFilter); % Normalize.
x0 = filter_lfp(x,sr,[0 15]);
%x1 = abs(hilbert(x0));
x1 = conv(x0, gaussFilter,'same');

t = linspace(0, length(x1)/sr, length(x));

fig; 
jplot(t,x1)

thr = setthreshold(median(x1)); % set as default the 99th percentile

close

tmp = find(x1>thr);
[~,periods] = find_consecutive(tmp);

periods = periods(cellfun(@length,periods)>2); % Have at least 2 bins, to prevent spurious artifacts/microawakenings from destroyng the states
%%
period_start = cellfun(@(x) x(1), periods);
period_end = cellfun(@(x) x(end), periods);
mobility = [period_start'  period_end']/sr;
immobility = find_no_freeze_periods(mobility,max(t));

