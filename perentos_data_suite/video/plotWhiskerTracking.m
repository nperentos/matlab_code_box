function out = plotWhiskerTrackingNew(fileBase,varargin)
    %fileBase = 'NP48_2019-12-14_18-02-56';
        options = {'flag','man','session_pth',[],'vidName','face','abs_vid_path',[],'jump',200,'frames',[],'video',0};
        options = inputparser(varargin,options);
        % the orientation of the gabor filters is not saved anywhere. Maybe
        % this should be documented in the output of trackWhiskerGabor so
        % that it can be used without doubts inside this function
        orientation = [-80:15:80];
        
        
        % flag can be outliers, frames or jump
    %% PREREQUISITES
    
    try
        cd(fullfile(getFullPath(fileBase,options.session_pth),'video'));
        a = dir('top*.avi');
        b = dir('side*.avi');
    catch
        display('there is no video here, skipping folder...');
        out = nan;
        return;
    end
    if length(a) > 1 || length(a) == 0
        error('either more than one no video file found at all')
    end
    vidName = a.name;
    vidH = VideoReader(vidName);
    vidName2 = b.name;
    vidH2 = VideoReader(vidName2);
%     % CSV
%     a = dir('top*.csv'); 
%     if length(a) > 1 || length(a) == 0
%         error('either more than one no csv file found at all');
%     end
%     csvName = a.name;
    if exist(fullfile(getfullpath(fileBase),'whisker_whiskerTracking.mat'))
        load(fullfile(getfullpath(fileBase),'whisker_whiskerTracking.mat'));
        load(fullfile(getfullpath(fileBase),'whiskerROIs.mat'));
    else
        error('cannot find whisker tracking file (). Please check ')
        %T = importDLC(csvName);
    end

    %% SIMPLE GUI CONTROL
    %figure('color','w','pos',[199   141   575*2   980]);
    figure('color','w','pos',[1732 260 760 483]);
    global KEY_IS_PRESSED; KEY_IS_PRESSED = 0;
    global keepGoing; keepGoing = 1; 
    gcf; set (gcf, 'KeyPressFcn', @myKeyPressFcn)
