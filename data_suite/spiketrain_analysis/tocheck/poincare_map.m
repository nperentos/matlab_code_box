function poincare_map(spiketrain)

isi_n = diff(spiketrain);

plot(isi_n(1:end-1), isi_n(2:end),'.')

