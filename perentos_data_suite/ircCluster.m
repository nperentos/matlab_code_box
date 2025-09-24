function ircCluster(folderName,probeMap,flg1,flg2,flg3)
%%--------------------------------------------------------
% NPERENTOS-30/10/2018
% input 1- example: folderName = 'NP3_2018-04-11_19-37-06'
% input 2- example: probeMap = 'neuronexus_1x32poly2.prb'
% input 3 -make prm flag; [1 or 0]
% input 4 -detect spikes flag; [1 or 0]
% input 5 -cluster spikes flag; [1 or 0]
%%--------------------------------------------------------

%% get files in order
% make bin file
    if nargin < 2
        error(['Two inputs are required, ',...
            ' the filebase for the recording and the probe map']);
    end
    if nargin <3
        flg1 = 1; flg2 = 1; flg3 = 1;
    end
% get map file   
    prbPth = '/storage2/perentos/code/thirdParty/ironclust/matlab/prb';
    if ~strcmp(probeMap(end-3:end),'.prb') 
        probeMap = [probeMap,'.prb'];
    end
    if ~exist(fullfile(prbPth,probeMap))
        error('cannot find specified map file - please check');
    end

% get path to processed folder
    p = find(folderName == '_',1);
    animalFolder = folderName(1:p-1);
    dataPath = '/storage2/perentos/data/recordings/';
    flPth = fullfile(dataPath,animalFolder,folderName,'processed');
    
    cd(flPth); 
    if ~exist(fullfile(flPth,'irc'))
        mkdir(fullfile(flPth,'irc'))
    end
    cd irc

% copy .dat file and rename to bin 
    binFile = fullfile(flPth,'irc',[folderName,'.bin']);
    if ~exist(binFile)
        copyfile(fullfile(flPth,[folderName,'.dat']),binFile);
    end
    
    probeMapFile = fullfile(flPth,'irc',probeMap);    
    if ~exist(probeMapFile)
        copyfile(fullfile(prbPth,probeMap),probeMapFile);
    end

%% make a prm file
    if flg1
        cmd = ['irc makeprm ''', binFile, ''' ''', probeMapFile,''''];
        eval(cmd);
    end
    
%% detect spikes    
    if flg2
        disp 'detecting spikes...';
        cmd = ['irc detect ',folderName,'_', probeMap(1:end-4),'.prm'];
        eval(cmd);
    end

%% cluster data    
    if flg3
        disp 'sorting spikes...';
        cmd = ['irc sort ',folderName,'_', probeMap(1:end-4),'.prm'];
        eval(cmd);
    end