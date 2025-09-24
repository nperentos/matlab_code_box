%% mPFC P4 diagonal CSD
files = {'hf08_L1_mec_3240_23deg_good'};
files = fn_from_fn(files);

fn = files{1};
data = load_data(fn);

%%
state_detection(fn);

%%
try;
    mpfcchan = data.channels.mec;
catch;
    mpfcchan = data.channels.mec;
end

sig = getmd(data,{'resp',1});
sig = filter_lfp(-sig,1000,[1 6]);
insp = LocalMinima(sig,200); % inspiration
insp = spikes_in_periods(insp,[data.states.sleep ; data.states.quiet]*1000);
insp1 = spikes_in_periods(insp,[data.states.micromotions ; data.states.rem]*1000);
insp = setdiff(insp,insp1);
[trig_sig, trig_t] = mtrig_lfp(data,mpfcchan,insp);

%%
sig = getmd(data,{'mec',16});
sig = filter_lfp(sig,1000,[4 10]);
thpeaks = LocalMinima(-sig,200);
spikes_in_periods(thpeaks,[data.states.active]*1000);
[trig_sig, trig_t] = mtrig_lfp(data,mpfcchan,thpeaks);

%%
pos = oemaps.pos.L1;
tmp = mean(trig_sig,3);
%badch = setdiff(1:32,oemaps.sites.L1);
goodch = oemaps.sites.L1;
tmp = tmp(goodch,:);
pos = pos(goodch);

[csd_mean, z] = inverseCSD(tmp,pos,'spline',200,5);


%tmp(badch,:) = mean([tmp(badch-1,:) ; tmp(badch+1,:)]); % interpolate bad channel

%tic; [csd, z] = trig_csd(trig_sig(oemaps.sites.P4,:,:),pos,'step',1000,2); toc;
%csd_mean = mean(csd,3);

fig; plot_csd(csd_mean',tmp,trig_t,pos); colorbar
%tmp = max(abs(get(gca,'clim'))); clim([-tmp tmp]);