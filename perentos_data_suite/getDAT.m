% takes folder name and loads the data
% works by default with NPs folder structure i.e. my data path is hardcoded
% can take other data paths if necessary in the optional dataPath input
% takes sessionFolder e.g. NP3_2018-04-11_19-37-06
% loads in workspace
%   lfp data into workspace as channels x timepoints
%   settings xml
%   sampling rate
%   xaxis time scale
function [data,settings,tScale] = getDAT(sessionFolder,channels, dataPath)
defaultDataPath = '/storage2/perentos/data/recordings/';
disp 'importing dat file - could take long';
% ensure correct inputs
if nargin == 3 % alternative data path supplied
    defaultDataPath = dataPath;
    DATpth = fullfile(defaultDataPath,sessionFolder,'processed',[sessionFolder,'.dat']);
     if ~exist(DATpth) % try simpler file structure of EXELU
         DATpth = fullfile(defaultDataPath,sessionFolder,[sessionFolder,'.dat']);
         if ~exist(DATpth);
             error('file structure unconventional cannot continue please check'); 
         end
     end
elseif nargin == 1
    error('two inputs required, a folder name and channel number(s)')
elseif nargin < 3
    TF = isstrprop(sessionFolder(3:4),'digit');
    if sum(TF) == 2
        DATpth = [defaultDataPath, sessionFolder(1:4),'/',sessionFolder,'/processed/',sessionFolder,'.dat'];
    elseif TF(1) == 1
        DATpth = [defaultDataPath, sessionFolder(1:3),'/',sessionFolder,'/processed/',sessionFolder,'.dat'];
    else 
        disp('I was expecting a sessionFolder to start with NP (or other 2 initials characters followed by 1 or 2 digits');
        disp 'EXAMPLE:  NP3_2018-04-11_19-37-06'
        error('fix sessionFolder input variable and try again');
    end
end

data = load_binary(DATpth,channels);
data = double(data);
settings = xml2struct([DATpth(1:end-4),'.xml']); %grab sampling rate of LFP
SR = str2num(settings.parameters.acquisitionSystem.samplingRate.Text);
settings = xml2struct([DATpth(1:end-4),'.oe.xml']); % grab gain values
for i = 1:length(channels)
    try
        gain(i) = str2num(settings.SETTINGS.SIGNALCHAIN{1,1}.PROCESSOR{1,1}.CHANNEL_INFO.CHANNEL{1,i}.Attributes.gain);
    catch
        gain(i) = str2num(settings.SETTINGS.SIGNALCHAIN(1,1).PROCESSOR{1,1}.CHANNEL_INFO.CHANNEL{1,i}.Attributes.gain);
    end
end
data = data.*gain';
tScale = 1/SR:1/SR:size(data,2)/SR;