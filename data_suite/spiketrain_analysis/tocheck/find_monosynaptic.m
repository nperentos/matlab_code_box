function [xc,maxlim,minlim,decision]=find_monosynaptic(spikes1, spikes2,lag,repetitions,binsize)
if nargin<5 || isempty(binsize); binsize=0.001; end;
if nargin<3 || isempty(lag); lag=30; end;
if nargin<4 || isempty(repetitions); repetitions = 100; end;
if nargin<2 || isempty(spikes2); repetitions = 0; autocorr=1; decision = [];  maxlim = []; minlim = []; else; autocorr=0; end; % This is the case for the autocorrelogram, so no statistics performed.

t_start = min([min(spikes1), min(spikes2)]);
t_stop = max([max(spikes1), max(spikes2)]);
t = (t_start:binsize:t_stop);

spikeshist1 = histc(spikes1,t);
spikeshist2 = histc(spikes2,t);

xc=xcorr(spikeshist1,spikeshist2,lag);
if autocorr; xc(lag+1)=0; end;

bar(xc);
set(gca,'XTick', 1:10:2*lag+1, 'XTicKLabel',num2str([-lag:10:lag]'));
xlim([1 2*lag+1]);

if repetitions>0;
    sur_spiketrains1 = surrogate(spikes1,repetitions,0.005)';
    sur_spiketrains2 = surrogate(spikes2,repetitions,0.005)';
    
    t_start = min([min(sur_spiketrains1), min(sur_spiketrains2)]);
    t_stop = max([max(sur_spiketrains1), max(sur_spiketrains2)]);
    t = (t_start:binsize:t_stop);
    
    xcorrmax = zeros(repetitions,1);
    xcorrmin = zeros(repetitions,1);
    for k=1:repetitions;
        sur_hist1 = histc(sur_spiketrains1(k,:),t);
        sur_hist2 = histc(sur_spiketrains2(k,:),t);
        tmp=xcorr(sur_hist1,sur_hist2,lag); % [-20ms, 20,ms]
        xcorrmax(k)=max(tmp);
        xcorrmin(k)=min(tmp);
    end
    hold on;
    maxlim = prctile(xcorrmax,99);
    plot([1 2*lag+1],[maxlim maxlim],'r--');
    xcorrmin = xcorrmin(xcorrmin>0);
    minlim = prctile(xcorrmin,1);
    plot([1 2*lag+1],[minlim minlim],'r--');
    hold off;
    
    bins = xc(lag-5:lag+6);
    if sum(bins>=maxlim)>0;
        decision=1;
    elseif sum(bins<=minlim)>0;
        decision=-1;
    else
        decision=0;
    end
else
    maxlim=[]; minlim=[]; decision=[];
end

end

% Function definition
function surr = surrogate(spikes,n,maxlag)
surr = repmat(spikes,1,n) -maxlag +2*maxlag*(rand(length(spikes),n));
end