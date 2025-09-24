function displayFrames(fileBase,ts,varargin)
% displayFrames(fileBase,ts,varargin) displays specified frames from video. 
% ts is a vector of time points in the video e.g. for now we treat ts as 
% frame numbers not in real time. Unless detection is unset from 1, pupil
% detection results wil be overlayed.
% Inputs: options = {'detection',1,'xUnit','frame','video',0,'outliers',0};


options = {'detection',1,'xUnit','frame','video',0,'videoName','vidSample','outliers',0};
options = inputparser(varargin,options);

%% LOAD THE VIDEOS
    
fullPath = getFullPath(fileBase);
test = (dir(fullfile(fullPath,'side*.avi')));
if isempty(test)
    test = (dir(fullfile(fullPath,'video','side*.avi')));
end
if options.detection
    load(fullfile(fullPath,'processed/pupilRes.mat'));
    load(fullfile(fullPath,'processed','pupilInit.mat'));
end
if ~size(test,1)fileBase
    error('there is no pupil video file .. aborting');
elseif size(test,1) == 1
    disp 'found a side* video file; continuing with data processing...'
    fileName = fullfile(test.folder,test.name);
    [pth,fle,ext] = fileparts(fileName);
    obj1 = VideoReader(fileName);
end
    
    
test = (dir(fullfile(fullPath,'video','top*.avi')));
if isempty(test)
    test = (dir(fullfile(fullPath,'video','side*.avi')));
end
if ~size(test,1)
    error('there is no pupil video file .. aborting');
elseif size(test,1) == 1
    disp 'found a top* video file; continuing with data processing...'
    fileName = fullfile(test.folder,test.name);
    [pth,fle,ext] = fileparts(fileName); 
    obj2 = VideoReader(fileName);
end

if ~exist('ts','var')
    nFr = obj1.Duration;
    ts = randi([1 nFr],500,1);        
end   
ts = sort(ts);

% find frames that were smoothed/corrected and display those only
if options.outliers == 1
    ts = find(resSm(:,6) == 1);  
    if length(ts) > 500
        ts = ts(1:100:end);
    end
    display(['number of corrected frames: ',num2str(length(ts)),'/',num2str(nFr)])
end

% add the DLCpupil results so that we can compare
fl = 0;
if exist(fullfile(fullPath,'processed/pupilDLC.mat'))
    test = (dir(fullfile(fullPath,'video','*pupil*.avi')));
    fileName = fullfile(test.folder,test.name);
    [pth,fle,ext] = fileparts(fileName); 
    obj3 = VideoReader(fileName);    
    load(fullfile(fullPath,'processed/pupilDLC.mat'));
    fl = 1;
end     
    
    
if strcmp(options.xUnit,'frame') % ts is in seconds
    ts = ts;
elseif strcmp(options.xUnit,'time') % ts is in seconds
    ts = round(ts*obj.FrameRate);
    warning('untested for frame rates unequal to 1');
end

%% CYCLE THROUGH REQUESTED FRAMES
figure('color','k','position',[303       10         2100        1300]);%307        -275        1638         899]);
global KEY_IS_PRESSED; KEY_IS_PRESSED = 0;
gcf; set (gcf, 'KeyPressFcn', @myKeyPressFcn)
%obj1.CurrentTime = ts(1);
%obj2.CurrentTime = ts(1);
i = 0;
if options.video
    v = VideoWriter(options.videoName);
    v.FrameRate=15;
    open(v);
end

while  i < length(ts) & ~KEY_IS_PRESSED
    i = i+1;
    clf;
    obj1.CurrentTime = ts(i)-1;
    fr = obj1.readFrame;
    subplot(241); imshow(fr);title([int2str(ts(i)),' -- ',int2str(i)],'color','r');
    subplot(242);   
    if options.detection
        imshow(fr(pupilInit.rct(2):pupilInit.rct(2)+pupilInit.rct(4),pupilInit.rct(1):pupilInit.rct(1)+pupilInit.rct(3),:)); hold on;
        viscircles([res(ts(i),2)+5 res(ts(i),3)+5],res(ts(i),1));
        viscircles([resSm(ts(i),2)+5 resSm(ts(i),3)+5],resSm(ts(i),1),'color','b');
        if fl
            subplot(245); 
            obj3.CurrentTime = ts(i)-1;
            fr2 = obj3.readFrame;
            imshow(fr2); hold on;
            ofs = 0;
            plot(pupDLC.dlxX(ts(i),:)-ofs,pupDLC.dlxY(ts(i),:)+ofs,'xr');  % the dlc data points
            circle([pupDLC.res(ts(i),2)-ofs,pupDLC.res(ts(i),3)+ofs],sqrt(pupDLC.res(ts(i),1)/pi),30,'y');% circle fit
            circle([pupDLC.resIntrp(ts(i),2)-ofs,pupDLC.resIntrp(ts(i),3)+ofs],sqrt(pupDLC.resIntrp(ts(i),1)/pi),30,'g'); % intterpolated circle fit        
            title(['lik: ',num2str(sum(pupDLC.lik(ts(i),:))/8,2),' ,    resid: ', num2str(pupDLC.fitResiduals(ts(i),1),2), ' & ',num2str(pupDLC.fitResiduals(ts(i),2),2)],'color','w');        
        end
    end
    % top cam
    obj2.CurrentTime = ts(i)-1;
     subplot(243); imshow(obj2.readFrame);
     if options.detection
        subplot(244);imagesc(res(ts(i),5));caxis([0 3]);
     end
    drawnow;       %hold off;
    if options.video    
        frame = getframe(gcf);
        writeVideo(v,frame);  
    end
end

% close;

% clf; title('DONE','color','r');



function myKeyPressFcn (hObject, event)
global KEY_IS_PRESSED 
KEY_IS_PRESSED = 1;
disp ('key is pressed') 


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