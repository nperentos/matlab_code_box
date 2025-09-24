function fullpath = getfullpath(sessionFolder,dataPath)

defaultDataPath = '/storage2/perentos/data/recordings/';

if nargin > 1 & ~isempty(dataPath)% alternative data path supplied
    if ~isempty(dataPath); defaultDataPath = dataPath; end
    fullpath = [defaultDataPath,sessionFolder,'/processed/'];
    %disp 'cannot deal with this at present';
    %return;
elseif nargin > 2
    error('too many input arguments -- max two')
elseif nargin < 2 | isempty(dataPath)
    TF = isstrprop(sessionFolder(3:4),'digit');
    if sum(TF) == 2
        fullpath = [defaultDataPath, sessionFolder(1:4),'/',sessionFolder,'/processed/'];
    elseif TF(1) == 1
        fullpath = [defaultDataPath, sessionFolder(1:3),'/',sessionFolder,'/processed/'];
    else 
        disp('I was expecting a sessionFolder to start with NP (or other 2 initials characters followed by 1 or 2 digits');
        disp 'EXAMPLE:  NP3_2018-04-11_19-37-06'
        error('fix sessionFolder input variable and try again');
    end
end