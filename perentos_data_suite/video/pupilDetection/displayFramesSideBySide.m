function displayFramesSideBySide(fileBase,ts_two,varargin)
% displayFramesSideBySide(fileBase,ts,varargin) displays side-by-side
% two chunks of video frames for visual comparison.
% Works for face video frames with pupil tracking superimposed
% The speed of playback is such that the two video chunks last the same
% amount of time irrespective of actual duration
% ts is a vector of time points in the video e.g. for now we treat ts as 
% frame numbers not in real time. Unless detection is unset from 1, pupil
% detection results wil be overlayed.
% Inputs: options = {'detection',1,'xUnit','frame','video',0,'outliers',0};


options = {'detection',1,'xUnit','frame','video',1,'videoNames',{'vid1','vid2'},'outliers',0};
options = inputparser(varargin,options);

%% LOAD THE VIDEOS
% get sampling rate
[session,~] = loadSession(fileBase);
SR = session.info.SR_LFP

fullPath = getFullPath(fileBase);
test = (dir(fullfile(fullPath,'side*.avi')));
if isempty(test)
    test = (dir(fullfile(fullPath,'video','side*.avi')));
end
if options.detection
    load(fullfile(fullPath,'processed/pupilRes.mat'));
    load(fullfile(fullPath,'processed','pupilInit.mat'));
    load(fullfile(fullPath,'processed','pupilDLC.mat'));
end
if ~size(test,1)
    error('there is no pupil video file .. aborting');
elseif size(test,1) == 1
    disp 'found a side* video file; continuing with data processing...'
    fileName = fullfile(test.folder,test.name);
    [pth,fle,ext] = fileparts(fileName);
    obj1 = VideoReader(fileName);
end
    
    
% test = (dir(fullfile(fullPath,'video','top*.avi')));
% if isempty(test)
%     test = (dir(fullfile(fullPath,'video','side*.avi')));
% end
% if ~size(test,1)
%     error('there is no pupil video file .. aborting');
% elseif size(test,1) == 1
%     disp 'found a top* video file; continuing with data processing...'
%     fileName = fullfile(test.folder,test.name);
%     [pth,fle,ext] = fileparts(fileName); 
%     obj2 = VideoReader(fileName);
% end

% if ~exist('ts','var')
%     nFr = obj1.Duration;
%     ts = randi([1 nFr],500,1);        
% end   
% ts = sort(ts);

% find frames that were smoothed/corrected and display those only
% if options.outliers == 1
%     ts = find(resSm(:,6) == 1);  
%     if length(ts) > 500
%         ts = ts(1:100:end);
%     end
%     display(['number of corrected frames: ',num2str(length(ts)),'/',num2str(nFr)])
% end

% add the DLCpupil results so that we can compare
% fl = 0;
if exist(fullfile(fullPath,'processed/pupilDLC.mat'))
    test = (dir(fullfile(fullPath,'video','*pupil*.avi')));
    fileName = fullfile(test.folder,test.name);
    [pth,fle,ext] = fileparts(fileName); 
    obj3 = VideoReader(fileName);    
    load(fullfile(fullPath,'processed/pupilDLC.mat'));
    fl = 1;
end     
    
%  ts = [test{:}];
% if strcmp(options.xUnit,'frame') % ts is in seconds
%     ts = ts;
% elseif strcmp(options.xUnit,'time') % ts is in seconds
%     ts = round(ts*obj.FrameRate);
%     warning('untested for frame rates unequal to 1');
% end

%precompute the desired frame rates
% we will keep shorter video at 15fps and squeeze longer one's fps
% to what ever it takes so both finish at the same time
[a,b] = min([length(ts_two{1}),length(ts_two{2})]);
[c,d] = max([length(ts_two{1}),length(ts_two{2})]);
frRt(b) = 15;
frRt(d) = 15*(c/a);

