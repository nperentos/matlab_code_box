function trackStartingPoint(fldrName,init,track, frams, downSampleFlag, verb)
% tracks the eye point on the carousel. Can be used to reset carousel
% location
close all; clearvars -global
if nargin<3
    error('NEED at least 3 INPUTS: (1)filename, (2)init flag, and (3)track flag')
end
if nargin<6
    verb = 0;
end
if nargin<5    
    downSampleFlag = 0;
end
if nargin<4
    frams = [];
end
% look for the top video 
fullPath = getFullPath(fldrName);
test = (dir(fullfile(fullPath,'top*.avi')));
if ~size(test,1)
    error('there is no top video file .. aborting');
elseif size(test,1) == 1
    disp 'found a top video file; continuing with data processing...'
    fileName = [test.folder,'/',test.name];
    [pth,fle,ext] = fileparts(fileName);
end

if ~exist([pth,'/processed'])
    disp 'making folder'
    mkdir([pth,'/processed'])
end

global pupilInit tracked flagND frameTimes prevFr blI fwb movI dataPrev frames verbose r_z dnsmpl framesTotal;  
flagND = 0; %pupilInit.rct   = 0; pupilInit.thr   = 0;
tracked.Centroid        = [0 0];
tracked.Area            = 0;
tracked.MajorAxisLength = 0;
tracked.MinorAxisLength = 0;
tracked.BoundingBox     = [0 0 0 0];
tracked.Orientation     = 0;
frameTimes              = 0;
prevFr                  = 0;
blI                     = [];
movI                    = [];
dataPrev                = [];
frames                  = frams;
verbose                 = verb;
r_z                     = [];
dnsmpl                  = downSampleFlag;
framesTotal             = 0;

% create a smoothing kernel
r_hat            = 2;
r_r              = -2:2;
r_z              = bsxfun(@plus,r_r'.^2, r_r.^2);
r_z              = r_z/sum(r_z(:));

% generate initialisation parameters for pupil search routine
if init
    % check if this processing has already been done
    if exist([pth,'/processed/pupilInit.mat'],'file')
        msg = 'pupil detection initialisation already exist. Rerun? [Y/N]';
        s = input(msg,'s');
        if s == 'y' | s == 'Y'            
            disp 'Initialising...'
            [pupilInit] = initPupilDetection_v1(fileName);
            save([pth,'/processed/pupilInit.mat'],'pupilInit');
            disp('OK, subframe coordinates and threshold saved for later processing');
        else
            disp 'OK -- using existing detection criteria';
        end
    else
        disp 'Initialising...'
        [pupilInit] = initPupilDetection_v1(fileName);
        save([pth,'/processed/pupilInit.mat'],'pupilInit');
        disp('OK, subframe coordinates and threshold saved for later processing');
    end
end

if verbose
    global fig_num;
    fig_num = figure('pos',[1083   -88   960   456]); 
end

if exist([pth,'/processed/pupilInit.mat'],'file')
    load([pth,'/processed/pupilInit.mat']);
    %if isempty(frames); frames = pupilInit.nrFrames; end
else
    error('cannot find pupil detection initialisation parameters. rerun trackPupil.m with init flag=1');
end

if isempty(frames); framesTotal = pupilInit.nrFrames; end
if ~isempty(frames); framesTotal = length(frames); end

% search for the pupil in all available video frames
if track
        % check if this processing has already been done
    if exist([pth,'/processed/pupilResults.mat'],'file')
        msg = 'pupil detection results already created. Rerun? [Y/N]';
        s = input(msg,'s');
        if s == 'y' | s == 'Y'            
            disp ' Ready to track pupil'  
            % the following imports few frames at a time; no need to organise this
            disp ' Tracking...'  
            fwb = waitbar(0,'Processing frames...');
            mmread(fileName,frames,[],false,true,'processFramePupil_v1');
            close(fwb);
            disp 'done... saving...'
            save([pth,'/processed/pupilResults.mat'],'tracked','flagND','pupilInit','frameTimes','blI','movI')
        else
            disp 'OK -- will not run';
        end
    else
        disp ' Tracking...'  
        fwb = waitbar(0,'Processing frames...');
        mmread(fileName,frames,[],false,true,'processFramePupil_v1');
        close(fwb);close all;
        disp '  Done... saving...'
        save([pth,'/processed/pupilResults.mat'],'tracked','flagND','pupilInit','frameTimes','blI','movI')
        disp '   Saved.';
    end
end