function [pupilInit] = initPupilDetection_v1(fileName)
%% 
if nargin > 1
    error('please provide only one input variable; filename of video to be processed');
end
close
tic;
MSGID = 'images:imfindcircles:warnForLargeRadiusRange';
warning('off', MSGID)
keepLooking = 1; frame = 1; verbose = 1; incr = 0.01;
try
    [video, audio] = mmread(fileName,[1]);
    nrFrames = abs(video.nrFramesTotal);
%     frames = round(linspace(1,nrFrames,10));
    frames = 1; % force to onl one frame as loading multiple scattered frames is REALLY slow
%     [video, audio] = mmread(fileName,[frames]);
catch
    error('mmread error. Try running mmread directly for more error info')
end


I = video.frames(1).cdata(:,:,1);
figure('pos',[783   -88   960   456]);
subplot(331); imagesc(I); title('original'); colormap gray;
fprintf(2,'\nPlease draw rectangle over pupil with pupil close to the center') 
fprintf(2,'\nMust start from top left\n') 
rct = getrect(gcf);
disp 'Thanks, the coordinates are:'
rct = floor(rct);
rct
Icr = I(rct(2):rct(2)+rct(4),...
    rct(1):rct(1)+rct(3),:);
subplot(332); imagesc(Icr); title('cropped');

if size(Icr,3)==3
Icr=rgb2gray(Icr);
end    
subplot(333); imagesc(Icr); colormap('gray'); title('grayscale');
disp 'Decting pupil, standby for confirmation...'
close all;  

%% ACTUAL DETECTION
success = 0; thr = 0.5;
while ~success
k = 1;
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
    
% detect regions of interest
    tmp_u = bwareaopen(tmp_u,140); % lower bound to what constitutes a pupil
    out_a=regionprops(tmp_u,'Area','Centroid','BoundingBox','MajorAxisLength','MinorAxisLength','Orientation');
    N=size(out_a,1);
    trackSuccess = 0;
    if N>1
        trackSuccess = 1;
        % compute 'circleness'
        rAxes=[out_a.MajorAxisLength]./[out_a.MinorAxisLength]; %most circular ROI        
        % compute 'centerdness'
        for i = 1:N
            cntr(i) = (out_a(i).Centroid(1) - frCx)^2 + (out_a(i).Centroid(2) - frCy)^2;
        end
        % compute product of circleness and centerdness
        %[~,idx] = min(cntr.*rAxes);
        [~,idx] = min(cntr);
        clear cntr rAxes;
    elseif N == 1
        idx = 1;
        trackSuccess = 1;
    end
    if trackSuccess 
        out_a(idx)
    else
        disp 'no detection';
        pupilInit.rct = nan;
        pupilInit.thr = nan;
        pupilInit.nrFrames = nan;
        return;    
    end
% plot for user to approve  
    % create ellipse using out_a features
    phi = linspace(0,2*pi,50);
    cosphi = cos(phi);
    sinphi = sin(phi);
    xbar = out_a(idx).Centroid(1);
    ybar = out_a(idx).Centroid(2);
    a = out_a(idx).MajorAxisLength/2;
    b = out_a(idx).MinorAxisLength/2;
    theta = pi*out_a(idx).Orientation/180;
    R = [ cos(theta)   sin(theta)
         -sin(theta)   cos(theta)];
    xy = [a*cosphi; b*sinphi];
    xy = R*xy;
    x = xy(1,:) + xbar;
    y = xy(2,:) + ybar;
    %
    %fig_num = figure('pos',[-1382 803 1310 460]);% make sure you have figure open.
    fig_num = figure('pos',[783   -88   960   456]);
    colormap(gray);
    subplot(length(frames),3,3*k-2)
    imagesc(tmp_data); hold on; plot(x,y,'color',[1 0 0 0.5],'LineWidth',2); %alpha(.5); axis off;    
    subplot(length(frames),3,3*k-1)
    imagesc(tmp_data1); hold on; plot(x,y,'color',[1 0 0 0.5],'LineWidth',2); %alpha(.5); axis off;
    im2shows = repmat(ctr(tmp_data)*.5,1,1,3);% repmat for the convinence of using imshow
    subplot(length(frames),3,3*k);
    im2shows(:,:,3)= tmp_u;
    im2shows(:,:,1)=reshape(u==nclu,size(ntmp_data));
    subadd = imshow(im2shows);%ntmp_data.*reshape(u==2,size(ntmp_data)))
    
    subplot(length(frames),3,3); hold on; plot(x,y,'color',[1 0 0 0.5],'LineWidth',2); %alpha(.5); axis off;
    drawnow;
    
    %% ASK USER TO CONFIRM DETECTION
    disp 'Putative pupil has been marked';
    prompt = 'Does it look correct? [Y/N/abort]: ';
    figure(1);
    str = input(prompt,'s');
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
        return;        
    end  
end