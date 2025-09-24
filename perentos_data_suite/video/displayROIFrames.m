function displayROIFrames(fileBase,ts,pts,varargin)
% displayROIFrames(fileBase,ts,varargin) displays frames specified in ts
% for a particular ROI. The ROI should be defined as 4 points corresponding
% [upperleftpixelX upperleftpixelY length of X and length of Y]. These can
% for predefined ROIs you can find these ROIs in all_video_results.mat but
% also in whiskerROIs, pupilInit or faceROIs.

options = {'xUnit','frame','video',0};
options = inputparser(varargin,options);

%% LOAD THE VIDEOS
ts = sort(ts);
    
fullPath = getFullPath(fileBase);
test = (dir(fullfile(fullPath,'side*.avi')));
if isempty(test)
    test = (dir(fullfile(fullPath,'video','side*.avi')));
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
if strcmp(options.xUnit,'frame') % ts is in seconds
    ts = ts;
elseif strcmp(options.xUnit,'time') % ts is in seconds
    ts = round(ts*obj.FrameRate);
    warning('untested for frame rates unequal to 1');
end

%% CYCLE THROUGH REQUESTED FRAMES
figure('color','k','position',[703 100 800 800]);colormap gray;%307        -275        1638         899]);
global KEY_IS_PRESSED; KEY_IS_PRESSED = 0;
gcf; set (gcf, 'KeyPressFcn', @myKeyPressFcn)
%obj1.CurrentTime = ts(1);
%obj2.CurrentTime = ts(1);
i = 0;
if options.video
    v = VideoWriter('hello.avi');
    v.FrameRate=15;
    open(v);
end

while  i < length(ts) %& ~KEY_IS_PRESSED
    i = i+1;
    clf;
    obj1.CurrentTime = ts(i);
    fr = obj1.readFrame;
    fr = fr(:,:,1);
    sfr = imcrop(fr,pts);
    
    imagesc(sfr);title([int2str(ts(i)),' -- ',int2str(i)],'color','r');
    drawnow;       %hold off;
    if options.video    
        frame = getframe(gcf);
        writeVideo(v,frame);  
    end
end

% clf; title('DONE','color','r');



function myKeyPressFcn (hObject, event)
global KEY_IS_PRESSED
KEY_IS_PRESSED = 1;
disp ('key is pressed') 
close v;


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