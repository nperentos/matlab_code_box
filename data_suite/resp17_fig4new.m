%% Gamma example OB and mPFC PAC
%fn = 'pfc02_day1_homecage';
%fn = 'hf04_P4_mpfc_2900_L1_ca1_3100';
%fn = 'hfh03_P4_dca1_2_2mm_M11_mpfc_1_9mm';
fn = 'hf03_P4_v1_ca1_1500_M12_mPFC_2000';

fn = fn_from_fn(fn);
data = load_data(fn);

mpfc = getmd(data,data.channels.mpfc(end));
resp = getmd(data,data.channels.resp(1));
mpfcpac = phase_amp_coupling(resp,mpfc,'plot',0,'nShuffles',0,'phasefreqs',[1 6]);
ob = getmd(data,data.channels.ob(1));
obpac = phase_amp_coupling(resp,ob,'plot',0,'nShuffles',0,'phasefreqs',[1 6]);

fig; 
sp;
imagesc(obpac.ph_f,obpac.amp_f,obpac.MI); axis xy; colorbar
ylabel('Amplitude frequency (Hz)');
xlabel('Phase frequency (Hz)');
colorbar_label('Modulation Index')
set(gca,'XTick',[2:2:6]);
title('OB')
sp;
imagesc(obpac.ph_f,obpac.amp_f,mpfcpac.MI); axis xy; colorbar
ylabel('Amplitude frequency (Hz)');
xlabel('Phase frequency (Hz)');
colorbar_label('Modulation Index')
set(gca,'XTick',[2:2:6]);
title('mPFC')
clim_all(get(gca,'clim'));

fixfig([resultspath 'example_mPFC_OB_PAC'])

%% Gamma burst locking - all

%% mPFC gamma CSD - all
files = {'pfc01_sleep1',...
    
'pfc02_day1_homecage',...

'hfh01_M11_mpfc_1_5mm',...

%'hfh03_P4_dca1_1_3mm_M11_mpfc_1_6mm',...
'hfh03_P4_dca1_2_2mm_M11_mpfc_1_9mm',...
%'hfh03_P4_dca1_2_2mm_M11_mpfc_1_9mm2',...

%'hfh03_P9_CA1_M8_mPFC',...
%'hfh03_P9_V1_M8_mPFC',...

'hf03_P4_v1_ca1_1500_M12_mPFC_2000',...
%'hf03_P4_v1_ca1_2450_M12_mPFC_2000',...

'hf04_P4_ca11_2500_M12_mpfc_2000',...
%'hf04_P4_v1_1500_M12_mpfc_1500',...

%'hf04_P4_v1_ca1_1600_M12_mpfc_1600',...
'hf04_P4_v1_ca1_2300_M12_mpfc_2000',...

'hf05_P4_v1_ca1_2000_M12_mpfc_2150',...
%'hf05_P4_v1_ca1_2000_M12_mpfc_1500',...
%'hf05_P4_v1_ca1_2000_M12_mpfc_1800',...

%'hf05_P4_ca11_1500_M12_mpfc_1500',...
'hf05_P4_ca11_2500_M12_mpfc_2500'
};
files = fn_from_fn(files);

csd_all = {};
for f=1:length(files);
    f
    fn = files{f};
    data = load_data(fn);
    %resp = getmd(data,data.channels.resp(1));
    
    if isfield(data.channels,'ob');
        ob = getmd(data,data.channels.ob(1));
        tmp = find_ripples(ob,'ripplefreq',[60 100],'plot',0);
    else
        mpfc = getmd(data,data.channels.mpfc(end));
        tmp = find_ripples(mpfc,'ripplefreq',[60 100],'plot',0);
    end
    
    gammapower = tmp.ripple_amp_norm;
    gammapeaks = tmp.ripple_troughs_min;
    gammapeaks = gammapeaks(gammapower>3);
    
    [trig_sig, trig_t] = mtrig_filt(data,data.channels.mpfc,gammapeaks,[60 100],0.1);
    
    pos = oemaps.pos.M11;
    [csd, z] = inverseCSD(mean(trig_sig,3),pos,'step',1000,1);
    csd_all{f} = csd;
