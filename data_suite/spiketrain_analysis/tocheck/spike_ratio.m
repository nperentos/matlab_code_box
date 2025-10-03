function ratio = spike_ratio(waveforms)

ratio = zeros(1,size(waveforms,2));
for c = 1:size(waveforms,2);
    w = waveforms(:,c);
    [a,idx]= min(w);
    w = w(idx:end);
    b = max(w);
    ratio(c)= abs(b/a);
end