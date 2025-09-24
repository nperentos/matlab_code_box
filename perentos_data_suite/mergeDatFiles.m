    function mergeDatFiles(fileList)

% takes a list of sessions in the form of a cell array
% generates a new folder name based on the provided list
% links the dat files in the new folder
% joins the dat files and gives it the name of the new folder

% check if files come from the same animal
for i = 1:length(fileList)-1
    if ~strcmp(fileList{i}(1:15), fileList{i+1}(1:15))
        error('different animalsor different day?? please check folders')
    end    
end
% new folder 
nf = [fileList{1}(1:15),'_merged']
cd(getFullPath(fileList{1}));
cd ..;
mkdir(nf)
cd(getFullPath(nf));
mkdir('processed');
out_dat = fullfile(getfullpath(nf),[nf,'.dat']);
out_xml = fullfile(getfullpath(nf),[nf,'.xml']);

%% make a list of the dat files (full path to)
clear pth par SampleRate nChannels nBits
for i = 1:length(fileList)
    pth{i} = fullfile(getfullpath(fileList{i}),[fileList{i},'.dat']);
    par = LoadXml(pth{i}(1:end-4));
    %
    SampleRate(i) = par.SampleRate;
    nChannels(i) = par.nChannels;
    nBits(i) = par. nBits;
end

if ~max(diff(SampleRate)) & ~max(diff(nChannels)) & ~max(diff(nBits))
    display 'merging...';       
else
    error('dat files dont match ... aborting')
end

% system command
catcommand = ['cat ' cell2mat(cellfun(@(x) [x ' '], pth,'un',0)) ' > ' out_dat];
tic; s = system(catcommand); toc;
if s;
    disp('There was an error concatenating');
    return;
end

% also copy the xml of the first dat file
copyfile([pth{1}(1:end-4),'.xml'],out_xml)