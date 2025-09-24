function getVidVars(fileBase,varargin)

% finds all result files of video analyses and collects
% them into a single matrix called videoFeatures. The resolution is at the
% camera frame rate which would be 30 Hz most of the time. 
% INPUT: fileBase (check inside function for more options)
% OUTPUT:   all_video_results.mat
%           videoFeatures.data a matrix of all the video variables activities
%           videoFeatures.name: other info
% features included:
% 1. pupil X, Y and area
% 2. face roi energies (whisker, pad, nose, tongue, eye, ear)
% 3. faceroi svds x 10 PCs
% 4. nose position (X and Y for three points - from deep labcut)
% 5. whisker position (angles for left and right whisker)
    disp('collecting all available video feaures into videoFatures.mat - at frame rate!');
    
    
    
%% PREREQUISITES
    options = {'init',1,'track',0,'session_pth',[],'vidName','top','abs_vid_path',[],'verbose',0,'ROI',[]};
    options = inputparser(varargin,options);   
    
    if ~isempty(options.session_pth)
        pth = getfullpath(fileBase,options.session_pth); % path to session
    else
        pth = getfullpath(fileBase); % path to session
    end
    
    % count frames - will use for checking variables' dimensions 
    fullPath = fullfile(getFullPath(fileBase),'video');
    test1 = (dir(fullfile(fullPath,'side*.avi')));
    test2 = (dir(fullfile(fullPath,'top*.avi')));
    test3 = (dir(fullfile(fullPath,'*pupil*.avi')));
    
    if ~size(test1,1) | ~size(test2,1)
        pth = getFullPath(fileBase); cd(pth);
        if ~isdir([pth,'video'])
            display('there is no video in this session');
            videoFeatures = [];
            save(fullfile(getfullpath(fileBase),'all_video_results.mat'),'videoFeatures','-v7.3');
            return;
        else
            error('perhaps videos are missing ... check and rerun');
        end
    elseif size(test1,1) == 1 & size(test2,1) == 1 & size(test3,1) == 1
        fileName1 = [test1.folder,'/',test1.name];
        fileName2 = [test2.folder,'/',test2.name];
        fileName3 = [test3.folder,'/',test3.name];
        obj1 = VideoReader(fileName1);
        obj2 = VideoReader(fileName2);
        obj3 = VideoReader(fileName3);
        if obj1.Duration ~= obj2.Duration
            %THIS NEEDS TO BE INVESTIGATED FURTHER - WHY NOT MATCHING???
            %error('the two video files have different number of frames?');
            nFr = max([obj1.Duration*obj1.FrameRate obj2.Duration*obj2.FrameRate obj3.Duration*obj3.FrameRate]);
        else
            nFr = max([obj1.Duration*obj1.FrameRate obj2.Duration*obj2.FrameRate obj3.Duration*obj3.FrameRate]);
        end
    end
    clear fileName1 fileName2 obj1 obj2 test1 test2
    
    %
    j = 1; % offset into features matrix
    videoFeatures.data = nan(nFr,3+6+6*10+2+2);% a good guess of the dimension of the data matrix
    cd(getfullpath(fileBase));

%% PUPIL MORPHO TRACKING (AREA,X_POSITION, Y_POSITION, ?)
    try
        load('pupilInit.mat');
        load('pupilRes.mat');
        nme = {'area','centerX','centerY'};
      % pupil area
        for i = 1:length(nme)
            videoFeatures.data(:,j) = resSm(:,find(strcmp(varNames, nme{i})));
            videoFeatures.name{j} = ['pupil_',nme{i}]; 
            videoFeatures.ROI(j,:) = pupilInit.rct;
            j = j+1;
        end
      % interpolation flag
        videoFeatures.info.pupilInterpFlag = resSm(:,find(strcmp(varNames, 'interpFlag')));
        
    catch
        warning('pupilInit.mat  and/or pupilRes.mat are missing so skipping');
        %dbstop if warning
    end
    