%     H = uicontrol('Style', 'PushButton', ...
%                         'String', 'Break', ...
%                         'Callback', 'delete(gcbf)');     
    %xlim([0 300]); colormap('gray');


    %% MAIN PLOT FOR FRAME JUMPING CASE
    % if strcmp(options.flag,'jump')
    %     while hasFrame(vidH) & ishandle(H)
    %         try
    %             vidH.CurrentTime = vidH.CurrentTime + options.jump;
    %             fr = readFrame(vidH);
    %             cla;            
    %             imshow((fr(:,:,1)));
    %             hold on;
    %     %         plot(T.X(:,vidH.CurrentTime+1),T.Y(:,vidH.CurrentTime+1),'x','color',[T.P(:,vidH.CurrentTime+1),[0.5;0.5;0.5], [0.5;0.5;0.5]]');
    %             plot(T.X(:,vidH.CurrentTime+0),T.Y(:,vidH.CurrentTime+0),'o','markerfacecolor',[1-min(T.P(:,vidH.CurrentTime+1)), min(T.P(:,vidH.CurrentTime+1)), 0.5]);
    %             xlim([0 300]); title(['frame: ', num2str(vidH.CurrentTime)]);                      
    %             drawnow;
    %         catch
    %             display('last frame');
    %             break;
    %         end
    %     end
    % end

    %% DERIVE THE FRAMES OF INTEREST
    if      strcmp(options.flag,'frams') | strcmp(options.flag,'frames') 
        otl = options.frames;
        
    elseif  strcmp(options.flag,'outliers')
        otl = nose.otl;
    elseif  strcmp(options.flag,'man')
        nFr = vidH.Duration*vidH.FrameRate;
        otl = 1:options.jump:nFr;
        disp(['will display ', num2str(length(otl)), ' frames.'])
    else
        error('no valid frames to visualise were defined');
    end
    % calculate the center of mass
    %cx = median(vc(nose.dataInterp(:,1:3))); cy = median(vc(nose.dataInterp(:,4:6)));


    %% PLOT
    if options.video
        v = VideoWriter(fullfile(getfullpath(fileBase),['whiskerTracking(',options.flag,'Frames).avi']));
        v.FrameRate=10;
        open(v);
    end
    
    
    
    i=1;
    
    originL = [ROI.pts(1,1) + ROI.pts(1,3)/2 , ROI.pts(1,2) + ROI.pts(1,4)/2 ];%+ ROI.pts(1,4)
    extentL = min([ROI.pts(1,3:4)])/2;
    cMapL = parula(100); % 100 colors used for filters magnitude
    [~,~,binL] = histcounts(whisker.mag(1,:),length(cMapL)); % bin for each magnitude
    %
    originR = [ROI.pts(2,1) + ROI.pts(2,3)/2 , ROI.pts(2,2) + ROI.pts(2,4)/2 ];%+ ROI.pts(1,4)
    extentR = min([ROI.pts(2,3:4)])/2;
    cMapR = parula(100); % 100 colors used for filters magnitude
    [~,~,binR] = histcounts(whisker.mag(2,:),length(cMapR)); % bin for each magnitude    
    
    % an axis for colormap of whisker angle lines
    ax1 = axes;
    imagesc([]); colormap(ax1,'parula'); 
    set(gca,'visible','off');
    clb = colorbar;
    ylabel(clb,'low <- confidence -> high');
    clb.Ticks = [];set(clb,'pos',[get(clb,'pos')].*[1.05 1 1 0.5]);
    axis off; set(gca,'visible','off');
    hold on;  
    ax2 = axes; colormap(ax2,'gray'); axis off;
    
    while i < length(otl) & keepGoing 
        
        vidH.CurrentTime = otl(i);
        fr = readFrame(vidH);
        
               
        
        imshow((fr(:,:,1)),'parent',ax2);
        hold(ax2,'on');
        for  j = 1:length(whisker.names)
            rectangle('Position',ROI.pts(j,:),'EdgeColor','r','LineWidth',1.5,'LineStyle','-');
        end
        
        %for kk = 1:length(orientation)
        %   kk
        angL = deg2rad(orientation(whisker.angle(1,otl(i))));
        angR = deg2rad(orientation(whisker.angle(2,otl(i))));
        %angL = deg2rad(orientation(kk));
        
        
        %ROTL = [cos(angL) -sin(angL); sin(angL) cos(angL)];% conventional correct
        ROTL = [cos(angL) sin(angL); -sin(angL) cos(angL)];% we swap signs for the sinusoids to account for the top down direction of the y axis
        ROTR = [cos(angR) sin(angR); -sin(angR) cos(angR)];%
        
        zaL = [originL(1)-originL(1); extentL]; % the zero angle vector
        pROTL = ROTL * zaL + originL';
        zaR = [originR(1)-originR(1); extentR]; % the zero angle vector
        pROTR = ROTR * zaR + originR';        
        %py = ROT * [org1(2)-ext1];
        %plot([org1(1) org1(1)],[org1(2)  org1(2)-ext1],'g','linewidth',2)
        plot([originL(1) pROTL(1)],[originL(2)  pROTL(2)],'color',cMapL(binL(otl(i)),:),'linewidth',2);
        plot([originR(1) pROTR(1)],[originR(2)  pROTR(2)],'color',cMapR(binL(otl(i)),:),'linewidth',2);        
        title(['frame: ', num2str(otl(i))],'color','k');% ,' conf: ', num2str(whisker.mag(otl(i)))
        drawnow;       %hold off;
        hold(ax2,'off');
        %end
        if options.video    
            frame = getframe(gcf);
            writeVideo(v,frame);  
        end        
        i=i+1
        waitforbuttonpress;
    end
    if exist('v')
        close(v);
    end
    close all;
end

function myKeyPressFcn (hObject, event)
    global KEY_IS_PRESSED
    global keepGoing
    KEY_IS_PRESSED = 1;
    if strcmp(event.Key, 'q')
        keepGoing = 0;
        disp('exiting on user request')
    end
    if strcmp(event.Key, ' ')
        keepGoing = 1;
    end    
end

