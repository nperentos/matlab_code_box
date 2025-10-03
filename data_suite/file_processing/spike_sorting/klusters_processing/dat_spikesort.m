function dat_spikesort(fn, artifactremoval)

if nargin<2; artifactremoval=1; end;

%% Edit XML file
fn = directory_sanitizer(fn);
[xmlfn,sessionname] = get_lfp_filename(fn,'xml');
settings = xml2struct(xmlfn);

%% Read spike groups
spikegroups1 = get_lfp_filename(fn,'spikegroups');
if ~exist(spikegroups1);    
    disp('No spikegroups file found.')
    disp('Created a template one.')
    disp('Please fill and run again.');
    fid = fopen(spikegroups1,'w');
    fprintf(fid,'# %s \n',sessionname{1});
    fprintf(fid,'# Template \n\n');
    fprintf(fid,'# Note that channel numbers start from 0 and should be comma separated \n');
    fprintf(fid,'%.0f # \n',0:str2num(settings.parameters.acquisitionSystem.nChannels.Text)-1);
    fclose(fid)
    return;
end

spikegroups1 = fileread(spikegroups1);
spikegroups1 = split_string(spikegroups1,'\n');
spikegroups = {};
for c=1:length(spikegroups1);
    l = spikegroups1{c};
    
    if isempty(l) | strcmp(l(1),'#') | strcmp(l(1),' '); % comment line
        continue;
    else
        tmp = split_string(l,'#');
        comment = tmp{2};
        spikegroups{c} = cellfun(@str2num,split_string(tmp{1},','));
    end; 
end
spikegroups = spikegroups(cellfun(@(x) ~isempty(x), spikegroups));

%% Edit XML file
% Add spikegroups to xml
settings.parameters.spikeDetection.channelGroups = struct();
for c=1:length(spikegroups);
    settings.parameters.spikeDetection.channelGroups.group{c}.nSamples.Text = '48';
    settings.parameters.spikeDetection.channelGroups.group{c}.peakSampleIndex.Text = '16';
    settings.parameters.spikeDetection.channelGroups.group{c}.nFeatures.Text = '3';
    for ch=1:length(spikegroups{c})
        settings.parameters.spikeDetection.channelGroups.group{c}.channels.channel{ch}.Text = num2str(spikegroups{c}(ch));
    end
end

% Add spikesorting related programs to xml
settings.parameters.programs.program{1} = [];
settings.parameters.programs.program{1}.name.Text = 'ndm_extractchannels';
settings.parameters.programs.program{1}.help.Text = 'Extract channels from .dat file (i.e. remove those channels that are not listed).';
settings.parameters.programs.program{1}.parameters.parameter{1}.name.Text = 'nChannels';
settings.parameters.programs.program{1}.parameters.parameter{1}.value.Text = '';
settings.parameters.programs.program{1}.parameters.parameter{1}.status.Text = 'Mandatory';
settings.parameters.programs.program{1}.parameters.parameter{2}.name.Text = 'channels';
settings.parameters.programs.program{1}.parameters.parameter{2}.value.Text = '';
settings.parameters.programs.program{1}.parameters.parameter{2}.status.Text = 'Mandatory';

settings.parameters.programs.program{2} = [];
settings.parameters.programs.program{2}.name.Text = 'ndm_extractspikes';
settings.parameters.programs.program{2}.help.Text = 'Extract spikes from high-pass filtered .fil file (this creates .res and .spk files).';
settings.parameters.programs.program{2}.parameters.parameter{1}.name.Text = 'thresholdFactor';
settings.parameters.programs.program{2}.parameters.parameter{1}.value.Text = '1.5';
settings.parameters.programs.program{2}.parameters.parameter{1}.status.Text = 'Mandatory';
settings.parameters.programs.program{2}.parameters.parameter{2}.name.Text = 'refractoryPeriod';
settings.parameters.programs.program{2}.parameters.parameter{2}.value.Text = '25';
settings.parameters.programs.program{2}.parameters.parameter{2}.status.Text = 'Mandatory';
settings.parameters.programs.program{2}.parameters.parameter{3}.name.Text = 'peakSearchLength';
settings.parameters.programs.program{2}.parameters.parameter{3}.value.Text = '50';
settings.parameters.programs.program{2}.parameters.parameter{3}.status.Text = 'Mandatory';
settings.parameters.programs.program{2}.parameters.parameter{4}.name.Text = 'start';
settings.parameters.programs.program{2}.parameters.parameter{4}.value.Text = '0';
settings.parameters.programs.program{2}.parameters.parameter{4}.status.Text = 'Mandatory';
settings.parameters.programs.program{2}.parameters.parameter{5}.name.Text = 'duration';
settings.parameters.programs.program{2}.parameters.parameter{5}.value.Text = '200';
settings.parameters.programs.program{2}.parameters.parameter{5}.status.Text = 'Mandatory';

