% This function takes as an input a nex file and the target samplingrate
% as well as the animal and session names and the freezing intervals.
% It returns a matlab structure with the following fields (example) : 
% animal: 'm87'             ---> string (animal name)
% session: 'ext1'           ---> string (session name)
% sr: 1000                  ---> double (sampling rate)
% events: [432x1 double]    ---> n x 1 matrix (tones)
% freeze: [55x2 double]     ---> n x 2 matrix (freezing intervals, 1st column Start time, 2nd column Stop time
% units: {41x2 cell}        ---> n x 2 cell (units : first col. names, 2nd spiketimes)
% unsorted: {32x2 cell}     ---> n x 2 cell (unsorted spikes first col. channel names, 2nd spiketimes)
% mua: {32x1 cell}          ---> n x 1 cell (combined spikes per channel for sorted and unsorted units)
% lfp: [32x1399987 double]  ---> n x m matrix (lfp channels, rows :
% channels, columns time)
% 
% timestamps: [32x1 double] ---> n x 1 matrix (timestamps for the lfp
% channels. Since they have been fixed by the fix_timestamps, they should
% all be the same. They are not useful anymore, since everything has been
% shifted according to the timestamp. Remain here only for reference.
%
% waveforms: {146x3 cell}   ---> n x 3 cell 
% (This cell contains both the waveforms as well as the unit templates. 
% 1st column are the names, 2nd column the timestamps, 
% 3rd column the waveforms. The first half of the rows of the cell are the
% waveforms and the second half are the templates.
% 
% Author : Nikolas Karalis
% Date : July 2013

function data = convert_nex_file(filename, samplingrate, animal, session,freeze)
if nargin<2; samplingrate = 1000; end;
% Read file
nexfile=readNexFile(filename);
disp('File was loaded.')
nexfile = fix_timestamps(nexfile);
disp('Timestamps were fixed.')
% Filenames
if nargin<4;
    data.animal = filename;
    outname = [filename(1:end-4) '.mat'];    
else
    data.animal = animal;
    data.session = session;
    temp = str2cell(filename,'\');
    outdir = [];
    for c=1:length(temp)-1;
        outdir=cat(2,outdir,[temp{c} '\']); 
    end;
    outname = [outdir animal '_' session '.mat'];
end;
data.sr = samplingrate;
disp(['Outname : ',outname]);


% Events
try
    for c=1:length(nexfile.events)
        if length(nexfile.events{c}.timestamps)>1;
            data.events = event_fix(nexfile.events{c}.timestamps); % To fix the missing events
            break; % to stop the first time it finds an event with more than one times.
        end;
    end;
catch
    data.events = [];
end;

disp('Events completed.');

% Units
try
    k=1;
    for c=1:length(nexfile.neurons)
        if ~strcmp(nexfile.neurons{c}.name(end),'U') % To exclude unsorted spikes
            data.units{k,1}=nexfile.neurons{c}.name;
            data.units{k,2}=nexfile.neurons{c}.timestamps;
            k=k+1; % The reason why I'm using an extra counter, is that otherwise the units will contain empty matrices
        end;
    end;
catch
    data.units = [];
end;
disp('Units completed.')

% Unsorted spikes
try
    k=1;    
    for c=1:length(nexfile.neurons)
        if strcmp(nexfile.neurons{c}.name(end),'U') % To take only unsorted spikes
            data.unsorted{k,1}=nexfile.neurons{c}.name;
            data.unsorted{k,2}=nexfile.neurons{c}.timestamps;
            k=k+1;
        end;
    end;
catch
    data.unsorted = [];
end;
disp('Unsorted completed.')

% MUA
% Get all the spikes (sorted and unsorted) from each channel.
for c=1:length(nexfile.contvars)
    temp = [];
    for n=1:length(nexfile.neurons)
        if strcmp(nexfile.neurons{n}.name(1:6),strcat('sig', sprintf('%03d',c)))
            temp = cat(1,temp,nexfile.neurons{n}.timestamps);
        end;
    end;
    data.mua{c,1} = sort(temp);
end;
disp('MUA completed.')

% LFPs
m = min(length(nexfile.contvars{1}.data),length(nexfile.contvars{end}.data));
for c=1:length(nexfile.contvars)
    temp = nexfile.contvars{c}.data(1:m)';
    data.lfp(c,:)=decimate(temp,nexfile.contvars{c}.ADFrequency/samplingrate);
    data.timestamps(c,1) = nexfile.contvars{c}.timestamps;
    disp(['Converting channel : ',num2str(c)])
end;
disp('LFPs completed.')

% Waveforms
try
    k=1;
    for c=1:length(nexfile.waves)
        if ~strcmp(nexfile.waves{c}.name(end),'U_wf') && ~strcmp(nexfile.waves{c}.name(end),'U_template') % To exclude unsorted spikes
            data.waveforms{k,1}=nexfile.waves{c}.name;
            data.waveforms{k,2}=nexfile.waves{c}.timestamps;
            data.waveforms{k,3}=nexfile.waves{c}.waveforms;
            k=k+1;
        end
    end;
catch
    data.waveforms=[];
end;
disp('Waveforms completed.')

% Fix freezing and add it (no need to fix it for the lfp timestamps,
% because the events are already fixed (in the fix_timestamps), so the shift is incorporated.
if nargin<5;
    data.freeze = [];
else
    data.freeze = freeze+(data.events(1)-122);
end;

% Save
try
    save(outname,'data','-v7.3')
catch
    disp('Problem with saving.');
end;