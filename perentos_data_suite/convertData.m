function convertData(folderName, remapping, dataPath)
% NPerentos 13/04/2018
% wrapper function to convert data to lfp and dat from OE. Simplifies
% loading etc by finding the fullpath to the folderName provided and the 
% map if one exists in a README.txt.
% convertData(folderName, remapping, dataPath)

OEmaps
if nargin < 1 | ~ischar(folderName)
    error(['You either did not specify a ',...
        'file name or you specified a non string variable']);
end
if folderName(1:2) ~= 'NP'
    error(['can only deal with recordings that start with NP e.g.: ',...
        'NP3/NP3_2018-04-11_19-37-06',...
        'that live inside /storage2/perentos/data/recordings/'])
end

% get animal name
p = find(folderName == '_',1);
animalFolder = folderName(1:p-1);
if nargin < 3
    dataPath = '/storage2/perentos/data/recordings/';
end
if nargin < 2
    disp 'you did not supply an electrode map... will look for txt file with mapping/probe notes';    
    cd([dataPath,animalFolder,'/',folderName]); 
    if ~fopen('README.txt','r')
        noRemap = 1;
        options.mapping = [];
    else
        fileID = fopen('README.txt','r'); %fileID = fopen([dataPath,animalFolder,folderName,'/README.txt'],'r');
        tline = fgetl(fileID); tline = tline(7:end);
        if strcmp(tline, 'n/a')
            noRemap = 1;
        elseif strcmp(tline, 'CNE')
            options.mapping = oemaps.CNE4;
        elseif strcmp(tline, 'P2')
            options.mapping = oemaps.P2;
            disp 'README.txt has P2 as your probe - will use that';
        elseif strcmp(tline, 'P1')
            options.mapping = oemaps.P1;
        else
            noRemap = 1;
            options.mapping = [];            
            disp 'no remapping';
        end
    end
end


% if not converted then convert data
ifConvert = 0;
if size(dir([dataPath,animalFolder,'/',folderName,'/processed']),1) < 9
    ifConvert = 1;
else
    disp 'found converted data... no need to recompute';
end

if ifConvert
    options.lfpSR=1000;
    if nargin > 1
        disp 'you supplied a remapping array... will use...'
        options.mapping = remapping; % the actual mapping [electrode numbers]
    end
    options.numcores=[];
    options.downsampleparallel=1;
    options.period=[];%[1.3609e3, 2.5648e3];
    options.jumpoverride=1;
    options.appendchannels=1;
%     try
        openephys2dat([dataPath animalFolder '/' folderName],options);
%     catch
%         disp('this folder threw an error so best to check what happened');
%         disp([dataPath animalFolder '/' folderName]);
%         %disp('moving on to the next one');
%     end
end

%% irrespective of whether data was already converted or not lets try and copy the continuous files 
% to the raw folder
% once data is converted lets move the continuous files over to a
    % raw_fileBase folder
    
    mkdir(fullfile(dataPath,animalFolder,folderName,['raw_', folderName]));
    try
        cd(fullfile(dataPath,animalFolder,folderName));    
        movefile('*.continuous',fullfile(dataPath,animalFolder,folderName,['raw_', folderName]));
        movefile('Continuous_Data.openephys',fullfile(dataPath,animalFolder,folderName,['raw_', folderName]));
        movefile('messages.events',fullfile(dataPath,animalFolder,folderName,['raw_', folderName]));
        movefile('settings.xml',fullfile(dataPath,animalFolder,folderName,['raw_', folderName]));
        movefile('all_channels.events',fullfile(dataPath,animalFolder,folderName,['raw_', folderName]));
    catch
        display 'probably files were already moved. Please check.'
    end


    
    
    