settings.parameters.programs.program{3} = [];
settings.parameters.programs.program{3}.name.Text = 'ndm_hipass';
settings.parameters.programs.program{3}.help.Text = 'High-pass filter a .dat file (required for spike extraction).';
settings.parameters.programs.program{3}.parameters.parameter{1}.name.Text = 'windowHalfLength';
settings.parameters.programs.program{3}.parameters.parameter{1}.value.Text = '16';
settings.parameters.programs.program{3}.parameters.parameter{1}.status.Text = 'Mandatory';

settings.parameters.programs.program{4} = [];
settings.parameters.programs.program{4}.name.Text = 'ndm_lfp'*;
settings.parameters.programs.program{4}.help.Text = 'Downsample a .dat file to create the corresponding LFP file.';
settings.parameters.programs.program{4}.parameters.parameter{1}.name.Text = 'samplingRate';
settings.parameters.programs.program{4}.parameters.parameter{1}.value.Text = '1000';
settings.parameters.programs.program{4}.parameters.parameter{1}.status.Text = 'Mandatory';

settings.parameters.programs.program{5} = [];
settings.parameters.programs.program{5}.name.Text = 'ndm_pca';
settings.parameters.programs.program{5}.help.Text = 'Compute principal component analysis (PCA).';
settings.parameters.programs.program{5}.parameters.parameter{1}.name.Text = 'before';
settings.parameters.programs.program{5}.parameters.parameter{1}.value.Text = '8';
settings.parameters.programs.program{5}.parameters.parameter{1}.status.Text = 'Mandatory';
settings.parameters.programs.program{5}.parameters.parameter{2}.name.Text = 'after';
settings.parameters.programs.program{5}.parameters.parameter{2}.value.Text = '12';
settings.parameters.programs.program{5}.parameters.parameter{2}.status.Text = 'Mandatory';
settings.parameters.programs.program{5}.parameters.parameter{3}.name.Text = 'extra';
settings.parameters.programs.program{5}.parameters.parameter{3}.value.Text = 'true';
settings.parameters.programs.program{5}.parameters.parameter{3}.status.Text = 'Mandatory';

% Save xml
struct2xml(settings,xmlfn);

%% Extract spikes etc
currentdir = pwd; % Preserve directory
cd(fn)

fn1 = get_lfp_filename(fn,'');
fn1 = fn1(1:end-1);

system(['ndm_hipass ' fn1]);
system(['ndm_extractspikes ' fn1]);
system(['ndm_pca ' fn1]);

%% Move files
directory_sanitizer([fn 'spikesorting'],1);
backupfn = directory_sanitizer([fn 'spikesorting/backup'],1);

cellfun(@(x) movefile(x,[fn 'spikesorting']),list_files(fn,'*.clu*'));
cellfun(@(x) movefile(x,[fn 'spikesorting']),list_files(fn,'*.fet*'));
cellfun(@(x) movefile(x,[fn 'spikesorting']),list_files(fn,'*.res*'));
cellfun(@(x) movefile(x,[fn 'spikesorting']),list_files(fn,'*.klg*'));
cellfun(@(x) movefile(x,[fn 'spikesorting']),list_files(fn,'*.spk*'));

cellfun(@(x) copyfile(x,backupfn),list_files(fn,'*.xml*')); % Backup xml files

xmlfn1 = [fn 'spikesorting/' sessionname{1} '.xml'];
system(['ln -s ' xmlfn ' ' xmlfn1]);

%% Remove spikes during artifact periods
if artifactremoval; remove_spikes_artifact_periods(fn); end;

%% Kluster data
cd(currentdir)

fn1 = [fn 'spikesorting/'];
fn2 = [fn1 sessionname{1}];

sorting_params = '-PenaltyMix 1.0 -MinClusters 10 -MaxClusters 10 -MaxPossibleClusters 20 -nStarts 1 -UseFeatures 1111111111111111111111111111';

fetfiles = list_files(fn1,'*.fet*');
for c=1:length(fetfiles)
    cmd = ['/storage/share/bin/KlustaKwik ' fn2 ' ' num2str(c) ' ' sorting_params ' &'];
    system(cmd);
end

disp('')
disp('Clustering started. Check list of files for status.')

