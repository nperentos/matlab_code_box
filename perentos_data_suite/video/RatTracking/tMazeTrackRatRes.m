function tMazeTrackRatRes(paths)

%% RESULTS OF RAT EXPOSURE TO FEMALE STIMULUS IN THE CIRCULAR/T-MAZE ARENA
% cd('/storage2/perentos/data/recordings/Rats/results');
% mkdir('report1');
% PublishOptions.outputDir = fullfile(pwd,'report1');
% publish('tMazeTrackRatRes.m',PublishOptions);

% load one of the coordinates file with the assumption that they stay the
% same ie. the maze doesnt move for recordings across and within days

allPaths = {'/storage2/perentos/data/recordings/Rats/femaleExposureVideos/Habituation_day1_2019-03-06/Videos',...
    '/storage2/perentos/data/recordings/Rats/femaleExposureVideos/Habituation_day2_2019-03-07/Videos',...
    '/storage2/perentos/data/recordings/Rats/femaleExposureVideos/Habituation_day3_2019-03-08/Videos',...
    '/storage2/perentos/data/recordings/Rats/femaleExposureVideos/Test_2019-03-09/Videos'};
cd(allPaths{1})
coo = dir('coo*.mat');
coo = {coo.name}';
load(coo{1});

%% GET PATHS AND FRAME BY FRAME POSITION
if ~exist('/storage2/perentos/data/recordings/Rats/results/trackingAll.mat')
    k = 0;
    for i = 1:length(allPaths)
        cd(allPaths{i})
        % get also tracking
        fls = dir('tr*.mat');
        fls = {fls.name}';
        % get also video fps
        flv = dir('*.avi');
        flv = {flv.name}';
        % get also the coordinates mat file
        coo = dir('coo*.mat');
        coo = {coo.name}';

        for j = 1:length(fls)
            k=k+1;
            load(fls{j});
            load(coo{j});
            obj = VideoReader(flv{j});
            allTracking(k).data = tracking;
            allTracking(k).fileName = coo{j};
            allTracking(k).day = i;
            allTracking(k).fps = obj.FrameRate;
            allTracking(k).Width = obj.Width;
            allTracking(k).Height = obj.Height;
        end

    end
    save('/storage2/perentos/data/recordings/Rats/results/trackingAll.mat','allTracking');   
end

%% STORE TRACKING RESULTS IN A CONVENIENT FORMAT (baseline, female and recall)
clear tracking;
load('/storage2/perentos/data/recordings/Rats/results/trackingAll.mat');  
animal = {'787','788'};
mins = 9; % minutes from start of video to analyse
for n = 1:2 % animal number
    str = animal(n);
    idx = strfind({allTracking(:).fileName},str);
    idx = find(~cellfun(@isempty, idx));
    idx2 = strfind({allTracking(:).fileName},'Female');
    idx2 = find(~cellfun(@isempty, idx2));
    female = intersect(idx,idx2);
    idx3 = strfind({allTracking(:).fileName},'recall');
    idx3 = find(~cellfun(@isempty, idx3));
    recall = intersect(idx,idx3);
    habituation = setdiff(idx,[recall female]);
    
