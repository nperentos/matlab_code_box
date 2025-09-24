%based on 
% https://de.mathworks.com/help/images/ref/imregconfig.html

fixed = dicomread('knee1.dcm');
distorted = imtranslate(fixed,[5.3, -10.1],'FillValues',255);
fixed = fixed(128:384,128:384);
distorted = distorted(128:384,128:384);
imshowpair(fixed, distorted,'montage','Scaling','joint')

[optimizer, metric] = imregconfig('monomodal')

% optimizer.InitialRadius = 0.009;
% optimizer.Epsilon = 1.5e-4;
% optimizer.GrowthFactor = 1.01;
% optimizer.MaximumIterations = 300;

tform = imregtform(distorted, fixed, 'translation' , optimizer, metric)

movingRegistered = imwarp(distorted,tform,'OutputView',imref2d(size(fixed)));

figure
imshowpair(fixed, movingRegistered,'montage','Scaling','joint')



% there is also another way which uses a function called fitgeotrans
% https://de.mathworks.com/help/images/examples/find-image-rotation-and-scale-using-automated-feature-matching.html
% requires control points


% yet another method is here
% https://de.mathworks.com/help/images/examples/find-image-rotation-and-scale-using-automated-feature-matching.html
% requires control points

% another example that might be useful in helping to understand how images
% are/should be padded to avoid edge effects?
%% Apply Horizontal Shear to Image
% 
%%
% Read grayscale image into workspace and display it.

% Copyright 2015 The MathWorks, Inc.

I = imread('cameraman.tif');
imshow(I)
%%
% Create a 2-D geometric transformation object.
tform = affine2d([1 0 0; .5 1 0; 0 0 1])
%%
% Apply the transformation to the image.
J = imwarp(I,tform);
figure
imshow(J)