%% CYCLE THROUGH REQUESTED FRAMES
for xv = 1:2 % two videos to stitch
    ts = ts_two{xv};
    figure('color','k','position',[50 50 295   332],'visible','off');
    %global KEY_IS_PRESSED; KEY_IS_PRESSED = 0;
    %gcf; set (gcf, 'KeyPressFcn', @myKeyPressFcn)
    i = 0;
    if options.video
        v = VideoWriter(options.videoNames{xv});
        v.FrameRate=frRt(xv);
        open(v);
    end
    if isfield(session.info,'useDLCPupil') & session.info.useDLCPupil
        disp('using DLC instead of morpho....');
        while  i < length(ts) %& ~KEY_IS_PRESSED
            i = i+1;
            clf;
            axes('pos',[0 0 1 1])
            obj3.CurrentTime = ts(i)-1;
            fr2 = obj3.readFrame;
            imshow(fr2); hold on;
            circle([pupDLC.resIntrp(ts(i),2),pupDLC.resIntrp(ts(i),3)],sqrt(pupDLC.resIntrp(ts(i),1)/pi),30,'y');% circle fit
            % viscircles([pupDLC.aux.circl(ts(i),2)+ofs pupDLC.aux.circl(ts(i),3)+ofs],pupDLC.aux.circl(ts(i),1));
            hold on;
            xl = xlabel([session.info.conditions{xv}, '     ', num2str((ts(i)-ts(1))/30,'%4.2f'),'  s '],'color','g','fontweight','bold','fontsize',20,'HorizontalAlignment','left');
            set(xl,'pos',[10,4,1]);

            drawnow;       %hold off;
            if options.video    
                frame = getframe(gcf);
                writeVideo(v,frame);  
            end
        end
    else    
        while  i < length(ts) %& ~KEY_IS_PRESSED
            i = i+1;
            clf;
            axes('pos',[0 0 1 1])
            obj1.CurrentTime = ts(i)-1;
            fr = obj1.readFrame;
            if options.detection
                imshow(fr(pupilInit.rct(2):pupilInit.rct(2)+pupilInit.rct(4),pupilInit.rct(1):pupilInit.rct(1)+pupilInit.rct(3),:)); hold on;
                viscircles([res(ts(i),2)+5 res(ts(i),3)+5],res(ts(i),1));
                viscircles([resSm(ts(i),2)+5 resSm(ts(i),3)+5],resSm(ts(i),1),'color','b');
                hold on;
                xl = xlabel([session.info.conditions{xv}, '     ', num2str((ts(i)-ts(1))/30,'%4.2f'),'  s '],'color','g','fontweight','bold','fontsize',20,'HorizontalAlignment','left');
                set(xl,'pos',[10,4,1]);
            end

            drawnow;       %hold off;
            if options.video    
                frame = getframe(gcf);
                writeVideo(v,frame);  
            end
        end
    end
    close(v);
end

display('DONE');
close all;


% function myKeyPressFcn (hObject, event)
% global KEY_IS_PRESSED 
% KEY_IS_PRESSED = 1;
% disp ('key is pressed') 


%% BELOW CAME FROM VISBADFRAMES.M WHICH I DELETED
%%loop over bad frames just to visualise
%%figure('units','normalized','outerposition',[0 0 1 1])
% figure('Position',[-978   378   972   903]);
% pause(1);
% for i = flagND(2:end)
%     next = false;
%     %imshow(all.frames(i).cdata(:,:,1));
%     imagesc(all.frames(i).cdata(:,:,1));
%     colormap gray;
%     hold on;
%     bx  = tracked(i).BoundingBox;
%     ofs = pupilData.rct(1:2);
%     
%     bx  = [bx(1)+ofs(1) bx(2)+ofs(2) bx(3) bx(4)];    
%     rectangle('Position',bx,'EdgeColor',[1 0 0]);
%     title(int2str(i));
%     gcf;%set(gcf,'Position',[-978   37es8   972   903])
%     while ~next
%         prompt = 'press enter for next: ';
%         str = input(prompt,'s');        
%         gcf;
%         if strcmp('','')
%             next = true;
%         end
%     end
%     clf;
% end