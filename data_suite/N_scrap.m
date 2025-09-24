%% 1. CREATE A MAP FOR EACH SESSION AND CONVERT TO DAT 
%   Note: It looks like when there is 2 probes the EEGs were in the middle
%   65-95 whereas if a single probe was used it looks like EEG was always 1-32
%   The following should take care of this but better to always visualise
%   the data after conversion because there might be exceptions!!!!!!!!!
%   we account for two HS order scenarios   P1+EEG+P2  or  EEG+P1
% 
% read mappings from excel for conversion purposes
%T = readtable('/storage2/perentos/data/recordings/animals_and_recording_session_particulars.xlsx','Sheet','AnalysisVars');
T = getCarouselDataBase;OEmaps;
for i = 92
  
    
% ADC channel numbers % ADC is not needed as it defaults to the end of the file
    str = T.ADC{i};
    del = strfind(str,'-'); 
    if del ~= 1
        fr = str2num(str(1:del-1));
        to = str2num(str(del+1:end)); 
        ADC = fr:to;
    else
        display('there is  no ADC in this recording session');
        ADC = []; 
    end
        
% P1 channels assuming Probe 1 is at 1-64
    if sum(strcmp(fields(oemaps),{T.probe1{i}}))
        P1 = oemaps.(T.probe1{i})+0;
        display(['probe 1 is: ', T.probe1{i}]); 
    else
        display('probe 1 is: NONE');
        P1 = [];
    end
    
% P2 channels assuming Probe 2 is at 97-160
    if sum(strcmp(fields(oemaps),T.probe2{i}))
        P2 = oemaps.(T.probe2{i})+32+64;
        display(['probe 2 is: ', T.probe2{i}]); 
        EEGofs = 64; % if two probes, EEG was on second HS (preceded b64)
    else
        display('probe 2 is: NONE');
        P2 = [];
        EEGofs = 0; % if single probe, EEG was on first HS (1-32)
    end

% EEG channel numbers
    str = T.EEG{i};
    del = strfind(str,'-'); 
    if del ~= 1
        fr = str2num(str(1:del-1));
        to = str2num(str(del+1:end)); 
        EEG = [fr:to]+EEGofs;
    else
        display('there is  no EEG in this recording session');
        EEG = [];
    end     
    
% FINAL MAP
if isempty(P2) 
    % only one probe was used - expectation then is that P1 is at 33-96 so that one can use 
    % the PI microdrive. But perhaps also the cable was swapped so then P1
    % would be at 1-64
    map = [P1+32 EEG]; 
else
    map = [P1 P2 EEG]; 
end


% convert data
    convertData(T.session{i},map);
    clear map
end

