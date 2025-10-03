function isi_time(spiketrain)

isi = diff(spiketrain);
plot(spiketrain(2:end),isi,'.');