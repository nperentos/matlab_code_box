function [m, inst_freq] = mean_instantaneous_frequency(spiketrain, window_size, time)
if nargin<3 || isempty(time); time = [0 ceil(max(spiketrain))]; end;
no_windows = ceil((time(2)-time(1))./window_size);
inst_freq = zeros(no_windows,1);
for c=1:no_windows
    window = [time(1)+(c-1)*window_size , time(1)+c*window_size];
    inst_freq(c) = sum(spiketrain>=window(1) & spiketrain<window(2))/window_size;    
end;

m=mean(inst_freq);
