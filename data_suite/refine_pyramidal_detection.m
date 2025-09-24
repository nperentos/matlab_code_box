function refine_pyramidal_detection(data)

ripples = find_ripples(getmd(data,{'pyr',1}),'thr',3,'plot',0,'periods',[data.states.quiet ; data.states.sws],'refsig',getmd(data,{'rippleref',1}));

pyrch = data.channels.pyr(1);
if isfield(data.channels,'ca1')
    hpcchan = data.channels.ca1;
elseif isfield(data.channels,'dca1')
    hpcchan = data.channels.dca1;
elseif isfield(data.channels,'hpc')
    hpcchan = data.channels.hpc;
elseif isfield(data.channels,'v1')
    hpcchan = data.channels.v1;
end
testch = intersect(pyrch-5:pyrch+5,hpcchan);

[trig_sig_swr, trig_t] = mtrig_lfp(data,testch,ripples.ripple_troughs_min);
trig_sig_swr = mean(trig_sig_swr,3);

swr_amp = []; for c=1:size(trig_sig_swr,1); swr_amp(c,:) = abs(hilbert(filter_lfp(trig_sig_swr(c,:),1000,[100 250]))); end;
swr_amp1 = mean(swr_amp(:,495:505),2);

[~,idx]=max(smoothn(swr_amp1,1));
pyr_layer = testch(idx);