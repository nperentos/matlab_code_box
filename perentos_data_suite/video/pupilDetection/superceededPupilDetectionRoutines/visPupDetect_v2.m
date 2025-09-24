function visPupDetect_v2(fileBase,tOffset, jump)
% 
clrs = get(gca,'colororder'); close;
% if nargin <2
%     SDthr = 4;
% end
if nargin <1
    error('no folder name supplied - cannot proceed');
end
%get the pupil video object
fullPath = getFullPath(fileBase);
test = (dir(fullfile(fullPath,'side*.avi')));
if isempty(test)
    test = (dir(fullfile(fullPath,'video','side*.avi')));
end
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

if nargin < 2
    %tOffset = round(obj.Duration/2);
    tOffset = obj.CurrentTime;%round(obj.Duration*obj.FrameRate;
end
if nargin < 3
    jump = 0;
end
disp 'searching for a results file'
if exist(fullfile(getfullpath(fileBase),'pupilRes.mat')) == 2
    disp 'found a results file -> loading'
    load(fullfile(getfullpath(fileBase),'pupilRes.mat'));
    load(fullfile(getfullpath(fileBase),'pupilInit.mat'));
else
    error('cannot find a results file -. run trackPupilVideoReader script to generate');
end

%% 
% figure('pos',[144   107   970*1.5   456*1.5]);
% obj.CurrentTime = tOffset;
% for i = tOffset:jump:obj.Duration
%     %clf;
%     obj.CurrentTime = i;
%     fr = obj.readFrame;
%     fr = fr(pupilInit.rct(2):pupilInit.rct(2)+pupilInit.rct(4),pupilInit.rct(1):pupilInit.rct(1)+pupilInit.rct(3),:);
%     imagesc(fr(:,:,1)); hold on;
%     viscircles(5+[res(i,2) res(i,3)],res(i,1));
%     title(['frame no: ',int2str(i)])
%     pause(0.1);hold off;
% end

%%
figure('pos',[144   107   970*1.5   456*1.5]);
obj.CurrentTime = tOffset;
while hasFrame(obj)
    fr = obj.readFrame;
    i = round(obj.CurrentTime * obj.FrameRate);
    fr = fr(pupilInit.rct(2):pupilInit.rct(2)+pupilInit.rct(4),pupilInit.rct(1):pupilInit.rct(1)+pupilInit.rct(3),:);
    imagesc(fr(:,:,1)); hold on;
    viscircles(5+[res(i,2) res(i,3)],res(i,1));
    title(['frame no: ',int2str(i)])
    pause(0.1);hold off;
    obj.CurrentTime = obj.CurrentTime + jump;        
    % keyboard
end
    