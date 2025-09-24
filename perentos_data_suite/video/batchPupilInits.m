
error('not meant to be used as is - need to modify things each time and use the second part only')
% searches the data full data path (down to session folders) in search for
% pupil vids. If no pupilInit.mat exists then it calls pupilInit to create
% the pupil search criteria.
global datapath
cd(datapath);
subj = dir('NP*');
subj = {subj.name};
allf1 = {}; allf2 = {};

for i = 1:length(subj)
    cd([datapath,'/',subj{i}]);
    tmp = dir('NP*');
    f1 = {tmp.folder};
    f2 = {tmp.name};    
    allf1 = [allf1, f1];
    allf2 = [allf2, f2];
end

% for each path look for pupil video and pupil results
for i = 1:length(allf1)
    cd([allf1{i},'/',allf2{i}]);
    pwd
    fle = dir('*pupil*avi');
    if ~isempty(fle)
        % check if we already have pupil detection initialisation variables
        cd([allf1{i},'/',allf2{i},'/processed']);
        res = dir('pupilInit.mat');
        if length(res) == 1 
            disp 'results available - will not reprocess';
        else
            disp 'starting detection';
            [pupilInit] = initPupilDetection_v1([allf1{i},'/',allf2{i},'/',fle.name]);  
            if isnan(pupilInit.rct)
                disp('unsuccesful detection ... skipping file');
            else
                save([allf1{i},'/',allf2{i},'/processed/pupilInit.mat'],'pupilInit');
                disp 'saved ... moving on to next file .. '
            end
        end
    end
end

%% OR
an = {'NP46','NP47','NP48'};
for i = 1:length(an)
    cd(fullfile('/storage2/perentos/data/recordings',an{i}));
    list{i} = dir('*/..');
    for j = 3:length(list{i})
        list{i}(j).name
        try
            trackPupilMorpho(list{i}(j).name,1,0)
        catch
            display 'looks like videos are mising here?'
            list{i}(j).name
        end
    end
end