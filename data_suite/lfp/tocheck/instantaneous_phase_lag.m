function phase_difference = instantaneous_phase_lag(lfp1,lfp2,samplingfrequency,frequency_band)

filtered1 = filter_lfp(lfp1,samplingfrequency,frequency_band); 
filtered2 = filter_lfp(lfp2,samplingfrequency,frequency_band); 

phase1 = angle(hilbert(filtered1));
phase2 = angle(hilbert(filtered2));

phase_difference = rad2deg(phase1 - phase2,1);

plot_lfp([filtered1;filtered2],500);
figure;
plot(phase_difference,'.');