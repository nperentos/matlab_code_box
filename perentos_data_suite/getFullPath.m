function fullPath = getFullPath(folderName,pth)

% generate full path to the specified folder
if folderName(1:2) ~= 'NP'
    error(['can only deal with recordings that start with NP e.g.: ',...
        'NP3/NP3_2018-04-11_19-37-06',...
        'that live inside /storage2/perentos/data/recordings/'])
end

% get animal name
p = find(folderName == '_',1);
animalFolder = folderName(1:p-1);

dataPath = '/storage2/perentos/data/recordings/';
if nargin == 2
    if ~isempty(pth); dataPath = pth; end
end
% 
fullPath = [dataPath,animalFolder,'/',folderName,'/'];