function processFramePupil_v1(data,width,height,frameNr,time)
% processFrame(data,width,height,frameNr)
%
% This is the function prototype to be used by the matlabCommand option of
% mmread.
% INPUT
%   data        the raw captured frame data, the code below will put it
%               into a more usable form
%   width       the width of the image
%   height      the height of the image
%   frameNr     the frame # (counting starts at frame 1)
%   time        the time stamp of the frame (in seconds)
%
% Warning, the way that this is implemented requires buffering about 1
% seconds worth of video.  If you don't have enough memory in your system
% to hold 1 second's worth of video, this will crash on you.  Either make
% your movies smaller, or buy more memory.
% 
% EXAMPLES
%   Process all frames in a movie using this function:
%   mmread('mymovie.mpg',[],[],false,false,'processFrame');
%
%   Process only frames 1 through 10 using this function:
%   mmread('mymovie.mpg',1:10,[],false,false,'processFrame');
% 
% Copyright 2008 Micah Richert
% 
% This file is part of mmread.
% 
% mmread is free software; you can redistribute it and/or modify it
% under the terms of the GNU Lesser General Public License as
% published by the Free Software Foundation; either version 3 of
% the License, or (at your option) any later version.
% 
% mmread is distributed WITHOUT ANY WARRANTY.  See the GNU
% Lesser Lesser General Public License for more details.
% 
% You should have received a copy of the GNU Lesser General Public
% License along with this program.  If not, see
% <http://www.gnu.org/licenses/>.
%disp 'here'
persistent warned; 
global pupilInit;
global tracked;
global flagND;
global frameTimes;
global prevFr;
global blI; % 'blink metric'
global fwb; % handle to wait bar
global movI;% 'movement metric'
global dataPrev;
global frames;
global verbose;
global fig_num;
global r_z;
global dnsmpl;
global framesTotal;
try
    scanline = ceil(width*3/4)*4; % the scanline size must be a multiple of 4.

    % some times the amount of data doesn't match exactly what we expect...
    if (numel(data) ~= scanline*height)
        if (numel(data) > 3*width*height)
            if (isemtpy(warned))
                warning('mmread:general','dimensions do not match data size. Guessing badly...');
                warned = true;
            end
            scanline = width*3;
            data = data(1:3*width*height);
        else
            error('dimensions do not match data size. Too little data.');
        end
    end

% if there is any extra scanline data, remove it
    data = reshape(data,scanline,height);
    data = data(1:3*width,:);

% the data ordering is wrong for matlab images, so permute it
    data = double(permute(reshape(data, 3, width, height),[3 2 1]));
    data = data(:,:,1);
    if dnsmpl
        data = data([1:2:end],[1:2:end],1); % downsample the image
    end
    
%frameNr
% whole frame diff to extract amount of movement
    if frameNr == 1
        dataPrev = data;
    elseif ~isempty(frames) 
        if frameNr ==frames(1); dataPrev = data; end
    end
    movI(frameNr) = mean2(abs(sq(data(:,:,1)) - dataPrev))/255;
    dataPrev = data;
    
% here we look for the pupil NP
    trackSuccess = 0;
    if dnsmpl
        rct = floor(pupilInit.rct./2); %
    else
        rct = pupilInit.rct;
    end
    thr = pupilInit.thr;
    Icr = data(rct(2):rct(2)+rct(4),...
    rct(1):rct(1)+rct(3),1);
    framesize = size(Icr);
    x = nan(framesize(1),framesize(2));
    
% smooth the subframe
    r_hat = 2;
    r_r = -2:2;
    r_z = bsxfun(@plus,r_r'.^2, r_r.^2);
    r_z = r_z/sum(r_z(:));
    x(:,:) = conv2(Icr(:,:),r_z,'same');% smooth a bit
%     x(:,:) = Icr(:,:);
    
% normalise subframe
    G_data = x;
    G_data = G_data(5:(end-5),5:(end-5));
    %frCx = size(G_data,2);
    %frCy = size(G_data,3);    
    ctr = @(x)(x-min(x(:))/(max(x(:))-min(x(:))));
    
% do a percentile thresholding to avoid hard threshold
    nclu = 6;%
    tmp_data = G_data;
    tmpscale = prctile(tmp_data(:),[thr]);
    G_data = rescale(tmp_data,tmpscale);
    tmp_data1 = G_data(:,:);
    % cluster pixels using kmeans
    [u,C,ntmp_data] = smoothKNNgray(tmp_data1,nclu);%,u_init(:,nclu)
    tmp_u = reshape(u==1,size(ntmp_data));
    
% detect regions of interest
    tmp_u = bwareaopen(tmp_u,180); % lower bound to what constitutes a pupil
    out_a=regionprops(tmp_u,'Area','Centroid','BoundingBox','MajorAxisLength','MinorAxisLength','Orientation');
    N=size(out_a,1);
    [frCx, frCy]=size(tmp_data);
    if N>1
        trackSuccess = 1;
        % compute 'circleness'
        rAxes=[out_a.MajorAxisLength]./[out_a.MinorAxisLength]; %most circular ROI        
        % compute 'centerdness'
        for i = 1:N
            cntr(i) = (out_a(i).Centroid(1) - frCx)^2+(out_a(i).Centroid(2) - frCy)^2;
        end
        % compute product of circleness and centerdness
        [~,idx] = min(cntr.*rAxes);
%         [~,idx] = min(cntr);
        clear cntr rAxes;
    elseif N == 1
        idx = 1;
        trackSuccess = 1;
    end
    if trackSuccess 
        %out_a(idx)
        tracked(frameNr) = out_a(idx(1));
        %tracked(frameNr).times = time;
        frameTimes(frameNr) = time;
    else
        %disp 'no detection';
        flagND(length(flagND)+1) = frameNr;
    end
    if verbose
        figure(fig_num);
        clf;
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
        colormap(gray);
        subplot(131);
        imagesc(tmp_data); hold on; plot(x,y,'color',[1 0 0 0.5],'LineWidth',2); axis equal;%alpha(.5); axis off;    
        
        subplot(132);
        imagesc(tmp_data1); hold on; plot(x,y,'color',[1 0 0 0.5],'LineWidth',2); axis equal;%alpha(.5); axis off;
        im2shows = repmat(ctr(tmp_data)*.5,1,1,3);% repmat for the convinence of using imshow

        im2shows(:,:,3)= tmp_u;
        im2shows(:,:,1)=reshape(u==nclu,size(ntmp_data));
        subplot(133); subadd = imshow(im2shows);hold on; plot(x,y,'color',[1 0 0 0.5],'LineWidth',2); %alpha(.5); axis off;
        title(int2str(frameNr));
        drawnow;
    end
    
% frame difference for movement detection
    if frameNr == 1; prevFr = x; end
    blI(frameNr) = mean2(abs(prevFr-sq(x)))./255;
    prevFr = x;    
    waitbar(frameNr/framesTotal,fwb,[num2str((100*(frameNr/framesTotal)),3),' % processed']); %     waitbar(frameNr/pupilInit.nrFrames,fwb,[num2str(round(frameNr/pupilInit.nrFrames)),'% processed']);
    drawnow;
catch
    % if we don't catch the error here we will loss the stack trace.
    err = lasterror;
    disp([err.identifier ': ' err.message]);
    for i=1:length(err.stack)
        disp([err.stack(i).file ' (' err.stack(i).name ') Line: ' num2str(err.stack(i).line)]);
    end
    rethrow(err);
end