function h=calculate_phase_coherence(lfp1,lfp2,samplingrate,frequencyrange, plot)

if nargin < 5; plot=0; end;

phase_diff=extract_lfp_phase(filter_lfp(lfp1,samplingrate,frequencyrange) -  extract_lfp_phase(filter_lfp(lfp2,samplingrate,frequencyrange)));
h=hist(phase_diff,36);
if plot==1;
    plot_lfp(filter_lfp(lfp1,samplingrate,frequencyrange),samplingrate);
    hold on;
    plot_lfp(filter_lfp(lfp2,samplingrate,frequencyrange),samplingrate,'color','r')
    figure; hist(phase_diff,36);
end;