% To improve
function isi_histogram(spiketrain)
isi = diff(spiketrain);
bins = min(isi):0.01:max(isi)+0.01;
plot(bins,histc(isi, bins),'.');
xlim([floor(min(isi)),ceil(max(isi))]);