%% PUPIL DLC TRACKING
    try
        load('pupilDLC.mat'); % lets not load this for now
        nme = {'area','centerX','centerY'};
      % pupil area
        for i = 1:length(nme)
            videoFeatures.data(:,j) = pupDLC.resIntrp(:,i);
            videoFeatures.name{j} = ['pupilDLC_',nme{i}]; 
            videoFeatures.ROI(j,:) = [0 0 obj3.Width obj3.Height];
            j = j+1;
        end
        videoFeatures.data(:,j) = pupDLC.reflection(:,1); 
        videoFeatures.name{j} = ['pupDLC_reflection_X']; j = j +1;
        videoFeatures.data(:,j) = pupDLC.reflection(:,2); 
        videoFeatures.name{j} = ['pupDLC_reflection_Y']; j = j +1;
      % interpolation flag
        videoFeatures.info.pupDLCInterpFlag = pupDLC.outliers;
    catch
        warning('pupilDLC.mat are missing so skipping');
        %dbstop if warning
    end
    
    
%% FACE ROI ENERGIES (there should be 6)
%     try
%         load('faceROIs.mat');
%         load('face_ROI_energies.mat');
%         % add the ROI energies to the matrix
%         for i  = 1:length(ROI.names)
%             videoFeatures.data(:,j) = activity(:,i);
%             videoFeatures.name{j} = [ROI.names{i},'_frameDiff'];
%             videoFeatures.ROI(j,:) = ROI.pts(i,:);
%             j = j + 1;
%         end
%         
%     catch
%         warning('faceROIs.mat or face_ROI_energies.mat are missing so skipping');
%     end
    
