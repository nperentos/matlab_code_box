cd '/storage2/perentos/data/recordings/NP16/NP16_2018-09-15_14-50-03/side_cam_1_date_2018_09_15_time_14_49_56_v001';
fname = 'hello.tiff';
info = imfinfo(fname);
numImages = numel(info);
figure(1);
for i = 310:350%numImages
    A = imread(fname, i, 'Info', info); 
    imshow(A); title(num2str(i));
    drawnow;
    waitforbuttonpress;   
end