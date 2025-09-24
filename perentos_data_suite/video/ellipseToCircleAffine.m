% afine transformation of frame.

%1. load a frame
fle = '/storage2/perentos/data/recordings/NP48/OTHER/NP48-openfield-control-cage-29-10-2019/NP48-openfield-control-cage-29-10-2019.mp4'
obj = VideoReader(fle);
fr = double(rgb2gray(obj.readFrame));

%2. define an ellipse and make a mask out of it
figure; imshow(fr,[]);
el = imellipse;
elM = createMask(el);
figure; imshow(elM.*fr,[]);

%3. generate region props of the ellipse
[B,L] = bwboundaries(elM,'noholes');
stats = regionprops(L,'Orientation','Centroid','MajorAxisLength','MinorAxisLength');

%4 make transformation matrix
% from here: https://uk.mathworks.com/matlabcentral/answers/35083-affine-transformation-that-takes-a-given-known-ellipse-and-maps-it-to-a-circle-with-diameter-equal
alpha = pi/180 * stats(1).Orientation;
Q = [cos(alpha), -sin(alpha); sin(alpha), cos(alpha)];
x0 = stats(1).Centroid.';
a = stats(1).MajorAxisLength;
b = stats(1).MinorAxisLength;
S = diag([1, a/b]);
C = Q*S*Q';
d = (eye(2) - C)*x0;

%5. generate transformation matrix
tform = maketform('affine', [C d; 0 0 1]');

%8. transform image
Im2 = imtransform(fr, tform);
% compare the two
figure;
subplot(221);
imshow(fr,[]);
subplot(222);
imshow(Im2,[]);
subplot(223);
% xD = size(Im2,1)-size(fr,1);
% yD = size(Im2,2)-size(fr,2);
% Im2 = Im2(1:end-xD,1:end-yD);
Im2 = imresize(Im2,[size(fr,1) size(fr,2)]);
imshow(Im2-fr,[]);
%