%% WHOLE FRAME SVD COMPONENTS
    try
        load('face_wholeFrame_SVD_Activations.mat');
        % add the ROI energies to the matrix
        for k = 1:size(activity,1) % number of PCs per ROI
            videoFeatures.data(:,j) = padarray(activity(k,:)',nFr-length(activity),NaN,'post');
            videoFeatures.name{j} = ['wholeFrame_svd_',num2str(k)];
            %videoFeatures.ROI(j,:) = ROI.pts(i,:);
            j = j + 1;
        end                    
    catch
        warning('problem with whole frame svd so skipping!!!!');
    end
    
    
%% FACE ROI SVDs
    try
        load('faceROIs.mat'); % the ROIs are in fact the same as above
        load('face_SVD_ROI_Activations.mat');
        % add the ROI energies to the matrix
        for i  = 1:length(ROI.names)
            for k = 1:size(activity,1) % number of PCs per ROI
                videoFeatures.data(:,j) = padarray(sq(activity(k,:,i)),nFr-length(activity),NaN,'post');
                videoFeatures.name{j} = [ROI.names{i},'_pca_',num2str(k)];
                videoFeatures.ROI(j,:) = ROI.pts(i,:);
                j = j + 1;
            end            
        end        
    catch
        warning('faceROIs.matface_ROI_energies.mat and/or pupilRes.mat are missing so skipping');
    end

%% NOSE POSITION
    try
        load('noseTracking.mat'); % the ROIs are in fact the same as above
        % use only two PCs for now - ignore the row position???
        nme = {'nose_PC1','nose_PC2','nose_phi','nose_L'};
        for i  = 1:2
            videoFeatures.data(:,j) = padarray(sq(nose.PCs.score(:,i)),nFr-length(nose.PCs.score),NaN,'post');
            %nose.PCs.score(:,i);
            videoFeatures.name{j} = nme{i};
            %videoFeatures.ROI(j,:) = nan;
            j = j + 1;          
        end  
        videoFeatures.data(:,j) = padarray(sq(nose.vector.raw.phi),nFr-length(nose.vector.raw.phi),NaN,'post');
        videoFeatures.name{j} = nme{3}; j = j + 1;                  
        videoFeatures.data(:,j) = padarray(sq(nose.vector.raw.L),nFr-length(nose.vector.raw.L),NaN,'post');
        videoFeatures.name{j} = nme{4}; j = j + 1;                          
        videoFeatures.info.noseIdxInterp = nose.otl;  
    catch
        warning('problem with nose position - please investigate');
    end

    
%% WHISKER ANGLE
    try
        load('whiskerROIs.mat'); % the ROIs are in fact the same as above
        load('whisker_whiskerTracking.mat');
        % add the ROI energies to the matrix
        for i  = 1:size(ROI.names,2) % 2 whisker angles, left and right
            videoFeatures.data(:,j) = padarray(whisker.angle(i,:)',nFr-length(whisker.angle),NaN,'post');
            videoFeatures.name{j} = ROI.names{i};
            videoFeatures.ROI(j,:) = ROI.pts(i,:);
            j = j + 1;
        end
        videoFeatures.info.whiskerGaborMagnitudes = whisker.mag';
    catch
        warning('whiskerROIs.matand/or whisker_Tracking.mat are missing so skipping');
    end
    
    
%% GUMMY EYE
    try
        load('gummyEye.mat');
        load('faceROIs.mat');
    % get first PC of the intensity histograms. This will likely be similar
    % to the gummyEye.CC
        [~, pcs, ~] = pca(gummyEye.pxIntensity);
    % image histograms
        videoFeatures.data(:,j) = padarray(pcs(:,1),nFr-length(gummyEye.pxIntensity),NaN,'post');
        videoFeatures.name{j} = 'gummyEye_histogram_PC1';        
        videoFeatures.ROI(j,:) = ROI.pts(find(strcmp(ROI.names,'eye')),:);
        j = j + 1;
    % image cross corelations with the mother frame (first frame eye ROI essentially)
        videoFeatures.data(:,j) = padarray(gummyEye.CC,nFr-length(gummyEye.pxIntensity),NaN,'post');
        videoFeatures.name{j} = 'gummyEye_CC';
        videoFeatures.ROI(j,:) = ROI.pts(find(strcmp(ROI.names,'eye')),:);
        j = j + 1;        
        videoFeatures.info.gummyEye_motherFrame = gummyEye.motherFrame;        
    catch
        warning('cannot find gummyEye result... please check...')
    end
    
 
%% SACCADES
    try
        load('saccades.mat'); % the ROIs are in fact the same as above
        nme = {'saccadesX','saccadesY'};
        
        saccadesX = zeros(size(saccades.X.jerk,1),1);
        saccadesX(saccades.X.keepI) = 1;
        videoFeatures.data(:,j) = padarray(saccadesX,nFr-length(saccadesX),NaN,'post');
        videoFeatures.name{j} = nme{1};
        j = j + 1;
        
        saccadesY = zeros(size(saccades.Y.jerk,1),1);
        saccadesY(saccades.Y.keepI) = 1;
        videoFeatures.data(:,j) = padarray(saccadesY,nFr-length(saccadesY),NaN,'post');
        videoFeatures.name{j} = nme{2};
        j = j + 1;                
        videoFeatures.info.saccades = saccades;
    catch
        warning('saccades.mat is missing so skipping');
    end
    
    
%% due to frame diffs last frames (and hopefully only those!) are nans so we replace with mean    
    for i = 1:size(videoFeatures.data,2)
        en = find(isnan(videoFeatures.data(:,i)));
        if ~isempty(en)
            mu = nanmean(videoFeatures.data(:,i));
            videoFeatures.data(en,i) = mu;
            videoFeatures.info.nFr_vs_DetectionMissmatchFrames{i} = en;
        end
        en = [];
    end
    
%% SAVE 
    videoFeatures.name = videoFeatures.name';
    fprintf('saving ''all_video_results.mat''...');
    save(fullfile(getfullpath(fileBase),'all_video_results.mat'),'videoFeatures','-v7.3');  
    fprintf('DONE!\n');
end





%     fullPath = fullfile(getFullPath(fileBase),'video');
%     test3 = (dir(fullfile(fullPath,'top*.csv')));
%     if size(test3,1) ~= 1
%         error('multiple or no csv result was found. Did you run deeplabcut for nose detection? ');
%     else
%         fileName3 = [test3.folder,'/',test3.name];
%         [T] = importDLC(fileName3);
%         P = min(T.P,[],1); % we will treat these as missing values
%         t = (1:max(size(T.P)))'; 
%         ex = find(P<=0.995);
%     end
%     % nose is defined by 3 points each with an X and a Y
%     nme = {'nose_X1','nose_X2','nose_X3','unknown'};
%     for i = 1:size(T.X,1)
%         videoFeatures.data(:,j) = T.X(i,:)';
%         %videoFeatures.data(ex,j) = nan;     % maybe this shd be a postprocessing step
%         videoFeatures.name{j} = nme{i};
%         j = j + 1;
%     end
%     nme = {'nose_Y1','nose_Y2','nose_Y3','unknown'};
%     for i = 1:size(T.Y,1)
%         videoFeatures.data(:,j) = T.Y(i,:)';
%         %videoFeatures.data(ex,j) = nan;     % maybe this shd be a postprocessing step
%         videoFeatures.name{j} = nme{i};
%         j = j + 1;
%     end    
%     videoFeatures.info.noseProbabilitiesDLC = T.P; % dlc probabilities