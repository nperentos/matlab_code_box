% Splits the spike events in a window around the events, with the real
% times and returns a cell array. If centered flag is used, then the
% relative timing with the event at 0 is used.
% Author : Nikolas Karalis

function spikes = split_spikes_around_event(spiketrain, events, window,centered)
spikes = {};
if nargin<4
    centered = 0;
end;

if centered == 1
    for t=1:size(events,1)
        spikes{t,1} = events(t);
        spikes{t,2} = events(t)-spiketrain(spiketrain>events(t)-window & spiketrain<events(t)+window);
    end;

else
    for t=1:size(events,1)
    spikes{t,1} = events(t);
    spikes{t,2} = spiketrain(spiketrain>events(t)-window & spiketrain<events(t)+window);
    end;
end;