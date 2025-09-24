function ircVis(folderName)

% get path to processed folder
    p = find(folderName == '_',1);
    animalFolder = folderName(1:p-1);
    dataPath = '/storage2/perentos/data/recordings/';
    flPth = fullfile(dataPath,animalFolder,folderName,'processed','irc');
    cd(flPth);

% show summary and then go to manual sort
    lst=dir('*.prm');
    if length(lst) > 1
        if length(lst(1).name) < length(lst(2).name)
            cmd1 = ['irc describe ',lst(1).name];
            cmd2 = ['irc manual ',lst(1).name];
            disp 'here'
        else
            cmd1 = ['irc describe ',lst(2).name];
            cmd2 = ['irc manual ',lst(2).name]; 
            disp 'hesre'
        end
    end
    
    eval(cmd1);
    eval(cmd2);