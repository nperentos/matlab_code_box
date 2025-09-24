fle = 'NP21_2018-11-05_17-05-26';fpth = getFullPath(fle);cd(fpth);
cd('NoseTracking-Nperentos-2018-12-22/videos/');
data = csvread('top_cam_0_date_2018_11_05_time_17_05_19_v001DeepCut_resnet50_NoseTrackingDec22shuffle1_300000.csv',4);
data(:,[1 4 7 10])=[];

nclu = 6;
[idx,C] = kmeans(data,nclu);
% plot the centroids
for i = 1:nclu
    %OLDplot(C(i,[1 5 3]),C(i,[2 6 4]),'color',colororder(i,:),'linewidth',2);
    plot(C(i,[1 2 3]),C(i,[4 5 6]),'color',colororder(i,:),'linewidth',2);
    hold on;
end
legend('1','2','3','4','5','6');

%% plot the time traces and color by cluster - NOT VERY USEFULL
x = 1:1:length(data); y = data(:,1)';
z = zeros(1,length(data));
col = idx';
figure;
surface([x;x],[y;y],[z;z],[col;col],'facecol','no','edgecol','interp','linew',2);
close all;            
%% plot actual nose, the nose position and color by cluster
pth = getFullPath(fle);
cd(pth);
vf = dir('top*');
vidH = VideoReader(fullfile(pth,vf.name));
figure; plot([0],[0]); xlim([0 200]);ylim([0 190]); hold on; colormap gray;
ns = 10; h = []; fri = [];
v = VideoWriter('nosemovieNP3.mp4');%,'Uncompressed AVI'
v.FrameRate = 30;  % Default 30
v.Quality = 30;    % Default 75
open(v);
for i = 39000:500+39000%length(data)-ns
    delete(h);delete(fri);
    vidH.CurrentTime = i+ns;
    fr = readFrame(vidH); 
    fri = imagesc(double(fr(100:300,260:450,1)));
    for j = 1:ns
        h(j) = plot(2+[data(i+j,1),data(i+j,5),data(i+j,3)],[data(i+j,2),data(i+j,6),data(i+j,4)],'color',[colororder(idx(i+j),:) j/ns],'linewidth',2);        
    end
    drawnow;
   frame = getframe(gcf);
   writeVideo(v,frame);
end
close(v);


% from another file
figure;
for i = 1:length(data)
    plot(data(i,[2 5 8]),data(i,[3 6 9]))
    xlim([0 640]);ylim([0 720]);drawnow;
end
    

pth = getFullPath(fle);
cd(pth);
vf = dir('top*');
vidH = VideoReader(fullfile(pth,vf.name));
figure; plot([0],[0]); xlim([0 200]);ylim([0 190]); hold on; colormap gray;
ns = 10; h = []; fri = [];
v = VideoWriter('nosemovieNP3.mp4');%,'Uncompressed AVI'
v.FrameRate = 30;  % Default 30
v.Quality = 30;    % Default 75
open(v);
for i = 1:500%+39000%length(data)-ns
    i
    delete(h);delete(fri);
    vidH.CurrentTime = i;
    fr = readFrame(vidH); 
    fri = imagesc(double(fr(100:300,260:450,1)));
    for j = 1:ns
        h(j) = plot(2+[data(i+j,1),data(i+j,5),data(i+j,3)],[data(i+j,2),data(i+j,6),data(i+j,4)],'color',[colororder(idx(i+j),:) j/ns],'linewidth',2);        
    end
    drawnow;
   frame = getframe(gcf);
   writeVideo(v,frame);
end
close(v);