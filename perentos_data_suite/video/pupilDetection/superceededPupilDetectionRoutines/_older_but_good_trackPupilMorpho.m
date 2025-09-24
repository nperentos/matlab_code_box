function [out] = trackPupilMorpho(fileBase,init,track,frams)
% written by NPerentos 10/10/2018
% updates to actual computation and path management 25/10/2019

%% SETUP
reInit = 0; thrU = 9; thrL = 1;
MSGID = 'images:imfindcircles:warnForLargeRadiusRange';
warning('off', MSGID);
MSGID = 'images:imfindcircles:warnForSmallRadius';
warning('off', MSGID);
% MSGID ='You just called IMFINDCIRCLES with very small radius value(s). Algorithm accuracy is limited for radius values less than 1';
% warning('off', MSGID);

if nargin<3
    error('NEED at least 3 INPUTS: (1)filename, (2)init flag, and (3)track flag')
end

if nargin<4
    frams = [];
end
% look for the pupil video 
fullPath = fullfile(getFullPath(fileBase),'video');
test = (dir(fullfile(fullPath,'side*.avi')));
if ~size(test,1)
    warning('there is no pupil video file .. skipping session');
    return;
elseif size(test,1) == 1
    disp 'found a pupil file; continuing with data processing...'
    fileName = [test.folder,'/',test.name];
    [pth,fle,ext] = fileparts(fileName);
end

if ~exist(fullfile(getFullPath(fileBase),'/processed'))
    disp 'making folder'
    mkdir([pth,'/processed'])
end
pth = getFullPath(fileBase);% override pth above after some changes - could tidy up
%get video details/properties
obj = VideoReader(fileName);
nrFrames = obj.Duration;


%% INITIALISE PUPIL DETECTION ROUTINE
if init
    % check if this processing has already been done
    if exist([pth,'/processed/pupilInit.mat'],'file')
        %msg = 'pupil detection initialisation already exist. Rerun? [Y/N]';
        %s = input(msg,'s');
        %if s == 'y' | s == 'Y' 
        %    reInit = 1;
        %elseif s == 'n' | s == 'N'
            load ([pth,'/processed/pupilInit.mat']);
        %end
    else
        reInit = 1;
    end
elseif ~init
    if exist([pth,'/processed/pupilInit.mat'],'file')
        load ([pth,'/processed/pupilInit.mat']);
        disp 'proceeding with existing detection parameters';
    else
        disp 'no initialisation parameters found will generate';
        reInit = 1;
    end
end
        
if reInit
    disp 'Initialising...'  
    if nargin>3
        display(['a special frame was requested',int2str(frams)]);
        obj.CurrentTime = frams;
    end
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
    figure('color','k');

% detection optimisation
    success = 0; 
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
        G_data = x(5:(end-5),5:(end-5));
        frCx = size(G_data,1)/2;
        frCy = size(G_data,2)/2;
        subplot(1,3,1); imshow(x,[0 150]); axis off equal; hold on;
    % do a percentile thresholding to avoid hard threshold
        %tmp_data = G_data;
        tmpscale = prctile(G_data(:),[thrL, thrU]);
        
        %G_data = rescale(tmp_data,tmpscale); %G_data =
        %mapVal(tmp_data,tmpscale); mapval is a replacement for rescale
        %because rescale was deleted at some point
    % morphometric operations     
        %Gb=G_data./max(G_data(:)); % normalise to 1
        %
         
        %imshow(Gb); axis off square; hold on;
        %Gb = imbinarize(Gb);         % binarise
        Gb = imbinarize(G_data,tmpscale(2));         % binarise
        bw = ~bwareaopen(~Gb,20);    % remove small regions (work on inverted image)
        %imshow(Gb,[]); 
        %se = strel('disk',6);        % fill in small diskoid gaps (light reflection)
        %bw = imclose(~bw,se);
    % find closed region boundaries    
        [B,L] = bwboundaries(~bw,'noholes'); % traces boundaries around closed regions
        subplot(1,3,2);
        if length(B)>0
                imshow(label2rgb(L, @jet, [.5 .5 .5])); hold on;    
                for k = 1:length(B)
                    boundary = B{k};
                    plot(boundary(:,2), boundary(:,1), '.r', 'LineWidth', 2);
                    hold on;
                end
            % below can be simplified (but untested) by using only
            % circleness rather than weighting by centerdness
            stats = regionprops(L,'Area','Centroid','MajorAxisLength','MinorAxisLength','Perimeter');% ,'Solidity'
            for k = 1:length(B)
                metric(k) = 4*pi*stats(k).Area/stats(k).Perimeter;
            end
