function out = plotNoseTracking(fileBase,varargin)
    %fileBase = 'NP48_2019-12-14_18-02-56';
        options = {'flag','outliers','session_pth',[],'vidName','face','abs_vid_path',[],'jump',200,'frames',[],'video',0};
        options = inputparser(varargin,options);
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
    % CSV
    a = dir('top*.csv'); 
    if length(a) > 1 || length(a) == 0
        error('either more than one no csv file found at all');
    end
    csvName = a.name;
    if exist(fullfile(getfullpath(fileBase),'noseTracking.mat'))
        load(fullfile(getfullpath(fileBase),'noseTracking.mat'));
    else
        T = importDLC(csvName);
    end

    %% SIMPLE GUI CONTROL
    figure('color','k','pos',[199   141   575*2   980]);
    global KEY_IS_PRESSED; KEY_IS_PRESSED = 0;
    gcf; set (gcf, 'KeyPressFcn', @myKeyPressFcn)
    % H = uicontrol('Style', 'PushButton', ...
    %                     'String', 'Break', ...
    %                     'Callback', 'delete(gcbf)');              
    xlim([0 300]); colormap('gray');


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
    else
        error('no valid frames to visualise were defined');
    end
    % calculate the center of mass
    cx = median(vc(nose.dataInterp(:,1:3))); cy = median(vc(nose.dataInterp(:,4:6)));


    %% PLOT
    if options.video
        v = VideoWriter(fullfile(getfullpath(fileBase),['noseTracking(',options.flag,'Frames).avi']));
        v.FrameRate=10;
        open(v);
    end
    i=1; 
    
    while i < length(otl) & ~KEY_IS_PRESSED          
        vidH.CurrentTime = otl(i); 
        fr = readFrame(vidH);
        vidH2.CurrentTime = otl(i); 
        fr2 = readFrame(vidH2);
    % top cam
        subplot(3,2,[1 3]); cla;
        imshow((fr(:,:,1)));
        hold on;
        plot(nose.dataRaw(otl(i),1:3),nose.dataRaw(otl(i),4:6),'o','markerfacecolor',[1-min(nose.dataRaw(otl(i),7:9),[],2), min(nose.dataRaw(otl(i),7:9),[],2), 0.5]);
        plot(nose.dataMr(otl(i),1:3),nose.dataInterp(otl(i),4:6),'om','markersize',5,'linewidth',2);
        plot(cx,cy,'+c');
    %         plot(cxi(otl(i)),cyi(otl(i)),'mx');
        xlim([0 300]); 
        title(['frame: ', num2str(otl(i))],'color','w');
        %title(['frame: ', num2str(otl(i)),', p=',num2str(tmp(otl(i)))]);
    % side cam
        subplot(3,2,[2 4]); cla;
        imshow((fr2(:,:,1)));
    % 1st PC trace
        if strcmp(options.flag,'frams') | strcmp(options.flag,'frames')
            subplot(3,2,[5 6]);cla;set(gca,'color','k');ylabel('1^s^t PC');
            plot(-nose.PCs.score(otl(1:i),1),'w','linewidth',2);
            xlim([0 length(otl)]);
            ylim([-max(nose.PCs.score(otl,1)) abs(min(nose.PCs.score(otl,1)))]);
            hold on; plot(i,-nose.PCs.score(otl(i),1),'ow','markersize',14);
        end
        drawnow;       %hold off;
        if options.video    
            frame = getframe(gcf);
            writeVideo(v,frame);  
        end        
        i=i+1;
    end
    if exist('v')
        close(v);
    end
    close all;

function myKeyPressFcn (hObject, event)
    global KEY_IS_PRESSED
    KEY_IS_PRESSED = 1;
    disp ('aborting...') 
%


%% MAIN PLOT FOR OUTLIER OR SPECIFIC FRAMES  CASE
% if strcmp(options.flag,'outliers') | strcmp(options.flag,'frams') | strcmp(options.flag,'frames')
%     % low probability frames     
%     tmp = min(nose.dataInterp(:,7:9),[],1);
%     otl = find(T.P(1,:)<0.99);
%     % define additional outliers based on the center of mass
%     cx = median(vc(T.X)); cy = median(vc(T.Y)); % COM
%     cxi = mean(T.X,1); cyi = mean(T.Y,1); % COM per timepoint
%     toofar = find(abs(cxi-cx)>30 |abs(cyi-cy)>60);
%     
%     %otl2 = find(T.P(1,:)>0.99);
%     %otl = intersect(otl,otl2);
%     otl = union(otl,toofar);
%     if strcmp(options.flag,'frams') | strcmp(options.flag,'frames')
%         otl = options.frames;
%     end
%     
% 
%     length(otl)
%     waitforbuttonpress
%     for i = 1:length(otl)
%         if ishandle(H)            
%             vidH.CurrentTime = otl(i); 
%             fr = readFrame(vidH);
%             vidH2.CurrentTime = otl(i); 
%             fr2 = readFrame(vidH2);
%         % top cam
%             subplot(121); cla;
%             imshow((fr(:,:,1)));
%             hold on;
%             plot(T.X(:,otl(i)),T.Y(:,otl(i)),'o','markerfacecolor',[1-min(tmp(:,otl(i))), min(T.P(:,otl(i))), 0.5]);
%             plot(cx,cy,'rd');
%             plot(cxi(otl(i)),cyi(otl(i)),'mx');
%             xlim([0 300]); 
%             title(['frame: ', num2str(otl(i)),', p=',num2str(tmp(otl(i)))]);
%         % side cam
%             subplot(122); cla;
%             imshow((fr2(:,:,1)));
%             drawnow;
%             %waitforbuttonpress
%         end
%     end
% end

% close; 
% out = 1;
