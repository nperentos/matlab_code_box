function peripheralsPP(fileBase)
%% GENERATE A MATRIX OF PERIPHERALS, ALL ON THE LFP SCALE (tScale)

%fileBase = 'NP46_2019-10-26_15-40-40';
[data,settings,tScale] = getLFP(fileBase);
load(fullfile(getfullpath(fileBase),'peripherals.mat'));
p = peripherals; clear peripherals;

% DISCRETIZE POSITION INTO 5 DEGREE BINS
% 3 DEGREES CORRESPOND TO 2.9CM ON THE CAROUSEL WITH R = 55CM
    pos = smooth(p.position,20);
    posEdges = linspace(min(pos),max(pos),360/3);
    posDiscr = discretize(pos, posEdges);
    binCenters = (posEdges(2:end)+ posEdges(3)-posEdges(2));    

disp('interpolation ROIs');
n1 = sum(p.vidPulses); n2 = length(p.pupil.res);
n = abs(n1-n2);
% WHOLE ROI
    wholeROI    = interp1(tScale(p.vidPulses==1),[zeros(1,n) p.faceROIs.diffWhole],tScale,'linear','extrap');

% FACE ROI
    faceROI      = interp1(tScale(p.vidPulses==1),[zeros(1,n) p.faceROIs.diffFace]   ,tScale,'linear','extrap');     
    
% WHISKER ROI
    whiskerROI  = interp1(tScale(p.vidPulses==1),[zeros(1,n) p.faceROIs.diffWhisker],tScale,'linear','extrap');
    
% Snout ROI
    snoutROI    = interp1(tScale(p.vidPulses==1),[zeros(1,n) p.faceROIs.diffSnout] ,tScale,'linear','extrap');
    
% TONGUE ROI
    tongueROI   = interp1(tScale(p.vidPulses==1),[zeros(1,n) p.faceROIs.diffTongue],tScale,'linear','extrap');
    
% EAR ROI
    earROI      = interp1(tScale(p.vidPulses==1),[zeros(1,n) p.faceROIs.diffEar]   ,tScale,'linear','extrap');
    
% EYE ROI
    eyeROI      = interp1(tScale(p.vidPulses==1),[zeros(1,n) p.faceROIs.diffEye]   ,tScale,'linear','extrap');    
    
    disp('processing pupil variables ...');    
% PUPIL VARIABLES
    % difference in number of available frames and number of available pulses

    display(['number of pulses: ', num2str(n1),' and number of frames: ', num2str(n2)]);
    pupilDiam   = interp1(tScale(p.vidPulses==1), [zeros(1,n) p.pupil.resSm(:,1)'],tScale,'linear','extrap');
    pupilX      = interp1(tScale(p.vidPulses==1), [zeros(1,n) p.pupil.resSm(:,2)'],tScale,'linear','extrap');
    pupilY      = interp1(tScale(p.vidPulses==1), [zeros(1,n) p.pupil.resSm(:,3)'],tScale,'linear','extrap');
    
% NOSE POSITION FROM TOP CAMERA DEEPLABCUT (CURRENTLY MISSING)
    nosePos = zeros(size(tScale));
    
% RECTIFIED LICKING    
    licking = smooth(abs(hilbert(zscore(data(8,:)))),10);
    licking(licking > 10) = 0;   

% BULB PEAK RATE (FROM SPECTROGRAM)
    [~,ImaxS]   = max(p.resp.S.Sxy,[],2);
    respRate    = interp1(p.resp.S.t,p.resp.S.f(ImaxS),tScale,'linear','extrap');
    
% CAROUSEL MOVEMENT INDEX
    idxMov      = zeros(size(tScale));
    idxMov(p.carouselSpeed>1) = 1;

% TRIAL NUMBER INDEX
    idxTrialEpochs = [find(idxMov == 1,1); p.events.atStart];
    idxTrialEpochs = [idxTrialEpochs, circshift(idxTrialEpochs,-1)];
    idxTrialEpochs(end,:) = [];
    tmp = zeros(size(tScale));
    for i = 1:length(idxTrialEpochs)
        tmp(1,idxTrialEpochs(i,1):idxTrialEpochs(i,2)) = i;
    end
    idxTrials  = tmp;clear tmp;

%% PUT ALL VARIABLES INTO A SINGLE MATRIX
    ppp = [ tScale; 
            p.runSpeed; 
            p.carouselSpeed; 
            posDiscr'; 
            wholeROI; 
            whiskerROI;
            snoutROI; 
            tongueROI; 
            earROI; 
            eyeROI; 
            pupilDiam; 
            pupilX; 
            pupilY;
            licking'; 
            respRate; 
            idxMov; 
            idxTrials];% ppp stands for peripherals post processed
    
pppNames = {'tScale';
            'runSpeed';
            'carouselSpeed';
            'posDiscr'; 
            'wholeROI'; 
            'whiskerROI';
            'snoutROI';
            'tongueROI';
            'earROI'; 
            'eyeROI';
            'pupilDiam';
            'pupilX'; 
            'pupilY';
            'licking';
            'respRate'; 
            'idxMov';
            'idxTrials'};   

%% SAVE
save(fullfile(getfullpath(fileBase),'peripheralsPP.mat'), 'ppp','pppNames','binCenters','posEdges','-v7.3');
disp('succesfully saved peripheralsPP.mat');
% figure; plot(idxTrials/80); hold on; plot(idxMov);

%% GENERATE POSITION RESOLVED FIGURES FOR EACH BEHAVIORAL VARIABLE
disp('generating position resolved plots for behavioral variables...');
for i = [2 3 6 7 8 9 10 11 12 13 14 15]
    carouselPlotVar(fileBase,pppNames{i},1);
    pause(1); close;
end
    

%~cellfun('isempty',strfind(pppNames,'posD')); % partial string match
%(strcmp(pppNames,'tScale')==1) % or full string match


% DISCRETIZE POSITION INTO 5 DEGREE BINS
% commented block below corresponds to when the position was encoded in
% absolute pulses but now we changed to using adaptive resolution so as to
% fit available pulses into the 0 to 2pi range
%     pos = smooth(p.position,20);
%     posEdges = linspace(min(pos),max(pos),360/5);
%     posDiscr = discretize(pos, posEdges);
%     binCenters = (posEdges(2:end)+ posEdges(3)-posEdges(2));
%     binCentersRad = linspace(0,2*pi,length(binCenters));
%     binCentersRad = linspace(0,2*pi,length(binCenters));
% 3 DEGREES CORRESPOND TO 2.9CM ON THE CAROUSEL WITH R = 55CM

%     if sum(p.pupil.resSm(:)) == 0
%         disp('smoothing the pupil data - takes long!');
%         for i = 1:3
%             p.pupil.resSm(:,i) = smooth(p.pupil.res(:,i),4,'rlowess'); % rlowess is linear, outlier sensitive but loess is quadratic and sensitive to outlier
%         end
%         peripherals = p;
%         save(fullfile(getfullpath(fileBase),'peripherals.mat'),'peripherals');
%         clear peripherals;
%     end