
%% one way which apparently works on single frames

vidReader = VideoReader('frate=3-0_top_cam_0_date_2019_04_10_time_12_58_29_v001.avi');
opticFlow = opticalFlowLK('NoiseThreshold',0.0039);
figure('pos',[471 1276 1155 613]);
while hasFrame(vidReader)   
   frameRGB = readFrame(vidReader);    
   frameGray = rgb2gray(frameRGB(300:450,1:150,:));
   flow = estimateFlow(opticFlow,frameGray); 
   subplot(121)
   imagesc(flow.Orientation);
   subplot(122);
   bar(mean(flow.Orientation(:))); ylim([- 1 1]);
   drawnow;
end






%%




%% a method that works on consecutive frames


vidReader = VideoReader('frate=3-0_top_cam_0_date_2019_04_10_time_12_58_29_v001.avi');

vidReader.CurrentTime = 59;
figure('pos',[471 1276 1155 613]);

% block matcher object
hbm = vision.BlockMatcher('ReferenceFrameSource',...
        'Input port','BlockSize',[35 35]);
hbm.OutputValue = 'Horizontal and vertical components in complex form';
halphablend = vision.AlphaBlender;

% current frame
current_frameRGB = readFrame(vidReader);    
current_frameGray = rgb2gray(current_frameRGB(:,1:150,:));
skipF = readFrame(vidReader);


while hasFrame(vidReader)
   %skipF = readFrame(vidReader); 
   next_frameRGB = readFrame(vidReader);    
   next_frameGray = rgb2gray(next_frameRGB(:,1:150,:));
   %skipF = readFrame(vidReader);   
   motion = hbm(current_frameGray,next_frameGray);
   
   
   subplot(2,2,1)
   imagesc(current_frameGray);
   subplot(2,2,3);
   imagesc(next_frameGray);
   drawnow;
   
    subplot(2,2,[2 4]);
   [X,Y] = meshgrid(1:35:size(next_frameGray,2),1:35:size(next_frameGray,1));         
    imshow(next_frameGray);axis equal;
    hold on
    quiver(X(:),Y(:),real(motion(:)),imag(motion(:)),0)
    hold off
   
    current_frameRGB = readFrame(vidReader);    
    current_frameGray = rgb2gray(current_frameRGB(:,1:150,:));
    
   
%    subplot(121)
%    imagesc(flow.Orientation);
%    subplot(122);
%    bar(mean(flow.Orientation(:))); ylim([- 1 1]);
%    drawnow;
end





%% 
vidReader = VideoReader('frate=3-0_top_cam_0_date_2019_04_10_time_12_58_29_v001.avi','CurrentTime',39);
opticFlow = opticalFlowFarneback;
h = figure('pos',[471 1276 1155 613]);
movegui(h);
hViewPanel = uipanel(h,'Position',[0 0 1 1],'Title','Plot of Optical Flow Vectors');
hPlot = axes(hViewPanel);
while hasFrame(vidReader)
    frameRGB = readFrame(vidReader);
    frameGray = rgb2gray(frameRGB);  
    flow = estimateFlow(opticFlow,frameGray);
    
    imshow(frameRGB)
    hold on
    plot(flow,'DecimationFactor',[5 5],'ScaleFactor',2,'Parent',hPlot);
    hold off
    pause(10^-3)
end




