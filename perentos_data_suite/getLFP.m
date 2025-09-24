function [data,settings,tScale] = getLFP(sessionFolder, dataPath,ch)
% takes folder name and loads the data
% works by default with NPs folder structure i.e. my data path is hardcoded
% can take other data paths if necessary in the optional dataPath input
% takes sessionFolder e.g. NP3_2018-04-11_19-37-06
% loads in workspace
%   lfp data into workspace as channels x timepoints
%   settings xml
%   sampling rate
%   xaxis time scale

defaultDataPath = '/storage2/perentos/data/recordings/';

%% ensure correct inputs
if nargin == 0; error('need path to file to load...'); end


[LFPpth] = pathconstructor(sessionFolder, dataPath)



%%
tic;
disp 'loading binary ..lfp...';
if nargin == 3 % a subset of channels is requested
    data = load_binary(LFPpth,ch);
else
    data = load_binary(LFPpth);
end
toc
disp 'convert to double...';
data = double(data);
settings = xml2struct([LFPpth(1:end-4),'.xml']); %grab sampling rate of LFP
SR = str2num(settings.parameters.fieldPotentials.lfpSamplingRate.Text);
fle_oe = [LFPpth(1:end-4),'.oe.xml'];
if exist(fle_oe)
    settings = xml2struct(fle_oe); % grab gain values
    for i = 1:size(data,1)
        try
            gain(i) = str2num(settings.SETTINGS.SIGNALCHAIN{1,1}.PROCESSOR{1,1}.CHANNEL_INFO.CHANNEL{1,i}.Attributes.gain);
        catch
            gain(i) = str2num(settings.SETTINGS.SIGNALCHAIN.PROCESSOR{1,1}.CHANNEL_INFO.CHANNEL{1,i}.Attributes.gain);
        end         
    end
    data = data.*gain';
end
tScale = 1/SR:1/SR:size(data,2)/SR;
%settings = xml2struct([LFPpth(1:end-4),'.xml']); %grab sampling rate of LFP

    
