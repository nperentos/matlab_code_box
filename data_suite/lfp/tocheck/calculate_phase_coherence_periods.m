function calculate_phase_coherence_periods(lfp1,lfp2,samplingrate,frequencyrange,periods)
lfp_phase1=extract_lfp_phase(filter_lfp(lfp1,samplingrate, frequencyrange));
lfp_phase2=extract_lfp_phase(filter_lfp(lfp2,samplingrate, frequencyrange));

lfps1 = get_lfp_in_periods(lfp_phase1,samplingrate,periods);
lfps2 = get_lfp_in_periods(lfp_phase2,samplingrate,periods);
total_time = sum(periods(:,2)-periods(:,1));

for c=1:size(lfps1,1);    
    h=hist(lfps1{c}-lfps2{c},72);
    if c==1; H=h; else H = H+h; end;
end;
bar(linspace(-pi,pi,72),H./total_time)


