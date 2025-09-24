function runVideoAnalysis(fileBase)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% runVideoAnalysis runs a bunch of functions that have been pre initialised
% in terms of ROIs etc, generates matlab files for each analysis and
% finally collects a subselection of the varables into a single matlab file
% using getVidVars.m. The final matlab file is called all_video_results.mat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

pth = getFullPath(fileBase); cd(pth);
if ~isdir([pth,'video'])
    display('there is no video in this session')    
    return;
end


%% track pupil
% saves some report figures for visualisation
tic
disp('------------------------------------------------------------------');
disp('extracting pupil size and position...');
trackPupilMorpho(fileBase,0,1);
toc
disp('------------------------------------------------------------------');
disp(' ');disp(' ');

%% whole frame singular value decomposition
% does not save figures
tic
disp('------------------------------------------------------------------');
disp('extracting whole frame SVD...');
wholeFrameSVD(fileBase);
toc
disp('------------------------------------------------------------------');
disp(' ');disp(' ');


%% subframe singular value decomposition pca
% does not save figures
tic
disp('------------------------------------------------------------------');
disp('extracting sub frame SVD...');
options.track = 1;
subFrameSVD(fileBase,options);
toc
disp('------------------------------------------------------------------');
disp(' ');disp(' ');


%% whisker tracking
% saves some report figures for visualisation
tic
disp('------------------------------------------------------------------');
disp('extracting whiskers'' position...');
options.track = 1;
trackWhiskersGabor(fileBase,options);
toc
disp('------------------------------------------------------------------');
disp(' ');disp(' ');

%% nose position tracking
% saves some report figures for visualisation
tic
disp('------------------------------------------------------------------');
disp('extracting nose position from deeplabcut output...');
importDLC(fileBase);
toc
disp('------------------------------------------------------------------');
disp(' ');disp(' ');


%% gummy eye
% saves some report figures for visualisation
tic
disp('------------------------------------------------------------------');
disp('extracting gummy eye...');
getGummyEye(fileBase);
toc
disp('------------------------------------------------------------------');
disp(' ');disp(' ');

%% pupil using DLC
% saves some report figures for visualisation
tic
disp('------------------------------------------------------------------');
disp('extracting pupil quantification using DeepLabCut...');
importPupilDLC(fileBase);
toc
disp('------------------------------------------------------------------');
disp(' ');disp(' ');

%% get saccades
% saves some report figures for visualisation
tic
disp('------------------------------------------------------------------');
disp('extracting pupil quantification using DeepLabCut...');
getSaccades(fileBase);
toc
disp('------------------------------------------------------------------');
disp(' ');disp(' ');

%% combine all variables into a matlab file 
% sampling rate at the camera frame rates
% does not save any figures
% tic
% disp('------------------------------------------------------------------');
% disp('generating final video matrix at video frame rate...');
% getVidVars(fileBase);
% toc
% disp('------------------------------------------------------------------');