function trackPupilVideoReader(fldrName,init,track, frams, downSampleFlag, verb)
% written by NPerentos 10/10/2018

%% SETUP
reInit = 0;
MSGID = 'images:imfindcircles:warnForLargeRadiusRange';
warning('off', MSGID);
MSGID = 'images:imfindcircles:warnForSmallRadius';
warning('off', MSGID);
% MSGID ='You just called IMFINDCIRCLES with very small radius value(s). Algorithm accuracy is limited for radius values less than 1';
% warning('off', MSGID);

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
% look for the pupil video 
fullPath = getFullPath(fldrName);
test = (dir(fullfile(fullPath,'side*.avi')));
if ~size(test,1)
    error('there is no pupil video file .. aborting');
elseif size(test,1) == 1
    disp 'found a pupil file; continuing with data processing...'
    fileName = [test.folder,'/',test.name];
    [pth,fle,ext] = fileparts(fileName);
end

if ~exist([pth,'/processed'])
    disp 'making folder'
    mkdir([pth,'/processed'])
end

%get video details/properties
obj = VideoReader(fileName);
nrFrames = obj.Duration;

%% INITIALISE PUPIL DETECTION ROUTINE
if init
    % check if this processing has already been done
    if exist([pth,'/processed/pupilInit.mat'],'file')
        msg = 'pupil detection initialisation already exist. Rerun? [Y/N]';
        s = input(msg,'s');
        if s == 'y' | s == 'Y' 
            reInit = 1;
        elseif s == 'n' | s == 'N'
            load ([pth,'/processed/pupilInit.mat']);
        end
    else
        reInit = 1;
    end
elseif ~init
    if exist([pth,'/processed/pupilInit.mat'],'file')
        load ([pth,'/processed/pupilInit.mat']);
    else
        disp 'no initialisation parameters found will generate';
        reInit = 1;
    end
end
        
if reInit
    disp 'Initialising...'           
    vidFrame = readFrame(obj);
    I = vidFrame(:,:,1);
    figure('pos',[783   -88   960   456]);
    imagesc(I); title('original'); colormap gray; axis equal;
    fprintf(2,'\nPlease draw rectangle over pupil with pupil close to the center') 
    fprintf(2,'\nMust start from top left\n') 
    rct = getrect(gcf);
    disp 'Thanks, the coordinates are:'
    rct = floor(rct);
    rct
    Icr = I(rct(2):rct(2)+rct(4),rct(1):rct(1)+rct(3),:);
    imagesc(Icr); title('cropped');
    disp 'Decting pupil, standby for confirmation...'
    pause(1);close all;  

