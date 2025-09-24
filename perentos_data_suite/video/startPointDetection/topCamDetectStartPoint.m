function topCamDetectStartPoint(fldr)

% this is a script to extract starting point time stamps from the top video
% camera. I wrote it to validate the video time stamps.It turns out that
% the reported frame rate is not correct. There is a factor of X.X if one
% wants to stretch the frame rate so that it matches with the
% electrophysiology

datestr(now)
%fileName = '/storage2/perentos/data/recordings/NP3/NP3_2018-04-11_19-37-06/top2018-04-11T19_37_10.avi';
%fileName = '/storage2/perentos/data/recordings/NP1/NP1_2018-04-10_10-22-25/top2018-04-10T10_22_27.avi';
%fldr = 'NP1_2018-04-10_10-22-25';
processedPath = getfullpath(fldr); % folder to keep processed data figs etc
fullPath = getFullPath(fldr);
cd(fullPath)
% find the top video
test = (dir(fullfile(fullPath,'top*.avi')));
if ~size(test,1)
    error('there is no pupil video file .. aborting');
elseif size(test,1) == 1
    disp 'found a top video file; continuing with data processing...'
    fileName = [test.folder,'/',test.name];
    %[pth,fle,ext] = fileparts(fileName);
    [video, audio] = mmread(fileName,[1:1000]);
end

%[video, audio] = mmread(fileName,[],[],false,true);
datestr(now)
% figure; colormap gray;
% w = warning ('off','all');
% % for j = [30:55, 400:500] %ength(video.times)
% for j = [300:450] %ength(video.times)
%     data = double(video.frames(j).cdata);
%     data = sq(data(:,:,1));
%     scl = prctile(data(:),[80, 85]);
%     data = rescale(data,scl);
%     imagesc(data);
%     title(['frame:', int2str(j)])
%     drawnow;
% end
% datestr(now)
% clear  data data1;

%% run the threshold detection for all frames and drawnow
%get template
close all; figure('pos',[50 50 960 456]);
data = double(video.frames(960).cdata);
data = sq(data(:,:,1));
data = data([1:4:end],[1:4:end]);
%pctles = [0 100];
%scl = prctile(data(:),pctles);
%data = rescale(data,scl);
disp 'select template';
clf;imagesc(data); colormap gray;
rctT = round(getrect(gcf));
template = data(rctT(2):rctT(2)+rctT(4),rctT(1):rctT(1)+rctT(3),:);
%template = template-mean(template(:))-1/length(template(:));
template = template-mean(template(:));
% what is the actualy peak of the frame with starting point object visible?
C = conv2(data,template,'valid');
nf = max(C(:));
disp 'select start area (with tolernace)'
rct = round(getrect(gcf));

verbose = 0;
clf;
out = nan(video.nrFramesTotal,1); 

% lets import about 3k frames = 8.1 gb of data for 720x1280 ! at a time
N = abs(video.nrFramesTotal);
sz = 3000;
chunks = (N-rem(N,sz))/sz;
remSz = rem(N,sz);
datestr(now)
for j = 1:chunks+1
    from = 1+((j-1)*sz); 
    to = ((j-1)*sz)+sz;
    if j == chunks+1 
        from = 1+((j-1)*sz);
        to = ((j-1)*sz)+remSz;
    end
    disp(['looking at frames:',int2str(from),'---',int2str(to)]);
    [video, audio] = mmread(fileName,[from:to]);
    frmN = from:to;
    % core detection
    for i = 1:(to-from)%from:to%video.nrFramesTotal
%         try
        data = double(video.frames(i).cdata);
%         catch
%             disp(['>missing frame - ',int2str(frmN(i))]);
%             continue;
%         end
        data = sq(data(:,:,1));
        data = data([1:4:end],[1:4:end]);
        % do the detection here with already gen. templ.
        C = conv2(data,template,'valid');
        %mask = C>max(C(:))*.70;
        mask = C>nf*0.7;
    %     out(i) = sum(sum(mask((rct(2)-round(rct(4)/2):rct(2)-round(rct(4)/2)+rct(4)),(rct(1)-round(rct(3)/2):rct(1)-round(rct(3)/2)+rct(3)))));    
        out(frmN(i)) = sum(sum(mask((rct(2)-round(rct(4)/2):rct(2)-round(rct(4)/2)+rct(4)),(rct(1)-round(rct(3)/2):rct(1)-round(rct(3)/2)+rct(3)))));    
        topCamTimes(frmN(i)) = video.times(i);
        if verbose
            subplot(1,6,[1 2]);
            imagesc(data);
            title(['frame:', int2str(frmN(i))]);
            rectangle('Position',[rct(1) rct(2) rct(3) rct(4)],'edgecolor','r');
            subplot(1,6,[3 4]); imagesc(mask);
            newRect = [rct(1)-round(rct(3)/2) rct(2)-round(rct(4)/2) rct(3) rct(4)];
            rectangle('Position',newRect,'edgecolor','r');
            subplot(1,6,[5]);
            bar(out(i)); ylim([0 50]);
            drawnow;
        end
    end
    datestr(now)    
end

if exist([processedPath,'topCamStartPoint.mat'],'file') ~= 2   
    disp '>saving data<';
    topNrFramesTotal = abs(video.nrFramesTotal);
    topCamRate = video.rate;
    save([processedPath,'topCamStartPoint'],'out', 'rct','rctT','topNrFramesTotal','topCamRate','topCamTimes');
end