end

idx = [2:5 7 9];
tmp = cell2mat3(csd_all);
tmp1 = squeeze(mean(tmp(100:101,:,idx)));
tmp2 = squeeze(mean(tmp(:,:,idx)));
fig; shadedErrorBar(1:size(tmp1,1),zscore(tmp1)',{@mean,@sem});
textbp(['n = ' num2str(length(idx))])
ylim([-2.5 2.5])
fixfig([resultspath 'gamma_mPFC_CSD_quant'])

%% mPFC gamma CSD - example
for f=3%[2:5 7 9]
    fn = files{f};
    data = load_data(fn);
    %resp = getmd(data,data.channels.resp(1));
    
    freq = [60 100];
    if isfield(data.channels,'ob');
        ob = getmd(data,data.channels.ob(1));
        tmp = find_ripples(ob,'ripplefreq',freq,'plot',0);
    else
        mpfc = getmd(data,data.channels.mpfc(end));
        tmp = find_ripples(mpfc,'ripplefreq',freq,'plot',0);
    end
        
    gammapower = tmp.ripple_amp_norm;
    gammapeaks = tmp.ripple_troughs_min;
    gammapeaks = gammapeaks(gammapower>3);
    
    
    %gammapeaks = spikes_in_periods(gammapeaks,data.states.quiet*1000);

    [trig_sig, trig_t] = mtrig_filt(data,data.channels.mpfc,gammapeaks,freq,0.1);

    pos = oemaps.pos.M11;

    lfp = mean(trig_sig,3);
    lfp = lfp(2:end-1,:);
    pos = pos(2:end-1);
    [csd, z] = inverseCSD(lfp,pos,'spline',1000,1);
    fig; plot_csd(csd',lfp,trig_t,pos);
    fixfig([resultspath 'gamma_mPFC_CSD_example_' data.info.sessionname])
end

% Testing the normal CSD
%step=2;
%chans=[step+1:size(tmp,1)-step];
%csd = lfp(chans+step,:) - 2*lfp(chans,:) + lfp(chans-step,:);
%csd = csd/(step^2);
%csd = smoothn(csd,1)';

%% PAC example all
parfor f=1:length(files);
    fn = files{f};
    data = load_data(fn);
    mpfc = getmd(data,data.channels.mpfc(end));
    resp = getmd(data,data.channels.resp(1));
    mpfcpac = phase_amp_coupling(resp,mpfc,'plot',1,'nShuffles',0,'phasefreqs',[1 6],'uniformphase',1);
    close
    fixfig([resultspath 'gamma_mPFC_PAC_example_' data.info.sessionname])
end

%% Cumulative phase locking
% Load units
tmp1 = load([resultspath 'matfiles/' 'laminar_phaselocking1'],'unitsall');
tmp2 = load([resultspath 'matfiles/' 'depth_phaselocking1'],'unitsall');
tmp3 = load([resultspath 'matfiles/' 'other_phaselocking1'],'unitsall');
%tmp2.unitsall.depth = []; tmp3.unitsall.depth = [];
tmp1.unitsall.depth = NaN*zeros(size(tmp1.unitsall.id,1),1);
unitsall = cat(1,tmp1.unitsall,tmp2.unitsall,tmp3.unitsall);
clear tmp1 tmp2 tmp3
for c=1:length(unitsall.id); unitsall.uniqueid(c) = c; end;

%% Cumulative phase locking - local channel
freqs = [60 100];

sessions = unique(unitsall.filename);
gammaph = {};
gammaphun = {};
uniqueidx = {};

for s=1:length(sessions)
    s
    tic;
    units = unitsall(strcmp(unitsall.filename,sessions{s}),:);
    data = load_data(fn_from_fn(sessions{s},'/storage2/nikolas/data/Recordings/'));
    
    if isfield(data.channels,'ob');
        %sig = getmd(data,data.channels.ob(1));
        tmp = find_ripples(sig,'ripplefreq',freqs,'plot',0);
    else
        %sig = getmd(data,data.channels.mpfc(end));
        tmp = find_ripples(sig,'ripplefreq',freqs,'plot',0);
    end
    gammapower = tmp.ripple_amp_norm;
    gammapeaks = tmp.ripple_troughs_min;
    %gammapeaks = gammapeaks(gammapower>3);

    
    tmp1 = {};
    tmp2 = {};
    tmp3 = {};
    for c=1:length(units.id);
        sig = getmd(data,units.channel(c));
        sig = angle(hilbert(filter_lfp(sig,1000,freqs)));
        sig1 = MakeUniformDistr(sig);
        spk = round(units.spikes{c}/30);
        spk = spikes_in_periods(spk,[gammapeaks'-50 gammapeaks'+50]);
        tmp1{c} = sig(spk);
        tmp2{c} = sig1(spk);
        tmp3{c} = find(unitsall.uniqueid==units.uniqueid(c));        
    end
    gammaph{s} = tmp1;
    gammaphun{s} = tmp2;
    uniqueidx{s} = tmp3;
    toc;
end

% reorder and add to unitsall
[~,idx]=sort(cell2mat([uniqueidx{:}])');
tmp1 = [gammaph{:}]'; tmp1 = tmp1(idx);
tmp2 = [gammaphun{:}]'; tmp2 = tmp2(idx);
unitsall.gammaph = tmp1;
unitsall.gammaphun = tmp2;

%% Cumulative phase locking - reference channel
freqs = [60 100];
unitsall.gammaph = cell(size(unitsall.id,1),1);
unitsall.gammaphun = cell(size(unitsall.id,1),1);

sessions = unique(unitsall.filename);
gammaph = {};
gammaphun = {};
uniqueidx = {};

parfor s=1:length(sessions)
    s
    tic;
    units = unitsall(strcmp(unitsall.filename,sessions{s}),:);
    data = load_data(fn_from_fn(sessions{s},'/storage2/nikolas/data/Recordings/'));
    
    if isfield(data.channels,'ob');
        sig = getmd(data,data.channels.ob(1));
        tmp = find_ripples(sig,'ripplefreq',freqs,'plot',0);
    else
        sig = getmd(data,data.channels.mpfc(end));
        tmp = find_ripples(sig,'ripplefreq',freqs,'plot',0);
    end
    gammapower = tmp.ripple_amp_norm;
    gammapeaks = tmp.ripple_troughs_min;
    %gammapeaks = gammapeaks(gammapower>3);

    sig = angle(hilbert(filter_lfp(sig,1000,freqs)));
    sig1 = MakeUniformDistr(sig);
    tmp1 = {};
    tmp2 = {};
    tmp3 = {};
    for c=1:length(units.id);         
        spk = round(units.spikes{c}/30);
        spk = spikes_in_periods(spk,[gammapeaks'-50 gammapeaks'+50]);
        tmp1{c} = sig(spk);
        tmp2{c} = sig1(spk);
        tmp3{c} = find(unitsall.uniqueid==units.uniqueid(c));        
    end
    gammaph{s} = tmp1;
    gammaphun{s} = tmp2;
    uniqueidx{s} = tmp3;
    toc;
end

% reorder and add to unitsall
[~,idx]=sort(cell2mat([uniqueidx{:}])');
tmp1 = [gammaph{:}]'; tmp1 = tmp1(idx);
tmp2 = [gammaphun{:}]'; tmp2 = tmp2(idx);
unitsall.gammaph = tmp1;
unitsall.gammaphun = tmp2;

%% Cumulative phase locking to gamma - plots
logz = {};
mean_ph = {};
for c=1:2;
    idx = unitsall.class==c;
    tmp1 = unitsall.gammaphun(idx); 
    tmp2 = unitsall.gammaph(idx); 
    idx = cellfun(@length,tmp1)>100;
    tmp1 = tmp1(idx);
    tmp2 = tmp2(idx);
    tmp1 = cellfun(@(x) log((abs(mean(exp(1i*x)))^2)*length(x)), tmp1);
    mean_ph{c} = cellfun(@(x) circ_mean(x(:)),tmp2(tmp1>1));
    logz{c} = tmp1;
end

fig; 
sp;
rose(mean_ph{1})
hold on;
rose(mean_ph{2})
sp;
[f,x]=ecdf(logz{1},'function','cdf'); 
plot(x,100*(1-f),'k')
hold on;
[f,x]=ecdf(logz{2},'function','cdf'); 
plot(x,100*(1-f),'r')
xlim([0 max(get(gca,'xlim'))])
legend({'PN','IN'});
textbp(['PN n=' num2str(length(logz{1}))])
textbp(['IN n=' num2str(length(logz{2}))])
sig_levels = log(-log([0.05 0.01 0.001]));
hold on;
verticalline(sig_levels(1),'--k')
fixfig([resultspath 'gamma_spike_phaselocking_mpfc_all'])

%% Example neurons
idx = unitsall.class==1 & cellfun(@length,unitsall.gammaph)>200;
tmp1 = unitsall.gammaphun(idx);
tmp1 = cellfun(@(x) log((abs(mean(exp(1i*x)))^2)*length(x)), tmp1);
tmp2 = unitsall.gammaph(idx);
templates = unitsall.template(idx);
[tmp1,idx1] = sort(tmp1);
tmp2 = tmp2(idx1);
templates = templates(idx1);

%% Example gamma phase locking
fig;
sp(1,2);
circ_hist(tmp2{end},18,2)
sp;
jplot(1:61,templates{end-10},'k')
fixfig([resultspath 'example_gamma_unit_phase_locking'])

%% Gamma - spike xcorr
freqs = [60 100];

sessions = unique(unitsall.filename);
uniqueids = [];
gspikexcs = [];
for s=1:length(sessions)
    s
    tic;
    units = unitsall(strcmp(unitsall.filename,sessions{s}),:);
    data = load_data(fn_from_fn(sessions{s},'/storage2/nikolas/data/Recordings/'));
    
    if isfield(data.channels,'ob');
        sig = getmd(data,data.channels.ob(1));
        tmp = find_ripples(sig,'ripplefreq',freqs,'plot',0);
    else
        sig = getmd(data,data.channels.mpfc(end));
        tmp = find_ripples(sig,'ripplefreq',freqs,'plot',0);
    end   
    gammapower = tmp.ripple_amp_norm;
    gammapeaks = tmp.ripple_troughs_min;
    %gammapeaks = gammapeaks(gammapower>3);

    tmp = {};
    tmp1 = {};
    tic;
    parfor c=1:length(units.id);                 
        spk = round(units.spikes{c}/30);
        tmp{c} = run_xcorr(gammapeaks,spk,0.005,0.5);
        tmp1{c} = find(unitsall.uniqueid==units.uniqueid(c));  
    end
    tmp = cell2mat(tmp)';
    tmp1 = cell2mat(tmp1)';
    toc;
    uniqueids = cat(1,uniqueids,tmp1);
    gspikexcs = cat(1,gspikexcs,tmp);
end

[~,idx] = sort(uniqueids);
gspikexcs = gspikexcs(idx,:);

%% Gamma trig firing - cumulative
fig;
sp(1,2);
for c=1:2;
    idx = unitsall.class == c;    
    tmp = gspikexcs(idx,:);
    %tmp = zscore_partial(tmp,[1:80 120:201]);
    tmp = zscore(tmp,[],2);
    %tmp = max(tmp(:,98:103),[],2);
    [tmp,tmpidx] = max(tmp(:,96:105),[],2);
    %tmp = mean(tmp(:,96:105),2);
    [f,x]=ecdf(tmp,'function','cdf'); 
    plot(x,100*(1-f))
    hold on;
end
xlim([-1 8])
legend({'PN','IN'})
xlabel('Normalized firing rate (sd)')
ylabel('Cells (%)');
verticalline(1.96,'--k');
textbp(['PN n = ' num2str(sum(unitsall.class==1))]);
textbp(['IN n = ' num2str(sum(unitsall.class==2))]);
sp;
boxplot((tmpidx+95-101)*2);
ylabel('Lag (ms)');
fixfig([resultspath 'mPFC_gamma_triggered_spiking'])

%% Gamma trig psth - example and all
idx = unitsall.class == 1;   
tmp = gspikexcs(idx,:);
tmp1 = zscore(tmp,[],2);
tmp1 = max(tmp1(:,96:105),[],2);
[~,idx1] = sort(tmp1);
tmp = tmp(idx1,:);
fig; 
sp;
bar(linspace(-500,500,201),smoothn(tmp(end-2,:),1),'k'); colorbar
xlim([-200 200])
ylabel('Corr.Coef.')
sp;
tmp = zscore(gspikexcs,[],2);
tmp1 = max(tmp(:,96:105),[],2);
[~,idx1] = sort(tmp1,1,'descend');
imagesc(linspace(-500,500,201),1:size(gspikexcs,1),smoothn(tmp(idx1,:),1)); colorbar;
xlim([-200 200])
colormap(linspecer)
clim([-3 3])
xlabel('Time from gamma peak (ms)')
ylabel('Cells (#)')
fixfig([resultspath 'mPFC_gamma_triggered_psth_example'])

%% Logz in depth
logz = {};
mean_ph = {};
depth = {};
for c=1:2;
    idx = unitsall.class==c & ~isnan(unitsall.depth);
    tmp1 = unitsall.gammaphun(idx); 
    tmp2 = unitsall.gammaph(idx); 
    depthtmp = unitsall.depth(idx);
    idx = cellfun(@length,tmp1)>100;
    tmp1 = tmp1(idx);
    tmp2 = tmp2(idx);
    depthtmp = depthtmp(idx);
    tmp1 = cellfun(@(x) log((abs(mean(exp(1i*x)))^2)*length(x)), tmp1);
    mean_ph{c} = cellfun(@(x) circ_mean(x(:)),tmp2(tmp1>1));
    logz{c} = tmp1;
    depth{c} = depthtmp;
end

%fig;jplot(depth{1},logz{1},'.')

depthbins = [500:250:3800];
[~,idx]=spikes_in_periods(depth{1},depthbins,1);
tmp = cellfun(@(x) logz{1}(x),idx,'un',0);

fig; jplot(depthbins(1:end-1),tmp)

%% Gamma burst locking - all
files = {
'ecog01_homecage'    
'ras08_post_novelctx_sleep2'
'ras09_baseline_sleep'
'ras10_baseline_sleep'
'chr02_homecage'
'pfc01_sleep1'
'pfc02_day1_homecage'
'hfh02_P4_mpfc_2_4mm'
'hfh03_P4_dca1_2_2mm_M11_mpfc_1_9mm2'
'hfh04_P7_dca1_2200_P4_mpfc_1800'
'hf01_L1_mPFC'
'hf02_P4_mPFC_left'
'hf03_P4_v1_ca1_1500_M12_mPFC_2000'
'hf04_P4_v1_1500_M12_mpfc_1500'
%'hf05_P4_ca11_2500_M12_mpfc_2500'
'hf05_P4_ca11_1500_M12_mpfc_1500'
%'ob01_P7_mpfc_photometry_1600'
'ob02_P4_P2_mPFC_S1_dCA1pyr'
};

files = fn_from_fn(files);

gammaburst_ph = {};

parfor f=1:length(files);
    f
    fn = files{f};
    data = load_data(fn);
    resp = angle(hilbert(getmd(data,data.channels.resp(1))));
    if strcmp(data.info.sessionname,'hf05');
        resp = angle(hilbert(-getmd(data,data.channels.ob(1))));
    end
    
    mpfc = getmd(data,data.channels.mpfc(end));
    tmp = find_ripples(mpfc,'ripplefreq',[60 100],'plot',0);
    
    gammapower = tmp.ripple_amp_norm;
    gammapeaks = tmp.ripple_troughs_min;
    gammapeaks = gammapeaks(gammapower>3);
    
    gammaburst_ph{f} = resp(gammapeaks);
    resp  = MakeUniformDistr(resp);
    gammaburst_ph_unif{f} = resp(gammapeaks);
end

gammalogz = cellfun(@(x) log((abs(mean(exp(1i*x)))^2)*length(x)), gammaburst_ph_unif);
gammaph = cellfun(@(x) circ_mean(x(:)),gammaburst_ph);

fig
sp;
rose(gammaburst_ph{1})
sp;
polar(gammaph,gammalogz,'.r'); 
hold on;
[xx,yy] = pol2cart(circ_mean(gammaph),mean(gammalogz));
compass(xx,yy,'r')
textbp(['n = ' num2str(length(gammaph))])
fixfig([resultspath 'gamma_burst_locking_all']);

%% Gamma - mPFC - OB phase relationship
files = {
'ecog01_homecage' 
'pfc01_sleep1'
'pfc02_day1_homecage'
'fbr03_homecage'
'hf03_P4_v1_ca1_1500_M12_mPFC_2000'
'hf04_P4_v1_1500_M12_mpfc_1500'
%'hf05_P4_ca11_2500_M12_mpfc_2500'
'hf05_P4_ca11_1500_M12_mpfc_1500'
};
files = fn_from_fn(files);

% hasob = [];
% for f=1:length(files);
%     fn = files{f};
%     data = load_data(fn);
%     
%     if isfield(data.channels,'ob'); 
%         hasob(f)=1;
%     end
% end

phase_diff = {};
phasexc = {};
gammaxc = {};

parfor f=1:length(files);
    tic;
    f
    fn = files{f};
    data = load_data(fn);
    
%     if isfield(data.channels,'ob'); 
%         sig1 = getmd(data,data.channels.ob(1));
%     else    
%         sig1 = -getmd(data,data.channels.resp(1));
%     end;
    
    sig1 = getmd(data,data.channels.ob(1));
    %sig2 = getmd(data,data.channels.mpfc(round(end/2)));
    sig2 = getmd(data,data.channels.mpfc(1));
    tmp = find_ripples(sig2,'ripplefreq',[60 100],'plot',0);
    
    sig1 = hilbert(filter_lfp(sig1,1000,[60 100]));
    sig2 = hilbert(filter_lfp(sig2,1000,[60 100]));
    
    gammapower = tmp.ripple_amp_norm;
    gammapeaks = tmp.ripple_troughs_min;
    gammapeaks = gammapeaks(gammapower>3);
    %idx = spikes_in_periods(1:length(sig1),[tmp.ripple_onset ; tmp.ripple_offset]');
    tmptmp = [tmp.ripple_onset ; tmp.ripple_offset]'; idx = []; for k=1:size(tmptmp,1); idx = cat(2,idx,tmptmp(k,1):tmptmp(k,2)); end;
    tmp=unwrap(angle(sig1)) - unwrap(angle(sig2));    
    phase_diff{f} = tmp(idx);
    phasexc{f} = xcorr(unwrap(angle(sig1)),unwrap(angle(sig2)),100,'coeff');
    gammaxc{f} = xcorr(abs(sig1),abs(sig2),100,'coeff');   
    
    toc;
end

%% Gamma burst - mPFC - OB xcorr
gammaxc1 = {};

parfor f=1:length(files);
    tic;
    f
    fn = files{f};
    data = load_data(fn);
    
    if isfield(data.channels,'ob'); 
        sig1 = getmd(data,data.channels.ob(1));
    else    
        sig1 = -getmd(data,data.channels.resp(1));
    end;
    sig2 = getmd(data,data.channels.mpfc(1));
    tmp1 = find_ripples(sig1,'ripplefreq',[80 100],'plot',0);
    tmp2 = find_ripples(sig2,'ripplefreq',[80 100],'plot',0);
    
    gammaxc1{f} = run_xcorr(tmp1.ripple_t,tmp2.ripple_t,0.001,0.1);
    toc;
end

%% Gamma mPFC - OB plots
gammalogz = cellfun(@(x) log((abs(mean(exp(1i*x)))^2)*length(x)), phase_diff);
gammaph = cellfun(@(x) circ_mean(x(:)),phase_diff);
% fix the ones with wrong polarity
gammaph(gammaph>pi/2)=gammaph(gammaph>pi/2)-pi;
gammaph(gammaph<-pi/2)=gammaph(gammaph<-pi/2)+pi;
%fig; polar(gammaph(hasob),gammalogz(hasob),'.k');
fig; 
sp(1,2);
rose(phase_diff{3})
sp;
polar(gammaph,gammalogz,'ok');
hold on;
[xx,yy] = pol2cart(circ_mean(gammaph),mean(gammalogz));
compass(xx,yy,'r')
textbp(['n = ' num2str(length(gammaph))])
fixfig([resultspath 'gamma_mPFC_OB_phase_relationship'])

xclag = [];
for c=1:length(gammaxc1);
    [~,idx] = max(smoothn(gammaxc1{c},1));
    xclag(c) = idx;
end

%% Gamma - mPFC - OB granger
gammagranger = {};

parfor f=1:length(files);
    tic;
    f
    fn = files{f};
    data = load_data(fn);
    
    sig1 = getmd(data,data.channels.ob(1));
    sig2 = getmd(data,data.channels.mpfc(1));
    gammagranger{f} = run_granger([sig1 ; sig2],'targetSR',1000);
    toc;
end

fig; for c=1:length(gammagranger); jplot(gammagranger{c}.freqs1,gammagranger{c}.GC); waitforbuttonpress; end;

%% Gamma PAC post meth
animals = fieldnames(mydataset.homecage_meth);
% Post-meth
mpfcpacmeth = {};
obpacmeth = {};
parfor f=2:length(animals)
    data =load_data(mydataset.homecage_meth.(animals{f}).fn);
    resp = getmd(data,{'resp',1});
    mpfc = getmd(data,{'mpfc',1});
    mpfcpacmeth{f} = phase_amp_coupling(resp,mpfc,'plot',0,'nShuffles',0,'phasefreqs',[1 6]);
    if isfield(data.channels,'ob');
        ob = getmd(data,{'ob',1});
        obpacmeth{f} = phase_amp_coupling(resp,ob,'plot',0,'nShuffles',0,'phasefreqs',[1 6]);
    end
end

% Pre-meth
mpfcpacmeth = {};
obpacmeth = {};
parfor f=1:length(animals)
    data =load_data(mydataset.homecage.(animals{f}).fn);
    resp = getmd(data,{'resp',1});
    mpfc = getmd(data,{'mpfc',1});
    mpfcpacpremeth{f} = phase_amp_coupling(resp,mpfc,'plot',0,'nShuffles',0,'phasefreqs',[1 6]);
    if isfield(data.channels,'ob');
        ob = getmd(data,{'ob',1});
        obpacpremeth{f} = phase_amp_coupling(resp,ob,'plot',0,'nShuffles',0,'phasefreqs',[1 6]);
    end
end

%% Gamma PAC pre vs post meth - quantification
ph_f = mpfcpacpremeth{1}.ph_f;
amp_f = mpfcpacpremeth{1}.amp_f;
[~,fidx1] = spikes_in_periods(amp_f,[80 100]);
[~,fidx2] = spikes_in_periods(ph_f,[2 4]);
tmp = [];
for c=1:length(mpfcpacmeth)
    %tmp(:,:,c) = mpfcpacpremeth{c}.MI  - mpfcpacmeth{c}.MI;
    tmp1 = mpfcpacpremeth{c}.MI;
    tmp2 = mpfcpacmeth{c}.MI;
    fig; sp(1,2); imagesc(ph_f,amp_f,tmp1); axis xy; colorbar;
    sp; imagesc(ph_f,amp_f,tmp2); axis xy; colorbar;
    tmp1 = tmp1(fidx1,fidx2);
    tmp1 = mean(tmp1(:));
    tmp2 = tmp2(fidx1,fidx2);
    tmp2 = mean(tmp2(:));
    %tmp(c,:) = [max(tmp1(:)) max(tmp2(:))];
    tmp(c,:) = [tmp1 tmp2];
    waitforbuttonpress;
end

%%
idx = [1 2 3 4 5 7 8];
p = signrank(tmp(idx,1),tmp(idx,2));
fig; boxplot(tmp(idx,:),{'Pre-ablation','Post-ablation'},'colors','kr'); sigstar([1 2],p);
nlabel(length(idx));
ylabel('Modulation index');
yticks([0:2:4]*1e-3)
fixfig([resultspath 'mpfc_gamma_pac_pre_post_meth'])

%% Gamma PAC post meth - plot all examples
fig; 
for c=1:length(mpfcpacmeth); 
    if isempty(mpfcpacmeth{c}); continue; end; 
    imagesc(mpfcpacmeth{c}.ph_f,mpfcpacmeth{c}.amp_f,mpfcpacmeth{c}.MI); axis xy; colorbar;
    %waitforbuttonpress; 
    fixfig([resultspath 'example_mPFC_PAC_' animals{c}])
end;

fig; 
for c=1:length(obpacmeth); 
    if isempty(obpacmeth{c}); continue; end; 
    imagesc(obpacmeth{c}.ph_f,obpacmeth{c}.amp_f,obpacmeth{c}.MI); axis xy; colorbar;
    %waitforbuttonpress; 
    fixfig([resultspath 'example_OB_PAC_' animals{c}])
end;

%% Gamma PAC - headfixed - plot example
fn = 'hf03_P4_mpfc_2500_L1_ca1_15deg_2000_thermistor_postmeth';
fn = 'hf04_P4_mpfc_2500_L1_ca1_2500_15deg_post_meth';
fn = 'hf05_P4_mpfc_2500_L1_ca1_2500_15deg_post_meth_thermistor_long';
fn = 'hf05_P4_mpfc_2500_L1_ca1_2500_15deg_post_meth';
fn = fn_from_fn(fn);
data = load_data(fn);

mpfc = getmd(data,data.channels.mpfc(round(end/2)));
resp = getmd(data,data.channels.resp(1));
%resp = getmd(data,data.channels.thermistor(1));
mpfcpac = phase_amp_coupling(resp,mpfc,'plot',0,'nShuffles',0,'phasefreqs',[1 6]);
ob = getmd(data,data.channels.ob(1));
obpac = phase_amp_coupling(resp,ob,'plot',0,'nShuffles',0,'phasefreqs',[1 6]);

fig; 
sp;
imagesc(obpac.ph_f,obpac.amp_f,obpac.MI); axis xy; colorbar
ylabel('Amplitude frequency (Hz)');
xlabel('Phase frequency (Hz)');
colorbar_label('Modulation Index')
set(gca,'XTick',[2:2:6]);
title('OB')
sp;
imagesc(obpac.ph_f,obpac.amp_f,mpfcpac.MI); axis xy; colorbar
ylabel('Amplitude frequency (Hz)');
xlabel('Phase frequency (Hz)');
colorbar_label('Modulation Index')
set(gca,'XTick',[2:2:6]);
title('mPFC')
%clim_all(get(gca,'clim'));

fixfig([resultspath 'example_mPFC_OB_PAC_postmeth4'])
