% this is a different tactic to getting the pupil size and centre. Avoids
% the use of imfindcircles and the clustering as performed by 
%%
clf; drawnow
cd /storage2/perentos/data/recordings/NP19/NP19_2018-10-10_13-30-36
fldrName='NP19_2018-10-10_13-30-36';
obj = VideoReader('side_cam_1_date_2018_10_10_time_13_30_28_v001.avi');
obj.CurrentTime = 22443;
frame = readFrame(obj);
vidFrame = frame;
clear frame
I = vidFrame(:,:,1);
cd processed/
load pupilInit.mat
 r_hat = 2;
    r_r = -1:1;
    r_z = bsxfun(@plus,r_r'.^2, r_r.^2);
    r_z = r_z/sum(r_z(:));
Icr = I(pupilInit.rct(2):pupilInit.rct(2)+pupilInit.rct(4),pupilInit.rct(1):pupilInit.rct(1)+pupilInit.rct(3),:);
imshow(Icr)
framesize = size(Icr);
x = nan(framesize(1),framesize(2));
x(:,:) = conv2(double(Icr(:,:)),r_z,'same');
G_data = x;
G_data = G_data(5:(end-5),5:(end-5));
frCx = size(G_data,1)/2;
frCy = size(G_data,2)/2;
tmp_data = G_data;
tmpscale = prctile(tmp_data(:),[pupilInit.thr, 25]);
G_data = rescale(tmp_data,tmpscale);
Gb=G_data./max(max(G_data));
Gb = imbinarize(Gb);
bw = ~bwareaopen(~Gb,50);
se = strel('disk',7);
bw = imclose(~bw,se);
%imshow(bw)
[B,L] = bwboundaries(bw,'noholes');
imshow(label2rgb(L, @jet, [.5 .5 .5]))
hold on
for k = 1:length(B)
boundary = B{k};
plot(boundary(:,2), boundary(:,1), 'k', 'LineWidth', 2)
end
stats = regionprops(L,'Area','Centroid','MajorAxisLength','MinorAxisLength');
diameters = mean([[stats.MajorAxisLength]; [stats(:).MinorAxisLength]]',2);
radii = diameters/2;
for k = 1:length(B)    
    % get center coordinates
    centers(k,:) = [stats(k).Centroid(1),stats(k).Centroid(2)];    
    % obtain (X,Y) boundary coordinates corresponding to label 'k'
    boundary = B{k};
    % compute a simple estimate of the object's perimeter
    delta_sq = diff(boundary).^2;
    perimeter = sum(sqrt(sum(delta_sq,2)));
    % obtain the area calculation corresponding to label 'k'
    area = stats(k).Area;
    % compute the roundness metric
    metric(k) = 4*pi*area/perimeter^2;
    % display the results
    metric_string = sprintf('%2.2f',metric(k));
    text(stats(k).Centroid(1),stats(k).Centroid(2),metric_string,'Color','k',...
    'FontSize',14,'FontWeight','bold');
end
viscircles(centers+5,radii);
res = 0;