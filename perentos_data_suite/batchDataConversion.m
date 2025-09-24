% convert all data folders inside animal folder
% help content?
subj = 'NP5';
fldrs = dir(['/storage2/perentos/data/recordings/',subj,'/NP*']);
n = length(fldrs);

for i = 1:n
    cd([fldrs(i).folder,'/',fldrs(i).name]); 
    convertData(fldrs(i).name, oemaps);
    disp '***';disp(['Done with ',fldrs(i).name]); disp '***';
end


%% or
an = {'NP47'};
for i = 1:length(an)
    cd(fullfile('/storage2/perentos/data/recordings',an{i}));
    list{i} = dir('*/..');
    for j = 3:length(list{i})
        list{i}(j).name
        if strcmp(list{i}(j).name,'OTHER')
            continue;
        end
        %convertData(list{i}(j).name)
        %trackPupilMorpho(list{i}(j).name,1,0)
        %frameDiffROIs(list{i}(j).name,1,0);
        %videoSVD(list{i}(j).name,1,1)
        extractBehavior(list{i}(j).name)
    end
end

an = {'NP45'};
for i = 1:length(an)
    cd(fullfile('/storage2/perentos/data/recordings',an{i}));
    list{i} = dir('*/..');
    for j = 3:length(list{i})
        list{i}(j).name
        if strcmp(list{i}(j).name,'OTHER')
            continue;
        end        
        %convertData(list{i}(j).name)
        %trackPupilMorpho(list{i}(j).name,1,0)
        %frameDiffROIs(list{i}(j).name,1,0);
        %videoSVD(list{i}(j).name,1,1)
        extractBehavior(list{i}(j).name,'respCh',2)
    end
end





%% CIRCULAR ARENA TRACKING
tic;an = {'NP46', 'NP48'};
for i = 1:length(an)
    cd(fullfile('/storage2/perentos/data/recordings',an{i},'OTHER'));
    list = dir('*/..');
    for j = 3:length(list)
        cd(list(j).name);
        fle = dir('*.mp4');fle = fle.name;
        fullfile(pwd,fle)
        circularArenaTrack(fullfile(pwd,fle),0,1,0);
        cd(fullfile('/storage2/perentos/data/recordings',an{i},'OTHER'));
        close;
    end
end
toc;

% now plot for these two animals
figure('pos',[2767 1218 2800 825]); k=1;
an = {'NP46', 'NP48'};
ttls = {'empty arena control','empty cage control', 'female cage'};
for i = 1:length(an)
    cd(fullfile('/storage2/perentos/data/recordings',an{i},'OTHER'));
    list = dir('*/..');
    for j = 3:length(list)
        cd(list(j).name);
        load 'tracking.mat';
        load 'trackInit.mat';
        v = dir('*.mp4')
        obj = VideoReader(v.name);
        fr = double(rgb2gray(obj.readFrame));
        %fr = fr(10:end-10,10:end-10);
        subplot(length(an),6,k);
        imshow(fr,[]); hold on; axis equal tight off; 
        title(ttls(j-2));
    % compute and plot distribution of euclideans
        tmp = repmat([x(1) y(1)],length(tracking),1);        
        cntr = [tracking(:).Centroid];        
        cntr = reshape(cntr,2,length(cntr)/2)'; 
        plot(cntr(:,1),cntr(:,2),'color',[1,0,0,.7]); k = k+1;
        distance = sqrt((tmp(:,1)-cntr(:,1)).^2+sqrt(x(1)-y(1)).^2);                
        subplot(length(an),6,k);
        histogram(distance,[0:5:200],'Normalization','probability');axis tight; box off;
        xlabel('distance to arena center (pixels)');
        k=k+1;
        cd(fullfile('/storage2/perentos/data/recordings',an{i},'OTHER'));                
    end
end
axes('pos',[0 0 1 1]);
text(0.05,0.8,'NP46');hold on; text(0.05,0.2,'NP48');axis off;

%% ========================================================================
% batch processing of behavioral videos for three different experiments
% 1 - Neutral - Water   n=5
% 2 - Water - Aurpuff   n=5
% 3 - Nothing - Nothing n=5
% 4 - Female - Nothing  n=5 (4 followed 3 immediately for all animals)

fid = fopen('/storage2/perentos/code/BehaviourOnly/behaviouralVideoList.txt');

tline = fgetl(fid);
i=1; ii = [];
while ischar(tline)
    f{i}=(tline)
    tline = fgetl(fid);
    i = i + 1
end
fAll = f;
for i = 1:length(f)
    if strcmp(f{i},'waterVsNothing'); ii = [i ii]; end
    if strcmp(f{i},'aversiveVsAppetitive'); ii = [i ii]; end
    if strcmp(f{i},'femaleVsNothing'); ii = [i ii]; end
end
f(ii) = [];
fclose(fid);
ifRun = 0;
if ifRun % I ran these one by one making sure it was working. If it worked I then moved the loop into the ifRun statement
    % init pupils
    for  i = 1:length(f)
        % for each file run the following scripts
        trackPupilMorpho(f{i},1,0);% create pupil ROI
    end

    % init framediffs
    for  i = 1:length(f)
        close all;
        % for each file run the following scripts
        frameDiffROIs(f{i},1,0) %create nose, whisker and tongue ROIs 
    end

    % since last exp is comprised of two videos for each animal the ROIs need
    % to be identical. So lets copy the inits from each of the first recordings
    % to the second recordings
    for i = 11:2:length(f)-1
        fullPthFrom = getFullPath(f{i});    
        cd([fullPthFrom,'/processed'])

        fullPthTo = getFullPath([f{i+1},'/processed']);   
        copyfile('frameDiffROI_Init.mat', fullPthTo);
    end



    for i = 1:length(f)
        trackPupilMorpho(f{i},0,1);% create pupil ROI
    end
    
    % create resSm that was left out for the sake of speed
    for i = 1:length(f)
        pth = getFullPath(f{i});    
        cd([pth,'/processed'])
        load pupilRes.mat;
        resSm = zeros(size(res));
        for i = 1:4
            resSm(:,i) = smooth(res(:,i),4,'rlowess');
        end
         % SAVE
        save([pth,'/processed/','pupilRes.mat'],'res','resSm');
        disp(['done processing file:  ', pth,'/processed/','pupilRes.mat', ' has been saved']);
    end

    for i = 1:length(f)
        frameDiffROIs(f{i},0,1) %create nose, whisker and tongue ROIs 
    end
    
    % generate the singular value decomposition of the video energy
    for i = 1:length(f) 
        videoSVD(f{i}, 1,0);
    end
end



% get components activations
for i = 1:length(f) 
    i
    videoSVD(f{i}, 0,1);
end