%             % extract properties of identified regions    
%             stats = regionprops(L,'Area','Centroid','MajorAxisLength','MinorAxisLength');% ,'Solidity'
%             diameters = mean([[stats.MajorAxisLength]; [stats(:).MinorAxisLength]]',2);
%             radii = diameters/2;
%             for k = 1:length(B)            
%                 centers(k,:) = [stats(k).Centroid(1),stats(k).Centroid(2)];           
%                 boundary = B{k}; % obtain (X,Y) boundary coordinates corresponding to label 'k'       
%                 delta_sq = diff(boundary).^2; % estimate perimeter
%                 perimeter = sum(sqrt(sum(delta_sq,2)));
%                 area = stats(k).Area;        
%                 metric(k) = 4*pi*area/perimeter^2; % roundness metric
%             end
%             % lets sort all regions according to the product of the metric(circleness)
%             % and inverse of distance from the center of the image
%             prd = (1./sqrt( (frCx-centers(:,2)).^2 + (frCy-centers(:,1)).^2 )).*metric';
%             [Y,I] = sort(prd,1,'descend');
            [Y,I] = sort(metric,1,'descend');
            idx = I(1); % index of the selected region 
            %
            subplot(1,3,3);
            imshow(bw); hold on;
            viscircles([centers(idx,1) centers(idx,2)],radii(idx));
            subplot(1,3,1);
            viscircles([centers(idx,1)+5 centers(idx,2)+5],radii(idx),'color','w','linewidth',1);
        % user confirmation
            disp 'Putative pupil has been marked';
            prompt = 'Does it look correct? [Y/N/q]: ';
            figure(1); pause(2);
            str = input(prompt,'s');
            while isempty(str)
                disp 'must enter 'y' or 'n' or 'q(quit)'. Try again'
                str = input(prompt,'s');
            end
            if str == 'y'  |  str == 'Y'     
                pupilInit.rct = rct;
                pupilInit.thr = [thrL, thrU];
                pupilInit.nrFrames= nrFrames;
                close all;
                success = 1;
                save([pth,'/processed/pupilInit.mat'],'pupilInit');
                disp('OK, subframe coordinates and threshold saved for later processing');
                continue;
            elseif str =='n' |  str == 'N'
                %error('unsuccesful detection check file and consider editing the code');
                %thrL = thrL+1;
                thrU = thrU-1; close;
                disp(['re-trying with thrU = ',num2str(thrU)]);
            elseif str == 'q' | str == 'Q'
                pupilInit.rct = nan;
                pupilInit.thr = nan;
                pupilInit.nrFrames = nan;
                error('nothing was detected - please investigate');
                return;        
            end  
        else
            disp 'no detection';            
            %thrL = thrL+1;
            thrU = thrU-1;close;
            disp(['re-trying with thrU = ',num2str(thrU)]);
        end
    end
end


%% PROCESS ALL FRAMES
if track & ~exist([pth,'/processed/','pupilRes.mat'])
    disp 'scanning all frames...'
    clear obj;
    tic
    load ([pth,'/processed/pupilInit.mat']);
    pupilInit
    %% run through all the frames on all 12 cores (gamma1)
    tic
        poolobj = gcp;
        addAttachedFiles(poolobj,{'processCurrentFrameMorpho.m'})
        spmd
            obj = VideoReader(fileName);
            nFr = round(obj.Duration*obj.FrameRate);
            % a = round((obj.Duration*obj.FrameRate)/12); %a = round(obj.Duration/12);
            r = linspace(1,nFr,13); r = round(r); %r(end) = [];
        % labindex 1    
            if labindex == 1
                % obj.CurrentTime = r(1)/obj.FrameRate-(1/obj.FrameRate);
                display(['Starting frame:  ',int2str(obj.CurrentTime)])
                to = r(2)
                for j = 1:to
                    if hasFrame(obj)
                        huo = readFrame(obj);
                        sect{j} = processCurrentFrameMorpho(huo,pupilInit);%huo(:,:,1);
                    else
                        break
                    end
                end
            end
        % labindex 2    
            if labindex == 2
                obj.CurrentTime = r(2)/obj.FrameRate-(1/obj.FrameRate);
                display(['Starting frame:  ',int2str(obj.CurrentTime)])
                to = r(2+1)-r(2)
                for j = 1:to
                    if hasFrame(obj)
                        huo = readFrame(obj);
                        sect{j} = processCurrentFrameMorpho(huo,pupilInit);%huo(:,:,1);
                    else
                        break
                    end
                end
            end  
        % labindex 3    
            if labindex == 3
                obj.CurrentTime = r(3)/obj.FrameRate-(1/obj.FrameRate);
                display(['Starting frame:  ',int2str(obj.CurrentTime)])
                to = r(3+1)-r(3)      
                for j = 1:to
                    if hasFrame(obj)
                        huo = readFrame(obj);
                        sect{j} = processCurrentFrameMorpho(huo,pupilInit);%huo(:,:,1);
                    else
                        break
                    end
                end
            end
        % labindex 4  
            if labindex == 4
                obj.CurrentTime = r(4)/obj.FrameRate-(1/obj.FrameRate);
                display(['Starting frame:  ',int2str(obj.CurrentTime)])
                to = r(4+1)-r(4)     
                for j = 1:to
                    if hasFrame(obj)
                        huo = readFrame(obj);
                        sect{j} = processCurrentFrameMorpho(huo,pupilInit);%huo(:,:,1);
                    else
                        break
                    end
                end
            end
        % labindex 5
            if labindex == 5
                obj.CurrentTime = r(5)/obj.FrameRate-(1/obj.FrameRate);
                display(['Starting frame:  ',int2str(obj.CurrentTime)])
                to = r(5+1)-r(5)     
                for j = 1:to
                    if hasFrame(obj)
                        huo = readFrame(obj);
                        sect{j} = processCurrentFrameMorpho(huo,pupilInit);%huo(:,:,1);
                    else
                        break
                    end
                end
            end 

        % labindex 6
            if labindex == 6
                obj.CurrentTime = r(6)/obj.FrameRate-(1/obj.FrameRate);
                display(['Starting frame:  ',int2str(obj.CurrentTime)])
                to = r(6+1)-r(6)    
                for j = 1:to
                    if hasFrame(obj)
                        huo = readFrame(obj);
                        sect{j} = processCurrentFrameMorpho(huo,pupilInit);%huo(:,:,1);
                    else
                        break
                    end
                end
            end  
        % labindex 7
            if labindex == 7
                obj.CurrentTime = r(7)/obj.FrameRate-(1/obj.FrameRate);
                display(['Starting frame:  ',int2str(obj.CurrentTime)])
                to = r(7+1)-r(7)     
                for j = 1:to
                    if hasFrame(obj)
                        huo = readFrame(obj);
                        sect{j} = processCurrentFrameMorpho(huo,pupilInit);%huo(:,:,1);
                    else
                        break
                    end
                end
            end      
        % labindex 8
            if labindex == 8
                obj.CurrentTime = r(8)/obj.FrameRate-(1/obj.FrameRate);
                display(['Starting frame:  ',int2str(obj.CurrentTime)])
                to = r(8+1)-r(8)    
                for j = 1:to
                    if hasFrame(obj)
                        huo = readFrame(obj);
                        sect{j} = processCurrentFrameMorpho(huo,pupilInit);%huo(:,:,1);
                    else
                        break
                    end
                end
            end  
        % labindex 9
            if labindex == 9
                obj.CurrentTime = r(9)/obj.FrameRate-(1/obj.FrameRate);
                display(['Starting frame:  ',int2str(obj.CurrentTime)])
                to = r(9+1)-r(9)   
                for j = 1:to
                    if hasFrame(obj)
                        huo = readFrame(obj);
                        sect{j} = processCurrentFrameMorpho(huo,pupilInit);%huo(:,:,1);
                    else
                        break
                    end
                end
            end  
        % labindex 10
            if labindex == 10
                obj.CurrentTime = r(10)/obj.FrameRate-(1/obj.FrameRate);
                display(['Starting frame:  ',int2str(obj.CurrentTime)])
                to = r(10+1)-r(10)    
                for j = 1:to
                    if hasFrame(obj)
                        huo = readFrame(obj);
                        sect{j} = processCurrentFrameMorpho(huo,pupilInit);%huo(:,:,1);
                    else
                        break
                    end
                end
            end  
        % labindex 11
            if labindex == 11
                obj.CurrentTime = r(11)/obj.FrameRate-(1/obj.FrameRate);
                display(['Starting frame:  ',int2str(obj.CurrentTime)])
                to = r(11+1)-r(11)   
                for j = 1:to
                    if hasFrame(obj)
                        huo = readFrame(obj);
                        sect{j} = processCurrentFrameMorpho(huo,pupilInit);%huo(:,:,1);
                    else
                        break
                    end
                end
            end  
        % labindex 12
            if labindex == 12
                obj.CurrentTime = r(12)/obj.FrameRate-(1/obj.FrameRate);
                display(['Starting frame:  ',int2str(obj.CurrentTime)])
                to = r(12+1)-r(12)   
                for j = 1:to
                    if hasFrame(obj)
                        huo = readFrame(obj);
                        sect{j} = processCurrentFrameMorpho(huo,pupilInit);%huo(:,:,1);
                    else
                        break
                    end
                end
            end      
        end
    toc
    % extract the data from the composite objects
    res = [sect{1}];
    for i = 2:12
        res = [res,sect{i}];
    end
    res = [res{:}];
    res = reshape(res,4,length(res)/4);
    res = res';
%    resSm = zeros(size(res));
%     for i = 1:3
%         resSm(:,i) = smooth(res(:,i),4,'rlowess');
%     end
    resSm = res;    
    % lets find outliers and replace them with NAN
    [rej, idx] = knee_pt(prctile(res(:,1),[1:0.2:100]),1:0.2:100)
    idx = find(res(:,1)>prctile(res(:,1),rej) | res(:,1)<prctile(res(:,1),0.5));
    resSm(idx,:) = nan;
    t = 1:numel(resSm(:,1));
    for i = 1:3
        %resSm(:,i) = inpaint_nans(resSm(:,i)); % or
        nanx = isnan(resSm(:,i));        
        resSm(nanx,i) = interp1(t(~nanx), resSm(~nanx,i), t(nanx));
    end
    
    % SAVE
    save([pth,'/processed/','pupilRes.mat'],'res','resSm');
    out.res = res;
    out.resSm = resSm;
    disp(['done processing file:  ', pth,'/processed/','pupilRes.mat', ' has been saved']);
elseif track & exist([pth,'/processed/','pupilRes.mat'])
    out = load([pth,'/processed/','pupilRes.mat']);
else
    out = [nan];
end


















%{ 
THIS WAS WORKING FINE FOR MY SETUP BUT NO FOR FILES THAT HAVE THE REAL
FRAMRE RATE ENCODED RATHER THAN JUST A FRAME RATE OF 1Hz WHICH IS WHAT I
HAVE
    %% run through all the frames on all 12 cores (gamma1)
    tic
        poolobj = gcp;
        addAttachedFiles(poolobj,{'processCurrentFrameMorpho.m'})
        spmd
            obj = VideoReader(fileName);
            a = round(obj.Duration/12);
            r = 1:a:obj.Duration;
            if r(end) < obj.Duration; r = [r, obj.Duration]; end           
        % labindex 1    
            if labindex == 1
                obj.CurrentTime = r(1);
                display(['Starting frame:  ',int2str(obj.CurrentTime)])
                to = r(2)
                for j = 1:to
                    if hasFrame(obj)
                        huo = readFrame(obj);
                        sect{j} = processCurrentFrameMorpho(huo,pupilInit);%huo(:,:,1);
                    else
                        break
                    end
                end
            end
        % labindex 2    
            if labindex == 2
                obj.CurrentTime = r(2);
                display(['Starting frame:  ',int2str(obj.CurrentTime)])
                to = r(2+1)-r(2)
                for j = 1:to
                    if hasFrame(obj)
                        huo = readFrame(obj);
                        sect{j} = processCurrentFrameMorpho(huo,pupilInit);%huo(:,:,1);
                    else
                        break
                    end
                end
            end  
        % labindex 3    
            if labindex == 3
                obj.CurrentTime = r(3);
                display(['Starting frame:  ',int2str(obj.CurrentTime)])
                to = r(3+1)-r(3)      
                for j = 1:to
                    if hasFrame(obj)
                        huo = readFrame(obj);
                        sect{j} = processCurrentFrameMorpho(huo,pupilInit);%huo(:,:,1);
                    else
                        break
                    end
                end
            end
        % labindex 4  
            if labindex == 4
                obj.CurrentTime = r(4);
                display(['Starting frame:  ',int2str(obj.CurrentTime)])
                to = r(4+1)-r(4)      
                for j = 1:to
                    if hasFrame(obj)
                        huo = readFrame(obj);
                        sect{j} = processCurrentFrameMorpho(huo,pupilInit);%huo(:,:,1);
                    else
                        break
                    end
                end
            end
        % labindex 5
            if labindex == 5
                obj.CurrentTime = r(5);
                display(['Starting frame:  ',int2str(obj.CurrentTime)])
                to = r(5+1)-r(5)     
                for j = 1:to
                    if hasFrame(obj)
                        huo = readFrame(obj);
                        sect{j} = processCurrentFrameMorpho(huo,pupilInit);%huo(:,:,1);
                    else
                        break
                    end
                end
            end 

        % labindex 6
            if labindex == 6
                obj.CurrentTime = r(6);
                display(['Starting frame:  ',int2str(obj.CurrentTime)])
                to = r(6+1)-r(6)     
                for j = 1:to
                    if hasFrame(obj)
                        huo = readFrame(obj);
                        sect{j} = processCurrentFrameMorpho(huo,pupilInit);%huo(:,:,1);
                    else
                        break
                    end
                end
            end  
        % labindex 7
            if labindex == 7
                obj.CurrentTime = r(7);
                display(['Starting frame:  ',int2str(obj.CurrentTime)])
                to = r(7+1)-r(7)     
                for j = 1:to
                    if hasFrame(obj)
                        huo = readFrame(obj);
                        sect{j} = processCurrentFrameMorpho(huo,pupilInit);%huo(:,:,1);
                    else
                        break
                    end
                end
            end      
        % labindex 8
            if labindex == 8
                obj.CurrentTime = r(8);
                display(['Starting frame:  ',int2str(obj.CurrentTime)])
                to = r(8+1)-r(8)    
                for j = 1:to
                    if hasFrame(obj)
                        huo = readFrame(obj);
                        sect{j} = processCurrentFrameMorpho(huo,pupilInit);%huo(:,:,1);
                    else
                        break
                    end
                end
            end  
        % labindex 9
            if labindex == 9
                obj.CurrentTime = r(9);
                display(['Starting frame:  ',int2str(obj.CurrentTime)])
                to = r(9+1)-r(9)    
                for j = 1:to
                    if hasFrame(obj)
                        huo = readFrame(obj);
                        sect{j} = processCurrentFrameMorpho(huo,pupilInit);%huo(:,:,1);
                    else
                        break
                    end
                end
            end  
        % labindex 10
            if labindex == 10
                obj.CurrentTime = r(10);
                display(['Starting frame:  ',int2str(obj.CurrentTime)])
                to = r(10+1)-r(10)    
                for j = 1:to
                    if hasFrame(obj)
                        huo = readFrame(obj);
                        sect{j} = processCurrentFrameMorpho(huo,pupilInit);%huo(:,:,1);
                    else
                        break
                    end
                end
            end  
        % labindex 11
            if labindex == 11
                obj.CurrentTime = r(11);
                display(['Starting frame:  ',int2str(obj.CurrentTime)])
                to = r(11+1)-r(11)   
                for j = 1:to
                    if hasFrame(obj)
                        huo = readFrame(obj);
                        sect{j} = processCurrentFrameMorpho(huo,pupilInit);%huo(:,:,1);
                    else
                        break
                    end
                end
            end  
        % labindex 12
            if labindex == 12
                obj.CurrentTime = r(12);
                display(['Starting frame:  ',int2str(obj.CurrentTime)])
                to = r(12+1)-r(12)    
                for j = 1:to
                    if hasFrame(obj)
                        huo = readFrame(obj);
                        sect{j} = processCurrentFrameMorpho(huo,pupilInit);%huo(:,:,1);
                    else
                        break
                    end
                end
            end      
        end
    toc
    % extract the data from the composite objects
    res = [sect{1}];
    for i = 2:12
        res = [res,sect{i}];
    end
    res = [res{:}];
    res = reshape(res,4,length(res)/4);
    res = res';
%    resSm = zeros(size(res));
%     for i = 1:3
%         resSm(:,i) = smooth(res(:,i),4,'rlowess');
%     end
    resSm = res;    
    % lets find outliers and replace them with NAN
    [rej, idx] = knee_pt(prctile(res(:,1),[1:0.2:100]),1:0.2:100)
    idx = find(res(:,1)>prctile(res(:,1),rej) | res(:,1)<prctile(res(:,1),0.5));
    resSm(idx,:) = nan;
    t = 1:numel(resSm(:,1));
    for i = 1:3
        %resSm(:,i) = inpaint_nans(resSm(:,i)); % or
        nanx = isnan(resSm(:,i));        
        resSm(nanx,i) = interp1(t(~nanx), resSm(~nanx,i), t(nanx));
    end
    
    % SAVE
    save([pth,'/processed/','pupilRes.mat'],'res','resSm');
    out.res = res;
    out.resSm = resSm;
    disp(['done processing file:  ', pth,'/processed/','pupilRes.mat', ' has been saved']);
%}