%% 2. Write contents of the xlsx file to a text file for DLC to use
fid = fopen('/storage2/perentos/data/recordings/DLCpaths.txt','w');
for jj = [12 16 33 41 46 62 115 137 165]
    fprintf(num2str(jj));
    fle = dir(fullfile(getFullPath(T.session{jj}),'video/top*.avi'));
    if length(fle) == 1
        %fprintf( fid, '%s\n', ['''',fullfile(fle.folder,fle.name),'''']);
        fprintf( fid, '%s\n', fullfile(fle.folder,fle.name));
    end    
    if jj<10; fprintf('\b'); else; fprintf('\b\b'); end
    %pause(0.2);
end
fclose(fid); fprintf('\n');

disp('The file was succesfully generated');
disp('Please inspect it at /storage2/perentos/data/recordings/DLCpaths.txt')


%% 3. INITIAL VIDEO
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function initialiseVideoAnalysis promps the user to define ROIs for the
% video analysis which are a prerequisite to all the video analysis except
% those that use DeepLabCut.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
T = getCarouselDataBase;

for i = [12 16 33 41 46 62 115 137 165]
     display(['processing ',num2str(i), ' out of ', num2str(height(T))])
    fileBase = T.session{i};
    initialiseVideoAnalysis(fileBase);
end

%% If eye is close

natialiasLisrt = [];
T = getCarouselDataBase;
for i = 51
     display(['processing ',num2str(i), ' out of ', num2str(height(T))])
    fileBase = T.session{i};
    trackPupilMorpho(fileBase,1,0,10000)
end

%% 4. VIDEO ANALISIS
T = getCarouselDataBase;
for i = [12 16 33 41 46 62 115 137 165]
     display(['processing ',num2str(i), ' out of ', num2str(height(T))])
    fileBase = T.session{i};
    runVideoAnalysis(fileBase)
end

%% 5. Visualization of correct position pf the piupil
T = getCarouselDataBase;
for i = 51
   
   
     display(['processing ',num2str(i), ' out of ', num2str(height(T))])
    fileBase = T.session{i};
    %displayFrames(fileBase,[1:30*3]);
    options.outliers = 1;
    displayFrames(fileBase,[],options);
end

%% 6. Check the position of the square on the face
T = getCarouselDataBase;
for i = 101
     display(['processing ',num2str(i), ' out of ', num2str(height(T))])
    fileBase = T.session{i};
    displayROIFrames(fileBase,[1:30*3],ROI.pts(1,:))
end

%% 7. Plot Nise position
T = getCarouselDataBase;
for i = [12 16 33 41 46 62 115 137 165]
     display(['processing ',num2str(i), ' out of ', num2str(height(T))])
    fileBase = T.session{i};
    plotNoseTracking(fileBase)
end

%% 8. Visualise nose tracking for all sessions
T = getCarouselDataBase;
for i = 3
     display(['processing ',num2str(i), ' out of ', num2str(height(T))])
    fileBase = T.session{i};
    manualNoseTrackingQuality
end

%% 9. COMBINE TOGETHER
T = getCarouselDataBase;
for i = [3 7 17 29 36 47 56 70 99 109 134 161 206]
     display(['processing ',num2str(i), ' out of ', num2str(height(T))])
    fileBase = T.session{i};
    getVidVars(fileBase);
end

%% Additional
% track the pupil
T = getCarouselDataBase;
for i = 134
     display(['processing ',num2str(i), ' out of ', num2str(height(T))])
    fileBase = T.session{i};
disp('extracting pupil size and position...');
trackPupilMorpho(fileBase,0,1);
end

% whole frame singular value decomposition
T = getCarouselDataBase;
for i = 36
     display(['processing ',num2str(i), ' out of ', num2str(height(T))])
    fileBase = T.session{i};
disp('extracting whole frame SVD...');
wholeFrameSVD(fileBase);


% subframe singular value decomposition
disp('extracting whole frame SVD...');
options.track = 1;
subFrameSVD(fileBase,options);


% nose position tracking
disp('extracting nose position from deeplabcut output...');
importDLC(fileBase);


% whisker tracking
T = getCarouselDataBase;
for i = 138
     display(['processing ',num2str(i), ' out of ', num2str(height(T))])
    fileBase = T.session{i};
disp('extracting whiskers'' position...');
options.track = 1;
trackWhiskersGabor(fileBase,options);
endwisk
end
end



% combine all variables into a matlab file (sampling rate will be at the
% camera frame rates

%% SPIKESORTER DELETE+OPEN
%% 10. Spike sort the database - MUST RUN ON SPIKESORTER!
%T = readtable('/storage2/perentos/data/recordings/animals_and_recording_session_particulars.xlsx','Sheet','AnalysisVars');
T = getCarouselDataBase;
sss = [163:165 206];
for jj = 1:length(sss)
    i = sss(jj);
toSort = false;
display(['processing ',num2str(i), ' out of ', num2str(height(T)), '. fileBase is: ', T.session{i}]);
% if isempty(str2num(char(T.KS_good(i))))
    % in case already sorted and are about to resort delete files...
    if exist([fullfile(getfullpath(T.session{i})),'rez2.mat'],'file')
        warning('there is already a kilosort solution in this folder!! Are you sure you want to recompute? This will overwrite any manual spike sorting already performed on this session!!!');
        inp = input('Press [Y] to overwrite or any other key to skip: ','s');
        if strcmp(inp,'Y')
            toSort = true;
        end
    else
        toSort = true;
    end
    if toSort
        cd(fullfile(getfullpath(T.session{i})))
        delete('amplitudes.npy','channel_map.npy','channel_positions.npy','cluster_Amplitude.tsv','cluster_ContamPct.tsv','cluster_group.tsv','cluster_info.tsv','cluster_KSLabel.tsv','params.py','pc_feature_ind.npy',...
        'pc_features.npy','phy.log','rez2.mat','rez.mat','similar_templates.npy','spike_clusters.npy','spike_templates.npy','spike_times.npy','template_feature_ind.npy','template_features.npy','templates_ind.npy',...
        'templates.npy','whitening_mat_inv.npy','whitening_mat.npy');
        master_kilosort(T.session{i});
        load(fullfile(getfullpath(T.session{i}),'rez2.mat'));
        display(['session ',T.session{i}, ',  db_entry=', num2str(sss(jj)), ' and number of good cells is ',num2str(sum(rez.good))]);
    else
        display(['skipping ',num2str(i), ' out of ', num2str(height(T)), '. fileBase is: ', T.session{i}])
    end
end
    %writetable(T,'/storage2/perentos/data/recordings/animals_and_recording_session_particulars.xlsx','Sheet','AnalysisVars')
% else
%     display(['skipping ',num2str(i), ' out of ', num2str(height(T)), '. fileBase is: ', T.session{i}])
% end



%% Run a video analysis function across many session efficiently
% this example is whisker which needs ROI (re)definitions
T= getCarouselDataBase;
for i = 101
    fileBase = T.session{i};
    cd(getfullpath(fileBase));
    delete('whiskerROIs.mat');
    trackWhiskersGabor(fileBase);
end
    
    T= getCarouselDataBase;
    for i = 1
        fileBase = T.session{i};
        display(['processing ',num2str(i), ' out of ', num2str(height(T))])
        cd(getfullpath(fileBase));
        trackWhiskersGabor(fileBase,{'init',0,'track',1});
    end
    
%% 11. Check wiskers
    T= getCarouselDataBase;
for i = 30
    fileBase = T.session{i};
    display(['processing ',num2str(i), ' out of ', num2str(height(T))])
   
    plotWhiskerTracking(fileBase)
end


%% 12. AuVars
T= getCarouselDataBase;
for i = 2
    fileBase = T.session{i};
    display(['processing ',num2str(i), ' out of ', num2str(height(T)), '  : ',fileBase])
    generateAuxVars(fileBase);
end
    
%% 13. COMBINAAL
T= getCarouselDataBase;
for i = [12 16 33 41 46 62 115 137 165]
    fileBase = T.session{i};
    display(['processing ',num2str(i), ' out of ', num2str(height(T)), '  : ',fileBase])
    combineVidAuxVars(fileBase);
end
 
    
%% PIPLINE CHECK  
% LFP and ADC
    convertDataCarousel(fileBase);
    % modify the dat file
    getGoodChannels(fileBase); 
    findCommonMode(fileBase);
    generateAuxVars(fileBase);
    % do you need to update spreadsheet??
    
% VIDEO    
    initialiseVideoAnalysis(fileBase);% this step is manual
    runVideoAnalysis(fileBase);
    % user must check results here before next step
    % update spreadheet with scores of video analusis 0 super-bad 1 good 2
    % bad
    getVidVars(fileBase);
    
% COMBINE BEHAVIORAL VARIABLLES FROM LFP AND VIDEO
    combineVidAuxVars(fileBase);

%% CHECK VIDEO QUICKLY
obj = VideoReader('general2019-11-21T11_44_53.avi');
obj.CurrentTime = 60;
figure;
while hasFrame(obj)
    obj.CurrentTime = obj.CurrentTime+1;
    fr = readFrame(obj);
    gcf;
    imshow(fr);
    drawnow;
end

%% REPORT NUMBER OF TRIALS

clear;close all;
i_Sessions =  [ 2 6 7 12 16 17 18 29 30 33 36 38 41 44 ...
    46 47 51 56 57 59 62 70 73 83 87 99 101 109 112 115 132 ...
    134 137 139 147 155 161 163 165 168 177 190 197 200 203 206 ];
excluded = [1 3 123];
i_Sessions = sort(i_Sessions);
T = getCarouselDataBase;        
allFileBases = [T.session(i_Sessions)];
clear ErrorLog exception msgText;
set(0,'DefaultFigureVisible','on');
close all; figure; 
for i = 1:length(i_Sessions) 
    fileBase = T.session{i_Sessions(i)};
%     if strcmp(fileBase, 'NP39_2019-11-21_11-44-59')
%         continue;
%     end 
    %updateSession(fileBase);
    session = loadSession(fileBase);
    nTr= length(session.events.TTL.atStart);
    nBlocks = session.info.nBlocks;
    nTrials = session.info.nTrials;
    blockSz = nTrials/nBlocks; 
    [a,b] = sort(diff(session.events.TTL.all(:,1))./session.info.SR_WB,'descend');
    a = a(1:nBlocks-1);
    b = b(1:nBlocks-1);
    reprt{i,1} = [num2str(i_Sessions(i)), ', ',fileBase, ',  ',num2str(nTr),...
        'trials, ',num2str(nBlocks), 'blocks'];
    reprt{i,2} = [num2str(b)];
    reprt{i,3} = [num2str(length(session.events.TTL.all(:,1)))];
    reprt{i,4} = session.info.taskType;
    subplot(211);
    plot((session.events.TTL.atStart)./60000);xlabel('trial num');
    title([reprt{i,1},session.info.taskType],'interpreter','none');
    subplot(212);
    plot((session.events.TTL.all(:,1))/(60*30000),(session.events.TTL.all(:,2)),'ok'); xlabel('min');
    ylim([0.5 4.5]); pause; clf;
end
close;

%% RUN ANY FUNCTION ACROSS ALL OF NATALIAS SESSIONS
clear;close all;
i_Sessions =  [ 2 6 7 12 16 17 18 29 30 33 36 38 41 44 ...
    46 47 51 56 57 59 62 70 73 83 87 99 101 109 112 115 132 ...
    134 137 139 147 155 161 163 165 168 177 190 197 200 203 206 ];
i_Sessions = sort(i_Sessions);
excluded = [1 3 123];

%i_Sessions =  i_Sessions_all(1:23);
% i_Sessions =  i_Sessions_all(24:end);


T = getCarouselDataBase;        
allFileBases = [T.session(i_Sessions)];
clear ErrorLog exception msgText;
set(0,'DefaultFigureVisible','off');
for i = length(i_Sessions):-1:35
    close all;  
    fileBase = T.session{i_Sessions(i)};
    try         
        display(['processing ',num2str(i), ' out of ', num2str(length(i_Sessions)), '  : ',fileBase]);
%         if strcmp(fileBase, 'NP39_2019-11-21_11-44-59')
%             continue;
%         end        
        % importDLC(fileBase);  % reran on Oct 2 for i_Sessions
        % getVidVars(fileBase); % reran on Oct 2 for i_Sessions
        % generateAuxVars(fileBase);      
        % combineVidAuxVars(fileBase);
        updateSession(fileBase);
        getBehTrialMatrices(fileBase);
    catch exception
        ErrorLog{i,1} = T.session{i_Sessions(i)};
        ErrorLog{i,2} = getReport(exception);
        warning('a file was skipped due to an error - check ErrorLog');
        disp(ErrorLog{i,2})        
    end       
    fprintf('\n\n\n');
end
close;

%% COLLATE ALL REPORT FIGURES ACROSS SESSIONS
clear;close all;
i_Sessions =  [ 2 3 6 7 12 16 17 18 29 30 33 36 38 41 44 ...
    46 47 51 56 57 59 62 70 73 83 87 99 101 109 112 115 132 ...
    134 137 139 147 155 161 163 165 168 177 190 197 200 203 206 ];
excluded = [1 123];
i_Sessions = sort(i_Sessions);
T = getCarouselDataBase;        
allFileBases = [T.session(i_Sessions)];
clear ErrorLog exception msgText;
for i = 1:length(i_Sessions) 
    close all;  
    fileBase = T.session{i_Sessions(i)};
    
    fnme = {'gummyEye_summary','all_behavioral_variables','goodChannels',...
        'commonMode','lickin_summary','nose_angle','positionByTime','pupil_area',...
        'respirationProperties','ROI_definitions','thetaProperties','whisker_tracking'};    
    goto(fileBase);
    for j = 1:length(fnme)
        figure;set(gcf,'visible','off');
        fnme_current = fnme{j};
        try
            im = imread([fnme_current,'.jpg']);
            imshow(im); hold on; 
        catch
            axes('pos',[0 0 1 1]);
            text(0.5,0.5,'missing figure');
            ylim([0 1]);xlim([0 1]); axis off;
        end        
        stampFig(fileBase);
        export_fig(['/storage2/perentos/results/',fnme_current,'_ALL_SESSIONS.pdf'],'-pdf','-append');  
        pause(1);
        close all;
    end
end
close;

%% WHISKER RE-REDEFINITION
% this will be a whisker ROI redefinition function for all of natalias
% files since said ROIs are ill defined
clear;close all;
i_Sessions =  [ 2 3 6 7 12 16 17 18 29 30 33 36 38 41 44 ...
    46 47 51 56 57 59 62 70 73 83 87 99 101 109 112 115 132 ...
    134 137 139 147 155 161 163 165 168 177 190 197 200 203 206 ];

excluded = [1 123];
i_Sessions = sort(i_Sessions);
T = getCarouselDataBase;        
% lets loop through all the sessions and rerun so as to correct respiration
% filter settings, add nose angle and magnitude. There might be more...
% can also loop through and create a single pdf with a particular figure
% (e.g. commonMode.jpg) for all sessions of interest
clear ErrorLog exception msgText;
for i = 1:length(i_Sessions) 
    close all;  
    fileBase = T.session{i_Sessions(i)};
%     try         
%         display(['processing ',num2str(i), ' out of ', num2str(length(i_Sessions)), '  : ',fileBase]);
%         cd(getfullpath(fileBase));
%         if exist('whiskerROIs.mat')
%             display('deleting previous ROI definitions');
%             delete('whiskerROIs.mat')
%         end
%         trackWhiskersGabor(fileBase);
%     catch exception
%         ErrorLog{i,1} = T.session{i_Sessions(i)};
%         ErrorLog{i,2} = getReport(exception);
%         warning('a file was skipped due to an error - check ErrorLog');
%     end
%     close;
    
    % a figure showing the ROIs for summary visualisation
    % load the ROIs
    fullPath = fullfile(getFullPath(fileBase),'video');
    
    % side view
    test1 = (dir(fullfile(fullPath,'side*.avi')));
    if ~size(test1,1)
        warning('there is no side*.avi video file .. skipping session');
        return;
    elseif size(test1,1)>1
        error('multiple side*.avi files were found - please investigate');
    elseif size(test1,1) == 1
        disp 'found a side*.avi file; continuing with data processing...'
        flag = [1];
        fileName = [test1.folder,'/',test1.name];
        obj1 = VideoReader(fileName);
        %[pth,fle,ext] = fileparts(fileName);
    end
    
    % top view
    test2 = (dir(fullfile(fullPath,'top*.avi')));
    if ~size(test1,1)
        warning('there is no top*.avi file .. skipping session');
        return;
    elseif size(test2,1)>1
        error('multiple top*.avi files were found - please investigate');
    elseif size(test2,1) == 1
        disp 'found a top*.avi file; continuing with data processing...'
        flag = [flag 1];
        fileName = [test2.folder,'/',test2.name];
        obj2 = VideoReader(fileName);
        %[pth,fle,ext] = fileparts(fileName);
    end
    figure;
    cd(getfullpath(fileBase));
    display(['processing ',num2str(i), ' out of ', num2str(length(i_Sessions)), '  : ',fileBase]);
    face = load(fullfile(getfullpath(fileBase),'faceROIs'));
    whisker = load(fullfile(getfullpath(fileBase),'whiskerROIs'));

    % plot first frame for side
    subplot(121);
    imagesc(rgb2gray(im2double(obj1.readFrame))); hold on; axis equal; colormap gray;
    % add the side ROIs:
    for  i = 1:length(face.ROI.names)
        rectangle('Position',face.ROI.pts(i,:),'EdgeColor','r','LineWidth',1,'LineStyle','-');
    end



    % plot first frame for top
    subplot(122);
    imagesc(rgb2gray(im2double(obj2.readFrame))); hold on; axis equal; colormap gray;
    % add the top ROIs:
    for  i = 1:length(whisker.ROI.names)
        rectangle('Position',whisker.ROI.pts(i,:),'EdgeColor','r','LineWidth',1,'LineStyle','-');
    end

    print(gcf,fullfile(getfullpath(fileBase),'ROI_definitions.jpg'),'-djpeg','-r600');
    close; clear obj1 obj2
    
end

%% inspect general videos to find female or whatever 
clear;close all;
i_Sessions =  [ 2 3 6 7 12 16 17 18 29 30 33 36 38 41 44 ...
    46 47 51 56 57 59 62 70 73 83 87 99 101 109 112 115 132 ...
    134 137 139 147 155 161 163 165 168 177 190 197 200 203 206 ];

excluded = [1 3 123];
% session 1 excluded because animal did not run and no female
% session 123 is excluded b/c its missing peripherals and there was no
% female anyway
% Natalia? whats up with sessions in red? 
i_Sessions = sort(i_Sessions);
T = getCarouselDataBase;        
allFileBases = [T.session(i_Sessions)];
j = sort(randperm(length(allFileBases),10));
j = [2    10    14    23    25    28    29    32    38    41];
for i = 1:length(j)
    goto(allFileBases{j(i)});
    cd ../video
    
    % CHECK THE GENERAL VIDEO 
    %     d=dir('general*.avi');
    %     if length(d) == 1
    %         str = ['vlc --width 400 --height 400 ',d.folder,'/', d.name ];
    %         fprintf([str,'\n']);
    %         clipboard('copy',[str])
    %         pause
    %         allFileBases{i,2} = input('enter sequence such as e.g.''bsl,fem,NO'', ::: ','s');
    %         allFileBases{i,3} = input('enter stimulus location e.g.''L/R/N'', ::: ','s');
    %         % eval(str)       
    %     end
    
    % FULL PATHS TO SIDE VIDEO FOR DLC USE
    d=dir('side*.avi');
    if length(d) == 1
       sideVidPaths{i,1} = [d.folder,'/', d.name,':    crop: 0, 720, 0, 540'];
       DLCProjectVideoFolder = '/storage2/perentos/data/PerentosPupil1-NP-2020-10-08/videos/';
       str = ['!ln -s ', d.folder,'/', d.name,' ',DLCProjectVideoFolder, d.name];
       eval(str);
    else
        error('something wrong with file names');
    end
    
end

%% next
figure;

% for i = 1:length(pup)
%     hold off;
%     scatter(pup(i,[2:3:24]),pup(i,[3:3:24]));
%     hold on;
%     scatter(pup(i,[26]),pup(i,[27]),'r');
%     xlim([0 100]);ylim([0 100]); set(gca,'YDir','reverse');
%     drawnow;
% end


% data = pup(:,[[2:3:24],[3:3:24]]);
data = pup(:,[3:3:24]);
[sig,mu,mah,outliers] = robustcov(data);
idx1 = find(outliers == 1);

idx2 = find(sum(data,2) ~= 8);
idx = idx2;
%figure;
for i = 1:length(idx)
    hold off;
    scatter(pup(idx(i),[1:3:24]),pup(idx(i),[2:3:24]));
    %hold on;
    %scatter(pup(idx(i),[26]),pup(idx(i),[27]),'r');
    xlim([0 100]);ylim([0 100]); set(gca,'YDir','reverse');
    title(num2str(idx(i)));
    drawnow;
    % pause;
end
% this is an outlier frame and we will test how to find the goodness of fit
% to it using ellipse or circle fitting
otl = find(sum(likelihoods,2) ~= 8);
for i = 20:length(otl)    
    Xc = X(otl(i),:)';
    Yc = Y(otl(i),:)';
    clf;
    plot(Xc,Yc,'xr'); hold on; % the dlc data points
    % polygons COM and area as most robust estimation of area and centroid
    [ geom, iner, cpmo ] = polygeom(Xc,Yc); %area and centroid of said polygon
    plot(geom(2),geom(3),'ok');
    % fit circle (used for residuals)
    out = circfit(Xc,Yc); % fit a circle to the data points
    viscircles([out(2),out(3)],out(1)); 
    resid(i,1) = sum(abs(sqrt((Xc-out(2)).^2 + (Yc-out(3)).^2)-out(1))); % circular fit residual
    % fi ellipse (used for residuals)
    [params] = fitellipse(Xc,Yc);
    Returned = round(params.*[1 1 1 1 180]);
    t = linspace(0,pi*2,40);
    x = params(3) * cos(t);
    y = params(4) * sin(t);
    nx = x*cos(params(5))-y*sin(params(5)) + params(1); 
    ny = x*sin(params(5))+y*cos(params(5)) + params(2);
    % since we would need to figure out the rotation of the fitted ellipse and
    % the corresponding radius at that angle to be able to compute the residual
    % on an individual point's basis, we can take a shortcut and instead
    % compute all the distances of the each point in question to those define
    % by the ellipse(nx,ny). The minimum of this set will be the equivalent to
    % the residual as defined above for circfit
    resid = 0;
    for pt = 1:8
        resid_(pt) = min(sqrt((Xc(pt)-nx).^2 + (Yc(pt)-ny).^2));
    end
    resid(i,2) = sum(resid_);
    
    hold on;
    plot(nx,ny,'b-');
    
    text(geom(2),geom(3),num2str(resid(i,2)));
    title(num2str(sum(likelihoods(otl(i),:))/8));
    xlim([0 100]);ylim([0 100]);
    axis equal;
    drawnow; pause(0.5*(resid(i,2)/20));
end

%% EXAMPLE 
function Template4Natasha(FileBase, varargin)
%DetectGammaModesOverlap is a function which detects wether gamma modes within a layer 
%with distinct preferred theta phase overlap in frequency.
%For that the function take phase values for all bursts from individual
%frequency bins and fits the phase values distribution with either Single
%Von Mises or with a Von Mises Mixture Model (2 components).
%
%USAGE: Template4Natasha(FileBase, <SignalType>, <BrainState>, <Channels>, <FreqRangeTotal>, <ThetaChannel>)
%
%INPUT:
% FileBase          is a name of the session (AnimalID-YYYMMDD).
% <SignalType>      is a type of signal the bursts have been detected in ('lfp','lfpinterp','csd'). Default='lfpinterp'
% <Channels>        is a vector with channels used for calculation. Default = [].
% <FreqRangeTotal>  is a frequency range the whole analysis will be done in. Default=[14 250]Hz
% <ThetaChannel>
% 
%EXAMPLE:    Template4Natasha(CurrentFileBase, 'lfpd', 'RUN', 65:96, [14 250])
%           
%
% Evgeny Resnik
% version 28.10.2020




FileBase = CurrentFileBase
Channels = 65:96;
BrainState = 'RUN';
SignalType = 'lfpd';
mfilename = 'Template4Natasha';



if nargin<1
    error(['USAGE:  DetectGammaModesOverlap(FileBase, <SignalType>, <BrainState>, <Channels>, <FreqRangeTotal>, <ThetaChannel>)'])
end


% Parse input parameters
[SignalType, BrainState ] = DefaultArgs(varargin, { 'lfpDeafult', 'BrainStateDefault' });


fprintf('=======================================================================================================\n')
fprintf(['                   %s - %s \n'], FileBase, mfilename )
fprintf('=======================================================================================================\n')


%-----------------------------------------------------------------------------%
%Load LFP sampling rates from .xml file
par = LoadXml([FileBase '.xml']);
lfpSamplingRate = par.lfpSampleRate;
nChan = par.nChannels;

%Path where figures must be save to
FigPathCommon = [pwd '/figures/'];




%-----------------------------------------------------------------------------%
%Load coordinates of LFP bursts
FileIn = sprintf('%s.%s.%s.%s.%d-%d.mat', FileBase, 'SelectBursts', SignalType, BrainState, Channels([1 end])  );
fprintf('Loading data from %s ...', FileIn)
load(FileIn, 'BurstFreq', 'Params');
fprintf('DONE\n')



%-----------------------------------------------------------------------------%
%calcalations ...




%-------------------------------------------------------------------------------------%
% Save data into a file
%-------------------------------------------------------------------------------------%
FileOut = sprintf('%s.%s.%s.%s.%d-%d.mat', FileBase, mfilename, SignalType, BrainState, Channels([1 end]) );
Params = struct('lfpSamplingRate', lfpSamplingRate, 'BrainState',BrainState,'Channels',Channels, 'FreqRange', FreqRangeTotal, 'ThetaChannel', ThetaChannel, 'ThrdMuDiff', ThrdMuDiff);
fprintf('Saving data into a file %s ...', FileOut)
save(FileOut,'outputvar1', 'outputvar2','Params', '-v7.3');
fprintf('DONE\n')







%---------------------------------------------------------------------------------%
%   Figure 1:
%---------------------------------------------------------------------------------%
FigIndex = 1;
figure;
redimscreen
colormap(jet)

h = tight_subplot(5, 5, [.05 .05], [.05 .07], [0.05 0.03]);
H = 1:5:5*5;



%suptitle
str = { sprintf('Detection of frequency ranges with overlaping gamma modes:  %s, %s', FileBase, AnatLayerTitle{l}) , sprintf('Bursts from: %s', InputBurstFile)  };
suptitle2(str, 0.92, 0)


%-------------------------------------------------------------------------------------%
%Save figure into a file
AxisPropForIllustrator(9);

FileOut = sprintf('%s.%s.%s.%s.%d-%d.%d', FileBase, mfilename, SignalType, BrainState, Channels([1 end]), FigIndex);

fprintf(['Saving figure into a file %s.jpg ...'], FileOut)
mkdir2([ FigPathCommon mfilename ])
% SaveForIllustrator( [FigPathCommon mfilename '/' FileOut],'jpg')
export_fig([FigPathCommon mfilename '/' FileOut], '-jpeg', '-nocrop', '-transparent', '-m2')
fprintf('DONE\n')

for nV = 23
    
    % Finding min and max for pupil area (for graph)
    tmp=[];
    for i = 1:nBlocks
        tmp = [tmp; A(nV).tun{i}(:)];
    end
    clim = round([min(tmp) max(tmp)]);
    clear tmp
    
    %additional variable
    nTrials = size(A(nV).tun{1},2);
    
    %Calculating for mean
    clear mean0 sd se
    for i = 1:nBlocks
        mean0.n = nTrials;
        mean0.CarouselPos = 1:360;
        mean0.PupilArea(i,:) = mean(A(nV).tun{i}');
        sd.PupilArea(i,:) = std(A(nV).tun{i}');
        se.PupilArea(i,:) = sd.PupilArea(i,:) / sqrt(mean0.n);
    end
    
    figure
    for i = 1:nBlocks
        
        %Pupil area PLOT
        subplot(4,3,i+0);
        imagesc(A(nV).tun{i}', clim);
        colorbar
        set(gca, 'xlim',[0 360], 'xtick', 0:90:360, 'xticklabels', 0:90:360 )
        set(gca, 'ylim',[1 nTrials], 'ytick', 1:4:nTrials, 'yticklabels', 1:4:nTrials)
        title({ sprintf('Block-%d',i)});
        %legend('show')
        %xlabel('Carousel angular position (degrees)')
        if i==1
            ylabel('Trials')
        end
        
        subplot(4,3,i+3); cla; hold on
        plot(A(nV).tun{i});
        set(gca, 'xlim',[0 360], 'xtick', 0:90:360, 'xticklabels', 0:90:360 )
        set(gca, 'ylim', clim.*[0.9 1.0], 'ytick', clim(1):100:clim(2), 'yticklabels', clim(1):100:clim(2))
        %xlabel('Carousel angular position (degrees)')
        if i==1
            ylabel('Pupil area, (pxl)')
        end
        
        subplot(4,3,i+6); cla; hold on
        %         plot(mean0.CarouselPos, mean0.PupilArea(i,:), 'color','k', 'linestyle','-', 'linewidth', 1, 'marker', 'none');
        shadedErrorBar(mean0.CarouselPos, mean0.PupilArea(i,:), se.PupilArea(i,:) )
        set(gca, 'xlim',[0 360], 'xtick', 0:90:360, 'xticklabels', 0:90:360 )
        set(gca, 'ylim', clim.*[0.9 1.0], 'ytick', clim(1):100:clim(2), 'yticklabels', clim(1):100:clim(2))
        xlabel('Carousel angular position (degrees)')
        if i==1
            ylabel('Mean pupil area, (pxl, SE)')
        end
    end
    
    %loop acros blocks
    
    %Common title
    str = { sprintf('Pupil area, (pxl)')};
    suptitle2(str, 0.92, 0);
    
    %Format
    AxisPropForIllustrator(12);
end

%% play around with the O/P from behTrialsMatrices.mat

%%1st step create general image for each block
load behTrialsMatrices.mat;
[session, behavior]=loadSession(fileBase);
nBlocks = session.info.nBlocks;
close all;
for nV = 1:length(A)
    figure;
    for i = 1:nBlocks
        subplot(3,1,i);
        imagesc(A(nV).tun{i}');
        title(['activ. on carousel for var: ',A(nV).varName, ', block number = ', num2str(i)], 'interpreter','none')
        %legend('show')
    end
end




%% ----------------------------------------------DIPLOMA----------------------------------------------------------------------------------------------------------------------------

%GO TO THE FILE

T = getCarouselDataBase;
for i = 30
    display(['processing ',num2str(i), ' out of ', num2str(height(T))])
    fileBase = T.session{i};
end

goto(fileBase)
ls
load behTrialsMatrices.mat;
[session, behavior]=loadSession(fileBase);
nBlocks = session.info.nBlocks;

close all;


%% Finding means and create aditianal file  
%(Work with one block)

% 1. Mean for each 20 degree for 14 trials
for nV = 25
    t = A(nV).tun{1,3}
     
    means = zeros(18,14); %create matrix with special size, but empty
    cur = 1;
    for m= [0: 20: 340] %from 0 wirh step 20 to 340, because 360-20
        cur_mean = mean(t(m+1:m+20,:)); % find meam for
        means(cur,:) = cur_mean;
        cur = cur+1;
    end
    
    means3 = means
    save('means3.mat','means3')
end

for nV = 25
    t = A(nV).tun{1,2}
    
    means = zeros(18,14); %create matrix with special size, but empty
    cur = 1;
    for m= [0: 20: 340] %from 0 wirh step 20 to 340, because 360-20
        cur_mean = mean(t(m+1:m+20,:)); % find meam for
        means(cur,:) = cur_mean;
        cur = cur+1;
    end
    
    means2 = means
    save('means2.mat','means2')
end

for nV = 25
    t = A(nV).tun{1,1}
    
    means = zeros(18,14); %create matrix with special size, but empty
    cur = 1;
    for m= [0: 20: 340] %from 0 wirh step 20 to 340, because 360-20
        cur_mean = mean(t(m+1:m+20,:)); % find meam for
        means(cur,:) = cur_mean;
        cur = cur+1;
    end
    
    means1 = means
    save('means1.mat','means1')
end


% 2. General means
M1 = mean(means1,2); % 2 meam that we find mean -->, 1 - mean that we wanna find in column
save('m1','M1');
nTrialsMean = size (M1,2)
clear mean0 sd se
for i = 1:nBlocks
    mean1.n = nTrialsMean;
    sd.M1 = std(M1);
    se.M1 = sd.M1 / sqrt(mean1.n);
end

M2 = mean(means2,2); % 2 meam that we find mean -->, 1 - mean that we wanna find in column
save('m2','M2');
nTrialsMean2 = size (M2,2)
clear mean0 sd se
for i = 1:nBlocks
    mean2.n = nTrialsMean2;
    sd.M2 = std(M2);
    se.M2 = sd.M2 / sqrt(mean2.n);
end


M3 = mean(means3,2); % 2 meam that we find mean -->, 1 - mean that we wanna find in column
save('m3','M3');
nTrialsMean3 = size (M3,2)
clear mean0 sd se
for i = 1:nBlocks
    mean3.n = nTrialsMean3;
    sd.M3 = std(M3);
    se.M3 = sd.M3 / sqrt(mean3.n);
end

TableMean = [M1'; M2'; M3']
TableMeans = TableMean'

[~,~,stats] = anova2(TableMeans,3, 'off')
c = multcompare(stats)


%% 1. Mean for each 10 degree for 14 trials
for nV = 25
    %Loop across blocks
    for bl=1:3
        t = A(nV).tun{1,bl}
                    %raw.PupilSize(bl, :,:) = A(nV).tun{1,bl};
                    %t = raw.PupilSize(bl, :,:);
    end     %loop across blocks
    
    means = zeros(36,14);   %create matrix with special size, but empty
    cur = 1;
    for m= [0: 10: 350] %from 0 wirh step 20 to 340, because 360-20
        cur_mean = mean(t(m+1:m+10,:)); % find meam for !!!!!DOESN'T WORK
        means(cur,:) = cur_mean;
        cur = cur+1;
    end
   
    %Save (??????)
    
    FunctionName = 'Analysis4PupilSize'
    FileOut = sprintf('%s.%s.mat', fileBase, FunctionName)
    save(FileOut, 'raw','newbin', 'Params' )
    
    %means3 = means
    %save('means3.mat','means3')
end

%------------Evgeny's version-----------------------%
angles_raw  = 1:360;
angles_bin = 0:10:360;
nBins = length(angles_bin);

clear means
for k=1:1:nBins-1
    ind = angles_raw>=angles_bin(k) & angles_raw<angles_bin(k+1);
    %means(k,:) = mean(t(ind, :),1);
    newbin.PupilSize(bl,k)= mean(t(ind, :),1);
end
%------------------ END ----------------------------%
    
     
 
% 1) CREATE LOOP FOR 3 BLOCKS
% 2) CREATE LOOP TO SAVE 


%% 2. General means
M1 = mean(means1,2); % 2 meam that we find mean -->, 1 - mean that we wanna find in column
    save('m1','M1');
nTrialsMean = size (M1,2)
clear mean0 sd se
for i = 1:nBlocks
    mean1.n = nTrialsMean;
    sd.M1 = std(M1);
    se.M1 = sd.M1 / sqrt(mean1.n);
end

M2 = mean(means2,2); % 2 meam that we find mean -->, 1 - mean that we wanna find in column
    save('m2','M2');
nTrialsMean2 = size (M2,2)
clear mean0 sd se
for i = 1:nBlocks
    mean2.n = nTrialsMean2;
    sd.M2 = std(M2);
    se.M2 = sd.M2 / sqrt(mean2.n);
end


M3 = mean(means3,2); % 2 meam that we find mean -->, 1 - mean that we wanna find in column
    save('m3','M3');
nTrialsMean3 = size (M3,2)
clear mean0 sd se
for i = 1:nBlocks
    mean3.n = nTrialsMean3;
    sd.M3 = std(M3);
    se.M3 = sd.M3 / sqrt(mean3.n);
end

TableMean = [M1'; M2'; M3']
TableMeans = TableMean'

[~,~,stats] = anova2(TableMeans,3, 'off')
c = multcompare(stats)



%% PLOT
%warmplot
for nV = 24
    figure;
    for i = 1:nBlocks
        subplot(3,1,i);
        imagesc(A(nV).tun{i}');
        title([A(nV).varName, ', Block = ', num2str(i)], 'interpreter','none')
        %legend('show')
        xlabel(['Carousel_position'],'interpreter','none')
        ylabel(['Trials'],'interpreter','none')
    end
end

%linear plots
for nV = 24
    figure;
    for i = 1:nBlocks
        subplot(3,1,i);
        plot(A(nV).tun{i});
        title([A(nV).varName, ', Block = ', num2str(i)], 'interpreter','none')
        %legend('show')
        xlabel(['Carousel_position'],'interpreter','none')
        ylabel([A(nV).varName],'interpreter','none')
    end
end

%means plot
for nV = 25
    figure;
    for i = 1:nBlocks
        subplot(3,1,i);
        plot(mean(A(nV).tun{i}'));
        title(['Means for:', A(nV).varName, ', Block = ', num2str(i)], 'interpreter','none')
        legend('show')
        xlabel(['Carousel_position'],'interpreter','none')
        ylabel([A(nV).varName],'interpreter','none')
    end
end

%mean for warmbar
for nV = 25
    figure;
    for i = 1:nBlocks
        subplot(3,1,i);
        imagesc(mean(A(nV).tun{i}'));
        title(['Means for:', A(nV).varName, ', Block = ', num2str(i)], 'interpreter','none')
        %legend('show')
        xlabel(['Carousel_position'],'interpreter','none')
        ylabel(['Trials'],'interpreter','none')
    end
end




%% FINAl

% Finding min and max for pupil area (for graph)
tmp=[];
for i = 1:nBlocks
    tmp = [tmp; A(nV).tun{i}(:)];
end
clim = round([min(tmp) max(tmp)]);
clear tmp

%additional variable
nTrials = size(A(nV).tun{1},2);

%Calculating for mean
clear mean0 sd se
for i = 1:nBlocks
    mean0.n = nTrials;
    mean0.CarouselPos = 1:360;
    mean0.PupilArea(i,:) = mean(A(nV).tun{i}');
    sd.PupilArea(i,:) = std(A(nV).tun{i}');
    se.PupilArea(i,:) = sd.PupilArea(i,:) / sqrt(mean0.n);
end



%% PLOT FOR EYES

T = getCarouselDataBase;
for i = 101
    display(['processing ',num2str(i), ' out of ', num2str(height(T))])
    fileBase = T.session{i};
end
goto(fileBase)
ls
load behTrialsMatrices.mat;
[session, behavior]=loadSession(fileBase);
nBlocks = session.info.nBlocks;
A(2).tun{1,1}

for nV = 25
    % Finding min and max for pupil area (for graph)
    tmp=[];
    for i = 1:nBlocks
        tmp = [tmp; A(nV).tun{i}(:)];
    end
    clim = round([min(tmp) max(tmp)]);
    clear tmp
    
    %additional variable
    nTrials = size(A(nV).tun{1},2);
    
    %Calculating for mean
    clear mean0 sd se
    for i = 1:nBlocks
        mean0.n = nTrials;
        mean0.CarouselPos = 1:360;
        mean0.PupilArea(i,:) = mean(A(nV).tun{i}');
        sd.PupilArea(i,:) = std(A(nV).tun{i}');
        se.PupilArea(i,:) = sd.PupilArea(i,:) / sqrt(mean0.n);
    end
    
    figure
    for i = 1:nBlocks
        
        %Pupil area PLOT
        subplot(4,3,i+0);
        imagesc(A(nV).tun{i}', clim);
        colorbar
        set(gca, 'xlim',[0 360], 'xtick', 0:90:360, 'xticklabels', 0:90:360 )
        set(gca, 'ylim',[1 nTrials], 'ytick', 1:4:nTrials, 'yticklabels', 1:4:nTrials)
        title({ sprintf('Block-%d',i)});
        %legend('show')
        %xlabel('Carousel angular position (degrees)')
        if i==1
            ylabel('Trials')
        end
        
        subplot(4,3,i+3); cla; hold on
        plot(A(nV).tun{i});
        set(gca, 'xlim',[0 360], 'xtick', 0:90:360, 'xticklabels', 0:90:360 )
        set(gca, 'ylim', clim.*[0.9 1.0], 'ytick', clim(1):100:clim(2), 'yticklabels', clim(1):100:clim(2))
        %xlabel('Carousel angular position (degrees)')
        if i==1
            ylabel('Pupil area, (pxl)')
        end
        
        subplot(4,3,i+6); cla; hold on
        %         plot(mean0.CarouselPos, mean0.PupilArea(i,:), 'color','k', 'linestyle','-', 'linewidth', 1, 'marker', 'none');
        shadedErrorBar(mean0.CarouselPos, mean0.PupilArea(i,:), se.PupilArea(i,:) )
        set(gca, 'xlim',[0 360], 'xtick', 0:90:360, 'xticklabels', 0:90:360 )
        set(gca, 'ylim', clim.*[0.9 1.0], 'ytick', clim(1):100:clim(2), 'yticklabels', clim(1):100:clim(2))
        xlabel('Carousel angular position (degrees)')
        if i==1
            ylabel('Mean pupil area, (pxl, SE)')
        end
    end
    
    %loop acros blocks
    
    %Common title
    str = { sprintf('Pupil area, (pxl)')};
    suptitle2(str, 0.92, 0);
    
    %Format
    AxisPropForIllustrator(12);
end

%Save file
%FileOut = sprintf('%s.%s.%s.%s.%d-%d.%d', 'Plot', fileBase, A(nV).varName);
fprintf(['Saving figure into a file %s.jpg ...'], FileOut)


%% PLOT FOR LICKING

[session, behavior]=loadSession(fileBase);
nBlocks = session.info.nBlocks;

for nV = 23
    % Finding min and max for pupil area (for graph)
    tmp=[];
    for i = 1:nBlocks
        tmp = [tmp; A(nV).tun{i}(:)];
    end
    clim = round([min(tmp) 1]) %max(tmp)]);
    clear tmp
    
    %additional variable
    nTrials = size(A(nV).tun{1},2);
    
    %Calculating for mean
    clear mean0 sd se
    for i = 1:nBlocks
        mean0.n = nTrials;
        mean0.CarouselPos = 1:360;
        mean0.PupilArea(i,:) = mean(A(nV).tun{i}');
        sd.PupilArea(i,:) = std(A(nV).tun{i}');
        se.PupilArea(i,:) = sd.PupilArea(i,:) / sqrt(mean0.n);
    end
    
    figure
    for i = 1:nBlocks
        
   % licking activity PLOT
        subplot(4,3,i+0);
        imagesc(A(nV).tun{i}', clim);
        colorbar
        set(gca, 'xlim',[0 360], 'xtick', 0:90:360, 'xticklabels', 0:90:360 )
        set(gca, 'ylim',[1 nTrials], 'ytick', 1:4:nTrials, 'yticklabels', 1:4:nTrials)
        title({ sprintf('Block-%d',i)});
        %legend('show')
        %xlabel('Carousel angular position (degrees)')
        if i==1
            ylabel('Trials')
        end
        
        subplot(4,3,i+3); cla; hold on
        plot(A(nV).tun{i});
        set(gca, 'xlim',[0 360], 'xtick', 0:90:360, 'xticklabels', 0:90:360 )
        set(gca, 'ylim', clim.*[0.9 1.0], 'ytick', clim(1):100:clim(2), 'yticklabels', clim(1):100:clim(2))
        %xlabel('Carousel angular position (degrees)')
        if i==1
            ylabel('Licking activity, (?)')
        end
        
        subplot(4,3,i+6); cla; hold on
        %         plot(mean0.CarouselPos, mean0.PupilArea(i,:), 'color','k', 'linestyle','-', 'linewidth', 1, 'marker', 'none');
        shadedErrorBar(mean0.CarouselPos, mean0.PupilArea(i,:), se.PupilArea(i,:) )
        set(gca, 'xlim',[0 360], 'xtick', 0:90:360, 'xticklabels', 0:90:360 )
        set(gca, 'ylim', clim.*[0.9 1.0], 'ytick', clim(1):100:clim(2), 'yticklabels', clim(1):100:clim(2))
        xlabel('Carousel angular position (degrees)')
        if i==1
            ylabel('Mean licking activity, (?, SE)')
        end
    end
    
    %loop acros blocks
    
    %Common title
    str = { sprintf('Licking activity, (?)')};
    suptitle2(str, 0.92, 0);
    
    %Format
    AxisPropForIllustrator(12);
end

%% RUN SPEED
[session, behavior]=loadSession(fileBase);
nBlocks = session.info.nBlocks;

for nV = 19
    % Finding min and max for pupil area (for graph)
    tmp=[];
    for i = 1:nBlocks
        tmp = [tmp; A(nV).tun{i}(:)];
    end
    clim = round([min(tmp) max(tmp)]);
    clear tmp
    
    %additional variable
    nTrials = size(A(nV).tun{1},2);
    
    %Calculating for mean
    clear mean0 sd se
    for i = 1:nBlocks
        mean0.n = nTrials;
        mean0.CarouselPos = 1:360;
        mean0.PupilArea(i,:) = mean(A(nV).tun{i}');
        sd.PupilArea(i,:) = std(A(nV).tun{i}');
        se.PupilArea(i,:) = sd.PupilArea(i,:) / sqrt(mean0.n);
    end
    
    figure
    for i = 1:nBlocks
        
   % licking activity PLOT
        subplot(4,3,i+0);
        imagesc(A(nV).tun{i}', clim);
        colorbar
        set(gca, 'xlim',[0 360], 'xtick', 0:90:360, 'xticklabels', 0:90:360 )
        set(gca, 'ylim',[1 nTrials], 'ytick', 1:4:nTrials, 'yticklabels', 1:4:nTrials)
        title({ sprintf('Block-%d',i)});
        %legend('show')
        %xlabel('Carousel angular position (degrees)')
        if i==1
            ylabel('Trials')
        end
        
        subplot(4,3,i+3); cla; hold on
        plot(A(nV).tun{i});
        set(gca, 'xlim',[0 360], 'xtick', 0:90:360, 'xticklabels', 0:90:360 )
        set(gca, 'ylim', clim.*[0.9 1.0], 'ytick', clim(1):25:clim(2), 'yticklabels', clim(1):25:clim(2))
        %xlabel('Carousel angular position (degrees)')
        if i==1
            ylabel('Run speed, (?)')
        end
        
        subplot(4,3,i+6); cla; hold on
        %         plot(mean0.CarouselPos, mean0.PupilArea(i,:), 'color','k', 'linestyle','-', 'linewidth', 1, 'marker', 'none');
        shadedErrorBar(mean0.CarouselPos, mean0.PupilArea(i,:), se.PupilArea(i,:) )
        set(gca, 'xlim',[0 360], 'xtick', 0:90:360, 'xticklabels', 0:90:360 )
        set(gca, 'ylim', clim.*[0.9 1.0], 'ytick', clim(1):25:clim(2), 'yticklabels', clim(1):25:clim(2))
        xlabel('Carousel angular position (degrees)')
        if i==1
            ylabel('Mean run speed, (?, SE)')
        end
    end
    
    %loop acros blocks
    
    %Common title
    str = { sprintf('Run Speed, (?)')};
    suptitle2(str, 0.92, 0);
    
    %Format
    AxisPropForIllustrator(12);
end

%% EYE POSITION
[session, behavior]=loadSession(fileBase);
nBlocks = session.info.nBlocks;

for nV = 26
    % Finding min and max for pupil area (for graph)
    tmp=[];
    for i = 1:nBlocks
        tmp = [tmp; A(nV).tun{i}(:)];
    end
    clim = round([min(tmp) max(tmp)]);
    clear tmp
    
    %additional variable
    nTrials = size(A(nV).tun{1},2);
    
    %Calculating for mean
    clear mean0 sd se
    for i = 1:nBlocks
        mean0.n = nTrials;
        mean0.CarouselPos = 1:360;
        mean0.PupilArea(i,:) = mean(A(nV).tun{i}');
        sd.PupilArea(i,:) = std(A(nV).tun{i}');
        se.PupilArea(i,:) = sd.PupilArea(i,:) / sqrt(mean0.n);
    end
    
    figure
    for i = 1:nBlocks
        
   % licking activity PLOT
        subplot(4,3,i+0);
        imagesc(A(nV).tun{i}', clim);
        colorbar
        set(gca, 'xlim',[0 360], 'xtick', 0:90:360, 'xticklabels', 0:90:360 )
        set(gca, 'ylim',[1 nTrials], 'ytick', 1:4:nTrials, 'yticklabels', 1:4:nTrials)
        title({ sprintf('Block-%d',i)});
        %legend('show')
        %xlabel('Carousel angular position (degrees)')
        if i==1
            ylabel('Trials')
        end
        
        subplot(4,3,i+3); cla; hold on
        plot(A(nV).tun{i});
        set(gca, 'xlim',[0 360], 'xtick', 0:90:360, 'xticklabels', 0:90:360 )
        set(gca, 'ylim', clim.*[0.9 1.0], 'ytick', clim(1):10:clim(2), 'yticklabels', clim(1):10:clim(2))
        %xlabel('Carousel angular position (degrees)')
        if i==1
            ylabel('Pupil pisotion, (?)')
        end
        
        subplot(4,3,i+6); cla; hold on
        %         plot(mean0.CarouselPos, mean0.PupilArea(i,:), 'color','k', 'linestyle','-', 'linewidth', 1, 'marker', 'none');
        shadedErrorBar(mean0.CarouselPos, mean0.PupilArea(i,:), se.PupilArea(i,:) )
        set(gca, 'xlim',[0 360], 'xtick', 0:90:360, 'xticklabels', 0:90:360 )
        set(gca, 'ylim', clim.*[0.9 1.0], 'ytick', clim(1):10:clim(2), 'yticklabels', clim(1):10:clim(2))
        xlabel('Carousel angular position (degrees)')
        if i==1
            ylabel('Mean pupil position, (?, SE)')
        end
    end
    
    %loop acros blocks
    
    %Common title
    str = { sprintf('Pupil position, (?)')};
    suptitle2(str, 0.92, 0);
    
    %Format
    AxisPropForIllustrator(12);
end

%% WHISKERS (pc1)
[session, behavior]=loadSession(fileBase);
nBlocks = session.info.nBlocks;

for nV = 78 %(%79)
    % Finding min and max for pupil area (for graph)
    tmp=[];
    for i = 1:nBlocks
        tmp = [tmp; A(nV).tun{i}(:)];
    end
    clim = round([min(tmp) max(tmp)]);
    clear tmp
    
    %additional variable
    nTrials = size(A(nV).tun{1},2);
    
    %Calculating for mean
    clear mean0 sd se
    for i = 1:nBlocks
        mean0.n = nTrials;
        mean0.CarouselPos = 1:360;
        mean0.PupilArea(i,:) = mean(A(nV).tun{i}');
        sd.PupilArea(i,:) = std(A(nV).tun{i}');
        se.PupilArea(i,:) = sd.PupilArea(i,:) / sqrt(mean0.n);
    end
    
    figure
    for i = 1:nBlocks
        
   % licking activity PLOT
        subplot(4,3,i+0);
        imagesc(A(nV).tun{i}', clim);
        colorbar
        set(gca, 'xlim',[0 360], 'xtick', 0:90:360, 'xticklabels', 0:90:360 )
        set(gca, 'ylim',[1 nTrials], 'ytick', 1:4:nTrials, 'yticklabels', 1:4:nTrials)
        title({ sprintf('Block-%d',i)});
        %legend('show')
        %xlabel('Carousel angular position (degrees)')
        if i==1
            ylabel('Trials')
        end
        
        subplot(4,3,i+3); cla; hold on
        plot(A(nV).tun{i});
        set(gca, 'xlim',[0 360], 'xtick', 0:90:360, 'xticklabels', 0:90:360 )
        set(gca, 'ylim', clim.*[0.9 1.0], 'ytick', clim(1):10:clim(2), 'yticklabels', clim(1):10:clim(2))
        %xlabel('Carousel angular position (degrees)')
        if i==1
            ylabel('Whiskers movements, (?)')
        end
        
        subplot(4,3,i+6); cla; hold on
        %         plot(mean0.CarouselPos, mean0.PupilArea(i,:), 'color','k', 'linestyle','-', 'linewidth', 1, 'marker', 'none');
        shadedErrorBar(mean0.CarouselPos, mean0.PupilArea(i,:), se.PupilArea(i,:) )
        set(gca, 'xlim',[0 360], 'xtick', 0:90:360, 'xticklabels', 0:90:360 )
        set(gca, 'ylim', clim.*[0.9 1.0], 'ytick', clim(1):10:clim(2), 'yticklabels', clim(1):10:clim(2))
        xlabel('Carousel angular position (degrees)')
        if i==1
            ylabel('Mean of whiskers movements, (?, SE)')
        end
    end
    
    %loop acros blocks
    
    %Common title
    str = { sprintf('Whiskers movements, (?)')};
    suptitle2(str, 0.92, 0);
    
    %Format
    AxisPropForIllustrator(12);
end


%% 
%mkdir2([ FigPathCommon mfilename ])
%SaveForIllustrator( [FigPathCommon mfilename '/' FileOut],'jpg')
%export_fig([FigPathCommon mfilename '/' FileOut], '-jpeg', '-nocrop', '-transparent', '-m2')
%fprintf('DONE\n')


%%DRAFT
mean(t(1:20,:))
for m = 1: 20: 340
    mean(t(m:m+19,:))
end
