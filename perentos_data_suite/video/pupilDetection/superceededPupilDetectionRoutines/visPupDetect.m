function visPupDetect(fldrName,SDthr)
% 
clrs = get(gca,'colororder');
if nargin <2
    SDthr = 4;
end
if nargin <1
    error('no folder name supplied - cannot proceed');
end
%get the pupil video object
fullPath = getFullPath(fldrName);
test = (dir(fullfile(fullPath,'side*.avi')));
if ~size(test,1)
    error('there is no pupil video file .. aborting');
elseif size(test,1) == 1
    disp 'found a pupil file...'
    fileName = [test.folder,'/',test.name];
    [pth,fle,ext] = fileparts(fileName);
end

% if ~exist([pth,'/processed'])
%     disp 'making folder'
%     mkdir([pth,'/processed'])
% end

%get video details/properties
disp 'loading video object...';
obj = VideoReader(fileName);

disp 'searching for a results file'
if exist(fullfile(pth,'processed','pupilRes.mat')) == 2
    disp 'found a results file -> loading'
    load(fullfile(pth,'processed','pupilRes.mat'));
    load(fullfile(pth,'processed','pupilInit.mat'));
else
    error('cannot find a results file -. run trackPupilVideoReader script to generate');
end

%% plots

Inan = isnan(res(:,1));
display(['There are ',int2str(sum(Inan)),' frames with no pupil detection...']);
res(Inan,1) = nanmean(res(:,1));
%
ax(1)=subplot(3,1,1); hold on;
plot((res(:,1)),'color',[.7 .7 .7]); 
h(1)=plot((resSm(:,1))); axis tight;
legend([h(1)],{'Area'})
%
ax(2)=subplot(3,1,2); hold on;
plot((res(:,2)),'color',[.7 .7 .7]);
h(2)=plot((resSm(:,2))); axis tight;
legend([h(2)],{'PosX'})
%
ax(3)=subplot(3,1,3); hold on;
plot((res(:,3)),'color',[.7 .7 .7]);
h(3)=plot((resSm(:,3))); axis tight;
legend([h(3)],{'PosY'})

linkaxes(ax,'x');


figure('color',[.7 .7 .7],'position',[400,200,400,200]);
oLI = find(zscore(res(:,1))>=4);
if length(oLI)<1000
    display(['Found ',int2str(length(oLI)),' outlier frames (', num2str(SDthr),' SDs)']);
    for i = 1:4:length(oLI)
        clf;
        obj.CurrentTime = oLI(i);
        fr = obj.readFrame;
        fr = fr(pupilInit.rct(2):pupilInit.rct(2)+pupilInit.rct(4),pupilInit.rct(1):pupilInit.rct(1)+pupilInit.rct(3),:);
        imshow(fr); hold on;
        viscircles([res(i,2) res(i,3)],res(i,1));
        title(['frame no: ',int2str(oLI(i))])
        drawnow;
    end
else
    disp 'There are more than 1k frames outside 4SDs...';
    disp 'SKIPPING OUTLIER DETECTION DISPLAY...';
    disp 'Perhaps you need to refine the algorythm...';
end



%%
thr = 3;
figure('units','normalized','outerposition',[0 0 1 1]);
X = res(:,2)-mean(res(:,2));
saccades = padarray(diff(X),1,0,'pre')+padarray(diff(X,2),2,0,'pre')+...
    padarray(diff(X,3),3,0,'pre')+padarray(diff(X,4),4,0,'pre')+...
    padarray(diff(X,5),5,0,'pre');
zSaccades = zscore(saccades);clear saccades;
%
ax(1)=subplot(2,3,[1 2 3]); hold on; 
t1 = randi(length(X)-3e3,1,1);
plot(zSaccades); xlim([t1 t1+3000]); % the actual data
 % sum of the 1st 2nd, 3rd and 4th order derivatives 
% alternatively
zSacJerk = zscore(diff(X,3)); % 3rd order derivative only
plot(zSacJerk,'color',[.5 .5 .5]);
plot(zscore(X),'r');
legend('\Sigma derivs','jerk','rawXpos'); ylim([-5 5]);

idx = find(zSacJerk > 4 |  zSacJerk <-4);
plot(idx,4.1*ones(length(idx),1),'bx','MarkerSize',7);

idx = find(zSaccades > 4 |  zSaccades <-4);
plot(idx,4*ones(length(idx),1),'go','MarkerSize',7);

% find duplicate candidates
didx = diff(idx);
idx(1+[didx<=3])=[];
sacs = zeros(length(idx),41);
idx(idx<21) = []; % remove if too close to start
idx(idx>length(X)-21)=[];% remove if too close to end

for i = 1:length(idx)
    sacs(i,:) = X(idx(i)-20:idx(i)+20);
end

[coeff,score,latent,tsquared,explained,mu] = pca(sacs);
% pick first 2 components - likely to correspond to up and down saccades
varEx = explained(1:2);
subplot(2,3,4); plot(coeff(:,1:3));
legend(['PCA1:  ',int2str(explained(1)),'%'],['PCA2  :',int2str(explained(2)),'%'],['PCA3:  ',int2str(explained(3)),'%']);
Xcentered = score(:,1:2)*coeff(:,1:2)';

% cluster the eye movements
options = statset('MaxIter',1000); % Increase number of EM iterations
gmfit = fitgmdist(score(:,[1,2]),3,'CovarianceType','full',...
        'SharedCovariance',false,'Options',options);
clusterX = cluster(gmfit,score(:,[1,2]));
subplot(2,3,5);
h1 = gscatter(score(:,1),score(:,2),clusterX);
subplot(2,3,6);
plot(mean(sacs(clusterX == 1,:)',2),'r');
hold on;
plot(mean(sacs(clusterX == 2,:)',2),'g');
plot(mean(sacs(clusterX == 3,:)',2),'b');











