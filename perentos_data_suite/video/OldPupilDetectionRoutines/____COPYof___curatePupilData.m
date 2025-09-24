function [smoothedPupilData] = curatePupilData(fldr,report,ifSaveFig)
flagProcess = 1; flag1 = 0; flag2 = 0;

%% CHECK STATE OF DATA
if nargin < 1
    error('Cannot proceed without a folder name...');
end

try
    fullPath = getFullPath(fldr);
catch
    error('there is no such folder ... aborting')
end

cd(fullPath); cd processed;

if exist('pupilResults.mat') == 2 % the results file exists
    test = whos('-file','pupilResults.mat');
    test = {test.name};
    % cycle through var names to see if the ones of interest exist
    for i = 1:length(test)
        if strcmp(test(i),'pupilResults')
            flag1 = 1;
        end
        if strcmp(test(i),'smPupilResults')
            flag2 = 1;
        end
    end
    if flag1 & flag2
        disp('curated data exists so skipping to the plots (if requested)...');
        flagProcess = 0;
        load('pupilResults.mat');
    else
        load('pupilResults.mat');
    end
else 
    disp('the pupil results file is missing ... please generate first...');
    disp('aborting for now ...');
    disp('this can be generated using the trackPupil_v1.m function ...');
    return;
end   
% check lfp data size
clear test;
if exist('peripherals.mat') == 2 % the results file exists
    load peripherals.mat tScale;
else
    disp('cannot find tScale variable. Cannot resample the data...')
end



%% FIX PUPIL RESULTS STRUCTURE
if flagProcess
    disp '>...reconfiguring data structures<';
    x = [tracked.MajorAxisLength];
    pupilResults.MajorAxisLength = normalize_array(x(:))'; clear x;
    x = [tracked.MinorAxisLength];
    pupilResults.MinorAxisLength = normalize_array(x(:))'; clear x;
    x = [tracked.Area];
    pupilResults.Area = normalize_array(x(:))'; clear x;
    centroid = [tracked.Centroid];
    x = centroid(1:2:end);
    pupilResults.CentroidX = normalize_array(x(:))'; clear x;
    x = centroid(2:2:end);
    pupilResults.CentroidY = normalize_array(x(:))'; clear x;
    pupilResults.blI = zscore(blI);
    pupilResults.movI = zscore(movI);
    pupilResults.frameTimes = frameTimes;
end


%% SMOOTH & UPSAMPLE TO MATCH THE LFP SAMPLING RATE (1000Hz)
if flagProcess
    disp '>...data imported ... now smoothing and upsampling...<';
    pupilTimes = linspace(0,max(tScale),length(frameTimes));

    lSm = 10;
    x = [tracked.MajorAxisLength];
    smPupilResults.MajorAxisLength = smooth(normalize_array(x(:)),lSm,'rlowess')'; clear x;
    smPupilResults.MajorAxisLength = interp1(pupilTimes,smPupilResults.MajorAxisLength,tScale); 
    
    
    x = [tracked.MinorAxisLength];
    smPupilResults.MinorAxisLength = smooth(normalize_array(x(:)),lSm,'rlowess')'; clear x;
    smPupilResults.MinorAxisLength = interp1(pupilTimes,smPupilResults.MinorAxisLength,tScale); 
    
    x = [tracked.Area];
    smPupilResults.Area = smooth(normalize_array(x(:)),lSm,'rlowess')'; clear x;
    smPupilResults.Area = interp1(pupilTimes,smPupilResults.Area,tScale);     
    
    centroid = [tracked.Centroid];
    x = centroid(1:2:end);
    smPupilResults.CentroidX = smooth(normalize_array(x'),lSm,'rlowess')'; clear x;
    smPupilResults.CentroidX = interp1(pupilTimes,smPupilResults.CentroidX,tScale); 
    
    x = centroid(2:2:end);
    smPupilResults.CentroidY = smooth(normalize_array(x'),lSm,'rlowess')'; clear x;
    smPupilResults.CentroidY = interp1(pupilTimes,smPupilResults.CentroidY,tScale); 
    
    smPupilResults.blI = zscore(blI);
    smPupilResults.blI = interp1(pupilTimes,smPupilResults.blI,tScale); 
    
    smPupilResults.movI = zscore(movI);
    smPupilResults.movI = interp1(pupilTimes,smPupilResults.movI,tScale); 
    
    smPupilResults.frameTimes = frameTimes;
    smPupilResults.frameTimes = interp1(pupilTimes,smPupilResults.frameTimes,tScale); 
    
    s=whos('-file',[processedPath,'peripherals.mat']);
end

%% UPDATE PUPILRESULTS DATA FILE 
if flagProcess
    disp '>...saving data...<';
    save('pupilResults','smPupilResults','pupilResults','-append');
end

%% IF PLOT SUMMARY
if nargin > 1 & report
    
    figure;
    t = smPupilResults.frameTimes;
    tOld = pupilResults.frameTimes;
    tNew = smPupilResults.frameTimes;
    sb(1) = subplot(311); hold on;
    load('pupilInit.mat');
    plot(tOld,pupilResults.MajorAxisLength,'color',[.8 .8 .8],'linewidth',2); 
    h1 = plot(tNew,smPupilResults.MajorAxisLength);
    plot(tOld,pupilResults.MinorAxisLength,'color',[.8 .8 .8],'linewidth',2);
    h2 = plot(tNew,smPupilResults.MinorAxisLength);
    plot(tOld,pupilResults.Area,'color',[.8 .8 .8],'linewidth',2);        
    h3 = plot(tNew,smPupilResults.Area);
    legend([h1 h2 h3],'MajorAxis','MinorAxis','Area');
    
    sb(2) = subplot(312); hold on;
    
    plot(tOld,pupilResults.CentroidX./mean(pupilResults.CentroidX),'color',[.7 .7 .7],'linewidth',2); 
    h1 = plot(tNew,smPupilResults.CentroidX./mean(smPupilResults.CentroidX));
    plot(tOld,pupilResults.CentroidY./mean(pupilResults.CentroidY),'color',[.7 .7 .7],'linewidth',2); 
    h2 = plot(tNew,smPupilResults.CentroidY./mean(smPupilResults.CentroidY));
    legend([h1 h2],'CentroidX','CentroidY');
    
    sb(3) = subplot(313); hold on;
    
    plot(tNew,smPupilResults.blI); 
    plot(tNew,smPupilResults.movI);
    legend('blink index','movement index');
    set(gcf,'position',[1 22 2058 1237]);    
    linkaxes(sb,'x');
    mtit(['contrast thresholding:  ',num2str(pupilInit.thr(1)),' - ',num2str(pupilInit.thr(2)),' %']);
    processedPath = getfullpath(fldr);
    if nargin >2 & ifSaveFig
        print([getfullpath(fldr),'pupilSummary_',num2str(pupilInit.thr(1)),'-',num2str(pupilInit.thr(2))],'-djpeg','-r600');
    end
end