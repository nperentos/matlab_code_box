function [Z, P, spike_phases,zvalues, maxlagphases] = phase_locking(spikes,lfp,frequencyrange,samplingrate,plots,offsetcontrol, statmode, shufflecontrol)

if isempty(spikes); Z=NaN; P=NaN; spike_phases =[]; zvalues=[]; maxlagphases = []; return; end;
if nargin<8 || isempty(shufflecontrol); shufflecontrol = 0; end;
if nargin<7 || isempty(statmode); statmode = 'rayleigh'; end;
if nargin<6 || isempty(offsetcontrol); offsetcontrol=0; zvalues=NaN; end;
if nargin<5 || isempty(plots); plots = 0; end;
if isempty(frequencyrange); 
    peak_freq = find_peak_freq(lfp,samplingrate,[]);
    frequencyrange = [int32(peak_freq)-2 int32(peak_freq)-2];
end;

lfp = filter_lfp(lfp,samplingrate,frequencyrange);
lfp = extract_lfp_phase(lfp);
lfp_phases = lfp;

spike_phases = extract_spike_phase(spikes,lfp_phases,samplingrate, 1);
if strcmp(statmode, 'rayleigh')
    [P, Z]=circ_rtest(spike_phases);
elseif strcmp(statmode, 'rao')
    [P,Z, Zcritical] = circ_raotest(spike_phases);
elseif strcmp(statmode, 'omnibus')
    [P,m] = circ_otest(spike_phases);
    Z = 0;
end;
% To make the figure as in Figure3A,B in Siapas and Wilson 2005, Neuron
if offsetcontrol==1;
    k=1; % counter
    lags =(-0.7:0.01:0.7); 
    zvalues = zeros(length(lags),1);
    for c=lags       
        [p, z]=circ_rtest(extract_spike_phase(spikes-c,lfp_phases,samplingrate, 1));
        zvalues(k,1)=z;
        k=k+1;
    end;
    [maxz,maxidx]=max(zvalues);
    % This is to extract the spike phases at the lag that gives the maximum
    % phase locking. As used in methods of Siggurdson et al., Nature, 2010
    maxlagphases=extract_spike_phase(spikes-lags(maxidx),lfp_phases,samplingrate, 1);
end;

if shufflecontrol==1;
    surrogate = surrogate_spiketrains(spikes,1000,'jitter',5);
    Zvals = zeros(size(surrogate,1),1);
    for c=1:size(surrogate,1);
        temp_phases = extract_spike_phase(surrogate(c,:),lfp_phases,samplingrate, 1);
        [Ptemp, Ztemp]=circ_rtest(temp_phases);
        Zvals(c)=Ztemp;
    end;    
    if Z<prctile(Zvals,95);
        Z=-0.1;
        P=1;
    end;
end;

if plots==1;
    figure;
    subplot(2,1,1)
    circ_hist(spike_phases,18,2);
    subplot(2,1,2)
    plot(-700:10:700,zvalues);
    sig_level = -log(0.05/141);
    hold on; line([0 0],[min(get(gca,'ylim')) max(get(gca,'ylim'))],'LineStyle','--','Color','r')
    xlim([-700,700])
    hold on; line([min(get(gca,'xlim')) max(get(gca,'xlim'))],[sig_level sig_level],'LineStyle','--','Color','r')
    set(gca,'XTick',[-700,0,700])
    set(gca,'TickDir','out'); box off;
end;