% habituation percentages for each ROI
    figure('pos',[84         561        1802         437]);
    for i = 1:length(habituation)
        subplot(3,length(habituation),i);
        tracking = allTracking(habituation(i)).data;
        H = allTracking(habituation(i)).Height;
        W = allTracking(habituation(i)).Width;
        fps = allTracking(habituation(i)).fps;
        test = [tracking.Centroid];
        test = reshape(test,2,[])';
        test(:,1) = smooth(test(:,1),15);
        test(:,2) = smooth(test(:,2),15);
        test = round(test);
        
        % lets truncate test to the first 10 minutes 
        test = test(1:mins*60*fps,:);        
        x_ = 0:25:W;
        y_ = 0:25:H;
        [a,b]=hist3(test,{x_,y_});
        hTmp = imagesc(x_,y_,a');colMap = colormap('jet'); colMap(1,:) = 1;
        colormap(colMap);caxis([2,prctile(a(:),95)]);
        ylabel('habituation');
        display([num2str(100*(length(test)/length(tracking)),'%5.2f '),'% of frames have a detection within the specified ROIs']);
        % count points within each video mask 
        res(n).hab(i,1) = sum(ismember(sub2ind(size(M_arm),test(:,2),test(:,1)),find(M_arm)));
        res(n).hab(i,2) = sum(ismember(sub2ind(size(M_arm),test(:,2),test(:,1)),find(L_arm)));
        res(n).hab(i,3) = sum(ismember(sub2ind(size(M_arm),test(:,2),test(:,1)),find(R_arm)));
        res(n).hab(i,4) = sum(ismember(sub2ind(size(M_arm),test(:,2),test(:,1)),find(C_road)));
        res(n).hab(i,5) = sum(ismember(sub2ind(size(M_arm),test(:,2),test(:,1)),find(L_cage)));
        res(n).hab(i,6) = sum(ismember(sub2ind(size(M_arm),test(:,2),test(:,1)),find(R_cage)));
    end
% female percentages for each ROI
    for i = 1:length(female)
        subplot(3,length(habituation),length(habituation)+i); 
        tracking = allTracking(female(i)).data;
        H = allTracking(female(i)).Height;
        W = allTracking(female(i)).Width;
        fps = allTracking(female(i)).fps;
        test = [tracking.Centroid];
        test = reshape(test,2,[])';
        test(:,1) = smooth(test(:,1),15);
        test(:,2) = smooth(test(:,2),15);
        test = round(test);  
        
        % lets truncate test to the first x minutes 
        test = test(1:mins*60*fps,:);        
        x_ = 0:25:W;
        y_ = 0:25:H;
        [a,b]=hist3(test,{x_,y_});
        hTmp = imagesc(x_,y_,a');colMap = colormap('jet'); colMap(1,:) = 1;
        colormap(colMap);caxis([2,prctile(a(:),95)]);
        ylabel('female');
        display([num2str(100*(length(test)/length(tracking)),'%5.2f '),'% of frames have a detection within the specified ROIs']);
        % count points within each video mask 
        res(n).fem(i,1) = sum(ismember(sub2ind(size(M_arm),test(:,2),test(:,1)),find(M_arm)));
        res(n).fem(i,2) = sum(ismember(sub2ind(size(M_arm),test(:,2),test(:,1)),find(L_arm)));
        res(n).fem(i,3) = sum(ismember(sub2ind(size(M_arm),test(:,2),test(:,1)),find(R_arm)));
        res(n).fem(i,4) = sum(ismember(sub2ind(size(M_arm),test(:,2),test(:,1)),find(C_road)));
        res(n).fem(i,5) = sum(ismember(sub2ind(size(M_arm),test(:,2),test(:,1)),find(L_cage)));
        res(n).fem(i,6) = sum(ismember(sub2ind(size(M_arm),test(:,2),test(:,1)),find(R_cage)));
    end
% recall percentages for each ROI
    for i = 1:length(recall)
        subplot(3,length(habituation),2*length(habituation)+i); 
        tracking = allTracking(recall(i)).data;
        H = allTracking(recall(i)).Height;
        W = allTracking(recall(i)).Width;
        fps = allTracking(recall(i)).fps;
        test = [tracking.Centroid];
        test = reshape(test,2,[])';
        test(:,1) = smooth(test(:,1),15);
        test(:,2) = smooth(test(:,2),15);
        test = round(test);
        
        % lets truncate test to the first x minutes 
        test = test(1:mins*60*fps,:);        
        x_ = 0:25:W;
        y_ = 0:25:H;
        [a,b]=hist3(test,{x_,y_});
        hTmp = imagesc(x_,y_,a');colMap = colormap('jet'); colMap(1,:) = 1;
        colormap(colMap);caxis([2,prctile(a(:),95)]);
        ylabel('recall');
        display([num2str(100*(length(test)/length(tracking)),'%5.2f '),'% of frames have a detection within the specified ROIs']);
        % count points within each video mask 
        res(n).rec(i,1) = sum(ismember(sub2ind(size(M_arm),test(:,2),test(:,1)),find(M_arm)));
        res(n).rec(i,2) = sum(ismember(sub2ind(size(M_arm),test(:,2),test(:,1)),find(L_arm)));
        res(n).rec(i,3) = sum(ismember(sub2ind(size(M_arm),test(:,2),test(:,1)),find(R_arm)));
        res(n).rec(i,4) = sum(ismember(sub2ind(size(M_arm),test(:,2),test(:,1)),find(C_road)));
        res(n).rec(i,5) = sum(ismember(sub2ind(size(M_arm),test(:,2),test(:,1)),find(L_cage)));
        res(n).rec(i,6) = sum(ismember(sub2ind(size(M_arm),test(:,2),test(:,1)),find(R_cage)));
    end
end
        

% PLOT OCCUPANCIES WITHIN ROIs AS A HEAT MAP
for n = 1:2
    tmp = res(n).hab;
    results = tmp./repmat(sum(tmp,2),1,size(tmp,2));
    tmp = res(n).fem(:,:);
    tmp = tmp./sum(tmp);
    results = [results; tmp];
    tmp = res(n).rec(:,:);
    tmp = tmp./sum(tmp);
    results = [results; tmp];    
    figure;
    imagesc(results(:,:)');%[2 3 5 6]
    title(animal{n});
    yticklabels({'middle arm','left arm','right arm','center road','left cage','right cage'});
    h = text(max(xlim)-2-.2,3.5+.2,'female'); set(h,'Rotation',45);
    h = text(max(xlim)-1-.2,3.5+.2,'recall'); set(h,'Rotation',45);
    xlabel(['habituation: 1 to ',num2str(max(xlim)-2.5),', female:' num2str(max(xlim)-1.5),' and recall:', num2str(max(xlim)-.5)]);
    ylabel('maze ROI');
    colorbar;
end




