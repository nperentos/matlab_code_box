% SVD practice
close all;
figure;


fileName = '/storage2/perentos/data/recordings/NP2/NP2_2018-02-25_18-09-16/vlc-record-2018-03-15-09h46m13s-pupil2018-02-25T18_09_17.mp4';
[video, audio] = mmread(fileName,[1]);
I = rgb2gray(video.frames.cdata);


[U,S,V] = svd(double(I)); 
subplot(4,4,1); imagesc(I); title('original');


for i = 1:15
    subplot(4,4,i+1);
    S2 = S;
    S2(i+1:end,:) = 0;
    rIm = U*S2*V';
    subplot(4,4,i+1); imagesc(rIm); title(['1-',num2str(i)]);
end
colormap('gray');

figure;
for i = 1:15
    subplot(4,4,i+1);
    S2 = S;
    S2(i+1:end,:) = 0;
    if i>1; S2(1:i-1,:) = 0; end
    rIm = U*S2*V';
    subplot(4,4,i+1); imagesc(rIm); title(num2str(i));
end
colormap('gray');