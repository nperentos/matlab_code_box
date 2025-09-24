function lags = dynamic_phase_lag(lfp1,lfp2,samplingfrequency,frequency,windowsize)
lfp1 = window_data(lfp1,samplingfrequency,windowsize, 0, [], 0);
lfp2 = window_data(lfp2,samplingfrequency,windowsize, 0, [], 0);

lags = zeros(size(lfp1,1),1);
for c=1:size(lfp1,1);
    [lags(c,1),x,inst_amp1,inst_amp2]=find_lfp_lag(lfp1(c,:),lfp2(c,:),samplingfrequency, frequency, 0.1);    
end;
plot(lags)