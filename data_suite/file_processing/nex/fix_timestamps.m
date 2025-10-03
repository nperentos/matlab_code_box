% Prepare a nex file for importing in Matlab

% This function takes as input a nexfile structure (as read by the
% ReadNexFile function provided by Plexon and returns the same structure.

% The LFPs are now shorter and have the same start timestamp for all the
% channels (the latest).
% Additionally, the spike timestampsm waveform timestamps and event timestamps
% are changed, so that they can be imported in Matlab.

% For example, if a spike timestamp = 1.5000 s and the LFP start timestamp
% is 0.0010 s, when they are imported in Matlab, the spike timestamp must
% be converted to 1.4990 s, since the first LFP point corresponds now to 0.

% *** This should be run on all the nexfiles after reading them and before
% importing them for further processing. ***
% Note : After this process, the data are suitable for processing in
% Matlab, but not with Neuroexplorer anymore.
% 
% Author : Nikolas Karalis
% Date : July 2013

function nexfile = fix_timestamps(nexfile)

% Fix timestamps
timestamps = zeros(length(nexfile.contvars),1);
for c=1:length(nexfile.contvars)
    timestamps(c) = nexfile.contvars{c}.timestamps;
end

max_timestamp=max(timestamps);
min_timestamp=min(timestamps);

if max_timestamp~=min_timestamp;
    disp('Fixing timestamps.');
    for c=1:length(timestamps);
        if timestamps(c)<max_timestamp;
            disp(num2str(c));
            d = int32((max_timestamp-timestamps(c))*nexfile.contvars{c}.ADFrequency);
            nexfile.contvars{c}.data(1:d) = [];
            nexfile.contvars{c}.timestamps = max_timestamp;          
        end;
    end;
end;

% Fix lengths
lengths = zeros(length(nexfile.contvars),1);
for c=1:length(nexfile.contvars)
    lengths(c) = length(nexfile.contvars{c}.data);
end

max_length=max(lengths);
min_length=min(lengths);

if max_length~=min_length;
    disp('Fixing lengths.');
    for c=1:length(lengths);
        if lengths(c)>min_length;
            disp(num2str(c));            
            nexfile.contvars{c}.data(min_length+1:end) = [];
        end;
    end;
end;

% Fix spikes and waveforms
for c=1:length(nexfile.neurons);
    ch = str2num(nexfile.neurons{c}.name(4:6));    
    spikes = nexfile.neurons{c}.timestamps-nexfile.contvars{ch}.timestamps;
    % To make sure that we don't keep any spikes with negative timestamp
    nexfile.neurons{c}.timestamps = spikes(spikes>0);
end;

for c=1:length(nexfile.waves);
    ch = str2num(nexfile.waves{c}.name(4:6));     
    spikes = nexfile.waves{c}.timestamps-nexfile.contvars{ch}.timestamps;
    % To make sure that we don't keep any spikes with negative timestamp
    nexfile.waves{c}.timestamps = spikes(spikes>0);
end;

% Fix events
for c=1:length(nexfile.events);
    nexfile.events{c}.timestamps = nexfile.events{c}.timestamps-nexfile.contvars{1}.timestamps;   
end;


