function initialiseVideoAnalysis(fileBase)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function initialiseVideoAnalysis promps the user to define ROIs for the
% video analysis which are a prerequisite to all the video analysis except
% those for nose that use DeepLabCut. Pupil is also detected in deeplabcut
% on top of the pupil morpho detection. For the former a pupil video is
% generated here and saved inside the video subfolder of the session
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


if nargin == 0
    error('Cannot proceed without a fileBase - please provide');
end


%% look for videos
    
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
    
    
%% initialise the ROIs for later processing

    if flag(1) 
        trackPupilMorpho(fileBase,1,0);
        subFrameSVD(fileBase);
    end
    if flag(2)
        trackWhiskersGabor(fileBase);
    end
    
    
%% a figure showing the ROIs for summary visualisation
    % load the ROIs
    figure;

    face = load(fullfile(getfullpath(fileBase),'faceROIs'));
    whisker = load(fullfile(getfullpath(fileBase),'whiskerROIs'));

    % plot first frame for side
    subplot(121);
    imagesc(rgb2gray(im2double(obj1.readFrame))); hold on; axis equal; colormap gray;
    % add the side ROIs:
    for  i = 1:length(face.ROI.names)
        rectangle('Position',face.ROI.pts(i,:),'EdgeColor','r','LineWidth',2,'LineStyle','--');
    end



    % plot first frame for top
    subplot(122);
    imagesc(rgb2gray(im2double(obj2.readFrame))); hold on; axis equal; colormap gray;
    % add the top ROIs:
    for  i = 1:length(whisker.ROI.names)
        rectangle('Position',whisker.ROI.pts(i,:),'EdgeColor','r','LineWidth',1.5,'LineStyle','--');end

    print(gcf,fullfile(getfullpath(fileBase),'ROI_definitions.jpg'),'-djpeg','-r600');
    
    
%% generate pupil video that feeds into deeplabcut
%     goto(fileBase);    
%     load faceROIs.mat; % obviousy only works if previous ROIs were defined using subFrameSVD.m
%     roi = ROI.pts(find(strcmp(ROI.names,'eye')),:);
%     cd ../video
%     d=dir('side*.avi');
%     if length(d) == 1        
%         phrase = ['ffmpeg -i ', fullfile(d.folder,d.name), ' -filter:v "crop=',num2str(roi(3)),':',...
%             num2str(roi(4)),':',num2str(roi(1)),':',num2str(roi(2)),'" -c:a copy ',fullfile(d.folder,[fileBase,'_pupil.avi'])];
%         system([phrase]);
%     end

    
%% insert file to be processed into expected text file list (FOR PUPIL)
fid = fopen('/storage2/perentos/data/pupil3-NP-2020-10-16/paths_to_analysis_vids.txt','a');
%T = getCarouselDataBase;        
%allFileBases = [T.session];
%sesh = find(strcmp(allFileBases,fileBase));
% create paths to all pupil videos to be analysed
goto(fileBase);
cd ../video
d=dir('*pupil.avi');
if length(d) == 1        
    fprintf( fid, '%s\n', fullfile(d.folder,d.name));
end
fclose(fid);     
    
%% insert file to be processed into expected text file list (FOR NOSE)    
% the following came from generateDLCpaths.m which basically ran this for
% the whole database. It is somewhat redundant here but included for
% completeness
% fle = dir(fullfile(getFullPath(fileBase),'video/top*.avi'));
% if length(fle) == 1
%     fprintf( fid, '%s\n', fullfile(fle.folder,fle.name));
% end    
% fclose(fid);


%% check if DLC pickles were generated and inform user if they do or don't 
%need to jump to python before next steps

fle1 = dir(fullfile(getFullPath(fileBase),'video/top*.pickle'));
fle2 = dir(fullfile(getFullPath(fileBase),['video/',fileBase,'*.pickle']));
if length(fle1) == 1 & length(fle2) == 1
    display('you can now proceed with runVideoAnalysis.m (*** deeplabcut files already generated ***)');
else
    display 'you are missing at least one deeplabcut file set. Please generate before executing runVideoAnalysis.m'
    display 'go to spike sorter'
    display 'conda deactivate'
    display 'cd /opt/py36'
    display 'source bin/activate'
    display 'python /storage2/perentos/code/python/DLC_batch_process.py'
    display 'python /storage2/perentos/data/pupil3-NP-2020-10-16/pupil_9pt_DLC_batch_process.py'
end    
    
    
    