% detection optimisation
    success = 0; thr = 0.5;
    while ~success
        framesize = size(Icr);
        x = nan(framesize(1),framesize(2));
    % smooth the subframe
        r_hat = 2;
        r_r = -1:1;
        r_z = bsxfun(@plus,r_r'.^2, r_r.^2);
        r_z = r_z/sum(r_z(:));
        x(:,:) = conv2(double(Icr(:,:)),r_z,'same');% smooth a bit
        %x(:,:) = double(Icr(:,:));
    % normalise subframe
        G_data = x;
        G_data = G_data(5:(end-5),5:(end-5));
        frCx = size(G_data,1)/2;
        frCy = size(G_data,2)/2;    
        ctr = @(x)(x-min(x(:))/(max(x(:))-min(x(:))));

    % do a percentile thresholding to avoid hard threshold
        nclu = 6;%
        tmp_data = G_data;
        tmpscale = prctile(tmp_data(:),[thr, 25]);
        G_data = rescale(tmp_data,tmpscale);
        tmp_data1 = G_data(:,:);
        % cluster pixels using kmeans
        [u,C,ntmp_data] = smoothKNNgray(tmp_data1,nclu);%,u_init(:,nclu)
        tmp_u = reshape(u==1,size(ntmp_data));
    % detect ROIs
        [centers,radii] = imfindcircles(tmp_u,[5 20],'ObjectPolarity','bright','sensitivity',0.8);
        N = length(radii)
        trackSuccess = 0;
        if N>1
            trackSuccess = 1;
            for i = 1:N
                cntr(i) = (centers(i,1) - frCx)^2 + (centers(i,2) - frCy)^2;
            end
            % compute product of circleness and centerdness
            [~,idx] = min(cntr);
            clear cntr rAxes;
        elseif N == 1
            idx = 1;
            trackSuccess = 1;
        end
        if ~trackSuccess 
            disp 'no detection';
            pupilInit.rct = nan;
            pupilInit.thr = nan;
            pupilInit.nrFrames = nan;
            return;    
        end
% user confirmation
        fig_num = figure('pos',[783   -88   960   456]); colormap(gray);

        subplot(1,3,1)
        imagesc(tmp_data); hold on; h = viscircles(centers(idx,:),radii(idx));axis equal; 

        subplot(1,3,2)
        imagesc(tmp_data1); hold on; h = viscircles(centers(idx,:),radii(idx));axis equal;

        subplot(1,3,3);
        im2shows = repmat(ctr(tmp_data)*.5,1,1,3);% repmat for the convinence of using imshow
        im2shows(:,:,3)= tmp_u;
        im2shows(:,:,1)=reshape(u==nclu,size(ntmp_data));
        subadd = imshow(im2shows);h = viscircles(centers(idx,:),radii(idx));
        drawnow;
        
        disp 'Putative pupil has been marked';
        prompt = 'Does it look correct? [Y/N/abort]: ';
        figure(1);
        str = input(prompt,'s');
        gcf;
        while isempty(str)
            disp 'must enter 'y' or 'n' or 'abort'. Try again'
            str = input(prompt,'s');
        end
        if str == 'y'        
            pupilInit.rct = rct;
            pupilInit.thr = [thr, 25];
            pupilInit.nrFrames= nrFrames;
            close all;
            success = 1;
            continue;
        elseif str =='n'
            %error('unsuccesful detection check file and consider editing the code');
            disp 're-trying...';
            thr = thr+1; close;
        elseif str == 'abort'
            pupilInit.rct = nan;
            pupilInit.thr = nan;
            pupilInit.nrFrames = nan;
            error('nothing was detected - please investigate');
            return;        
        end  
    end
    save([pth,'/processed/pupilInit.mat'],'pupilInit');
    disp('OK, subframe coordinates and threshold saved for later processing');
else
    disp 'OK -- will use existing detection criteria';
end


%% PROCESS ALL FRAMES
disp 'scanning all frames...'
tic
r_hat = 2;
r_r = -1:1;
r_z = bsxfun(@plus,r_r'.^2, r_r.^2);
r_z = r_z/sum(r_z(:));
res = nan(pupilInit.nrFrames,3);
wb = waitbar(0,'% frames processed');
if verb; fig_num = figure('pos',[483   -88   960   456]); colormap(gray); end
cFr = 0;
while hasFrame(obj)
    vidFrame = readFrame(obj);
    cFr = cFr + 1;
    I = vidFrame(:,:,1);
    Icr = I(pupilInit.rct(2):pupilInit.rct(2)+pupilInit.rct(4),pupilInit.rct(1):pupilInit.rct(1)+pupilInit.rct(3),:);
    framesize = size(Icr);
    x = nan(framesize(1),framesize(2));
% smooth the subframe
    x(:,:) = conv2(double(Icr(:,:)),r_z,'same');
% normalise subframe
    G_data = x;
    G_data = G_data(5:(end-5),5:(end-5));
    frCx = size(G_data,1)/2;
    frCy = size(G_data,2)/2;    
    ctr = @(x)(x-min(x(:))/(max(x(:))-min(x(:))));
% do a percentile thresholding to avoid hard threshold
    nclu = 6;%
    tmp_data = G_data;
    tmpscale = prctile(tmp_data(:),[pupilInit.thr, 25]);
    G_data = rescale(tmp_data,tmpscale);
    tmp_data1 = G_data(:,:);
    % cluster pixels using kmeans
    [u,C,ntmp_data] = smoothKNNgray(tmp_data1,nclu);%,u_init(:,nclu)
    tmp_u = reshape(u==1,size(ntmp_data));
    % detect ROIs
    [centers,radii,metric] = imfindcircles(tmp_u,[5 40],'ObjectPolarity','bright','sensitivity',0.75);
    N = length(radii);
    trackSuccess = 0;
    if N>1
        trackSuccess = 1;
        for i = 1:N
            cntr(i) = (centers(i,1) - frCx)^2 + (centers(i,2) - frCy)^2;
        end
        % compute product of circleness and centerdness
        [~,idx] = min(cntr);
        clear cntr rAxes;
    elseif N == 1
        idx = 1;
        trackSuccess = 1;
    end
    if ~trackSuccess 
        disp 'no ROI detected';
    end
    % store the data
    if trackSuccess
        res(cFr,1) = radii(idx);
        res(cFr,2) = centers(idx,1);
        res(cFr,3) = centers(idx,2);      
        res(cFr,4) = metric(idx,1); 
    end
    % plot for user to approve  
    if verb & trackSuccess     
        clf;
        subplot(1,3,1)
        imagesc(tmp_data); hold on; h = viscircles(centers(idx,:),radii(idx));axis equal; 

        subplot(1,3,2)
        imagesc(tmp_data1); hold on; h = viscircles(centers(idx,:),radii(idx));axis equal;

        subplot(1,3,3);
        im2shows = repmat(ctr(tmp_data)*.5,1,1,3);% repmat for the convinence of using imshow
        im2shows(:,:,3)= tmp_u;
        im2shows(:,:,1)=reshape(u==nclu,size(ntmp_data));
        subadd = imshow(im2shows);h = viscircles(centers(idx,:),radii(idx));
        drawnow;    
    end
    waitbar(cFr/pupilInit.nrFrames,wb, [int2str(cFr),'/',int2str(pupilInit.nrFrames)]);
    if cFr == 1000; break; end
end
toc
save([pth,'/processed/','pupilRes.mat'],'res');
disp(['done processing file:  ', pth,'/processed/','pupilRes.mat', ' has been saved']);
close(wb);