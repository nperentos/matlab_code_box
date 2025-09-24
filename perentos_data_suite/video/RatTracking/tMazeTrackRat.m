function [] = tMazeTrackRat(fileBase,femFlag,verbose)
% extracts animal location from behavioral video
% ---I/O
% fileBase: folder of animal e.g. 'NP24'
% femFlag: if data includes female & subsequent session set this flag = 1
% verbose: disply tracking or not

%% CREATE ROIs
close all;
tMazeTrackRatHelper(fileBase);

%% GET VIDEOS AND PRODUCE AND SAVE TRACKING
clrs = get(gca,'colororder'); close;
cd(fileBase);
fls = dir('*.avi');
fls = {fls.name}';

for v = 1:length(fls)
    load(['coo_',fls{v}(1:end-3),'mat'])
    fls{v}
    % first we check if the tracking has already been produced   
    obj = VideoReader(fls{v});
    nrFr = round(obj.Duration*obj.FrameRate);
    obj.CurrentTime = 1;
    bgFr = rgb2gray(im2double(obj.readFrame));
    obj.CurrentTime = 0;
    i=1;
    if exist(['tracking_',fls{v}(1:end-3),'mat']); continue; end
    % if not continue processing  
    wb = waitbar(0,['processing file ',int2str(v),'/',int2str(length(fls))]);
    if verbose; figure('WindowStyle','docked'); end
    while obj.hasFrame   
        fr = rgb2gray(im2double(obj.readFrame));
        frDf = fr - bgFr;
        %subplot(131); 
        if verbose; imagesc(fr);colormap gray; end;
        tmpscale = prctile(abs(frDf(:)),[98, 100]);
        thFr = rescale(frDf,tmpscale);
        %subplot(132); imagesc(thFr);

        Gb=thFr./max(max(thFr)); Gb=Gb./max(max(Gb));% normalise to 1
        Gb = imbinarize(Gb);         % binarise
        bw = bwareaopen(Gb,100);    % remove small regions (work on inverted image)
%         se = strel('disk',5);        % fill in small diskoid gaps (light reflection)
%         bw = imclose(~bw,se);
%         imagesc(bw);
%         bw=~bw;
        [B,L] = bwboundaries(bw,'noholes');
        stats = regionprops(L,'Area','Centroid','MajorAxisLength','MinorAxisLength');
        if ~isempty(stats); tracking(i) = stats(1); end
        if verbose
            if ~isempty(stats)
                viscircles(stats(1).Centroid,stats(1).MajorAxisLength);
                title(['t=',num2str(obj.CurrentTime),', X=',int2str(stats(1).Centroid(1)),' ,Y=',int2str(stats(1).Centroid(2))]);
                drawnow;
            end
        end
%         if obj.CurrentTime == 45
%             keyboard;
%         end
        i = i+1;
        waitbar(i/nrFr,wb,'processing');
    end
    save(['tracking_',fls{v}(1:end-4),'.mat'],'tracking');
    close(wb)
    clearvars -except fileBase femFlag fls verbose bgFr clrs;   
end
flsAvi = fls;


%% COMPUTE OCCUPANCIES
fls = dir('tr*.mat');
fls = {fls.name}';
% get also the coordinates mat file!
coo = dir('coo*.mat');
coo = {coo.name}';
for i = 1:length(fls)
    load(fls{i});
    load(coo{i});
    
    figure;
    obj = VideoReader(flsAvi{i});
    obj.CurrentTime = 1;
    fr = readFrame(obj);
    %imshow(bgFr); hold on;
    z=0;
    g = hgtransform('Matrix',makehgtform('translate',[0 0 z]));
    imagesc(g,fr); 
    %     colormap gray; hold on;
    %     scatter(test(:,1),test(:,2),'bx');
    set(gca,'Ydir','reverse');
    hold on;
    visboundaries(M_arm ,'color','r');
    visboundaries(C_road,'color','g');
    visboundaries(R_arm ,'color','b');
    visboundaries(L_arm,'color','w');
    visboundaries(R_cage,'color','m');
    visboundaries(L_cage,'color','y');
    
 % report how many frames have a detection
    test = [tracking.Centroid];
    test = reshape(test,2,[])';
    test(:,1) = smooth(test(:,1),15);
    test(:,2) = smooth(test(:,2),15);
    test = round(test);
    display([num2str(100*(length(test)/length(tracking)),'%5.2f '),'% of frames have a detection within the specified ROIs'])
    tmp = sum(abs(diff(test,1)),2);
    speed{i} = [0; tmp]; clear tmp;
    x_ = 0:30:size(bgFr,2);
    y_ = 0:30:size(bgFr,1);
    [a,b]=hist3(test,{x_,y_});
    %sig = imgaussfilt(log(1e-9+a'),2)
    %figure;
    z=1;
    g = hgtransform('Matrix',makehgtform('translate',[0 0 z]));
    hTmp = imagesc(g,x_,y_,a');colMap = colormap('jet'); colMap(1,:) = 1;
    colormap(colMap);caxis([2,prctile(a(:),95)]);
    hold on;
    I = imbinarize(a');
    set (hTmp, 'AlphaData', I);
    %hTmp.AlphaData = 0.5;
    view(3);
    
% count points within each video mask 
    occupancies(1,i) = sum(ismember(sub2ind(size(fr),test(:,2),test(:,1)),find(M_arm)));
    occupancies(2,i) = sum(ismember(sub2ind(size(fr),test(:,2),test(:,1)),find(L_arm)));
    occupancies(3,i) = sum(ismember(sub2ind(size(fr),test(:,2),test(:,1)),find(R_arm)));
    occupancies(4,i) = sum(ismember(sub2ind(size(fr),test(:,2),test(:,1)),find(C_road)));
    occupancies(5,i) = sum(ismember(sub2ind(size(fr),test(:,2),test(:,1)),find(L_cage)));
    occupancies(6,i) = sum(ismember(sub2ind(size(fr),test(:,2),test(:,1)),find(R_cage)));
   
    
% plot distribution of speeds for whole sessions
    figure(200);set(gcf,'position',[90 260 1987 456]);
    subplot(1,length(fls),i);
    tmp = find(speed{i}<prctile(speed{i},99.5));
    histogram(speed{i}(tmp),50); set(gca,'yscale','log'); xlim([0 50]);
    
end 
figure(200);
axes('position',[0 0 1 1]);
text(.1,.9,fileBase)
xlim([0 1]);ylim([0 1]);axis off; 
Image = getframe(gcf);
imwrite(Image.cdata, 'speedDistr.jpg');
% normalise the cage occupanices
occupancies = (occupancies./total)';
cageOcc = (cageOcc./sum(cageOcc,1))';

% bar plot of cage occupancies
%     if femFlag % if all sessions are present treat female and recall differently
        nd = length(fls);
%     else
%         nd = length(fls);
%     end
    figure;
    plot(ones(1,length(cageOcc(1:nd,1))),cageOcc(1:nd,1),'ok','MarkerFaceColor','k'); hold on;
    plot(2*ones(1,length(cageOcc(1:nd,2))),cageOcc(1:nd,2),'ob','MarkerFaceColor','b');
    if femFlag 
        % plot female session        
        plot(ones(1,length(cageOcc(end-1,1))),cageOcc(end-1,1),'or','MarkerFaceColor','r','MarkerSize',14);
        plot(2*ones(1,length(cageOcc(end-1,2))),cageOcc(end-1,2),'or','MarkerFaceColor','r','MarkerSize',14);
        % plot recall session
        plot(ones(1,length(cageOcc(end,1))),cageOcc(end,1),'o','MarkerFaceColor',clrs(3,:),'MarkerSize',14,'MarkerEdgeColor',clrs(3,:));
        plot(2*ones(1,length(cageOcc(end,2))),cageOcc(end,2),'o','MarkerFaceColor',clrs(3,:),'MarkerSize',14,'MarkerEdgeColor',clrs(3,:));
    end
    xlim([0 3]);
    xlabel('cage'); set(gca,'XTick',[1,2],'XTickLabel',{'right','left'});
    ylabel(['normalised occupancy']);
    text(2.4,.9,'habituation days'); plot([2 2.3],[.9 .9],'k','linewidth',4);
    text(2.4,.86,'habituation days');plot([2 2.3],[.86 .86],'b','linewidth',4);
    if femFlag 
        text(2.4,.82,'female day');plot([2 2.3],[.82 .82],'r','linewidth',4);
        text(2.4,.78,'recall');plot([2 2.3],[.78 .78],'color',clrs(3,:),'linewidth',4);
    end
    box off;

%% PLOT OCCUPANCY ON IMAGES
figure; 
clrMap = jet;
mx = max(occupancies(:));
day = [1 1 1 2 2 2 3 3 3 3];
a = numSubplots(length(fls));
for i = 1:length(fls)
    load(coo{i});
    subplot(a(1),a(2),i);
    imshow(bgFr); colormap gray; hold on;caxis([0 0.5]);
    title(['exp. ',int2str(i),' day', int2str(day(i))],'FontSize',10);
    if femFlag 
        if i == nd-1; title(['female exposure',' day', int2str(day(i))]); end
        if i == nd; title(['recall',' day', int2str(day(i))]); end
    end
    %if i == 6; keyboard; end
    p1 = patch(xM,yM,'g','FaceColor',clrMap(round((occupancies(i,1)/mx)*64),:),'EdgeColor','w');
    p1.FaceAlpha = 0.3; 
    p1 = patch(xC,yC,'g','FaceColor',clrMap(round((occupancies(i,2)/mx)*64),:),'EdgeColor','w');
    p1.FaceAlpha = 0.3;
    p1 = patch(xR,yR,'g','FaceColor',clrMap(round((occupancies(i,3)/mx)*64),:),'EdgeColor','w');
    p1.FaceAlpha = 0.3;
    p1 = patch(xL,yL,'g','FaceColor',clrMap(round((occupancies(i,4)/mx)*64),:),'EdgeColor','w'); 
    p1.FaceAlpha = 0.5;
end
    
axes('position',[0.86 0.15 0.1 0.1]);
colormap jet;
h = colorbar;
h.Label.String= 'occupancy';
caxis([0 0.5]);
axis off; 

axes('position',[0 0 1 1]);
text(.1,.9,fileBase)
xlim([0 1]);ylim([0 1]);axis off; 

% save image of occupancies superimposed onto the video image
%set(gcf, 'Position', get(0, 'Screensize'));
set(gcf, 'Position', [0   0   2000   600]);
Image = getframe(gcf);
imwrite(Image.cdata, 'occupanciesOnImage.jpg');
% save the occupancies for later group processing
save('occupancies.mat','occupancies','cageOcc');
%% COMPUTE STATS
% BIAS
    display 'results for the training sessions'; 
    display(' ');
    [H,P,CI,STATS] = ttest(occupancies(1:nd,3)-occupancies(1:nd,4))
    if CI > 0 & P <0.05
        display('-----------------------------------------');
        display('the animal favours right arm (O symbol).');
        display(['mu = ', num2str(100*mean(occupancies(1:nd,3)),'%2.2f'),'%, and std = ',num2str(100*std(occupancies(1:nd,3)),'%2.2f'),', P = ', num2str(P)])
        disp 'VS'
        display(['mu = ', num2str(100*mean(occupancies(1:nd,4)),'%2.2f'),'%, and std = ',num2str(100*std(occupancies(1:nd,4)),'%2.2f'),' (left)']);
        display('-----------------------------------------');
    elseif CI < 0 & P <0.05
        display('-----------------------------------------');
        display('the animal favours left arm (horizontal lines symbol).');
        display(['mu = ', num2str(100*mean(occupancies(1:nd,4)),'%2.2f'),'%, and std = ',num2str(100*std(occupancies(1:nd,4)),'%2.2f'),', P = ', num2str(P)])
        disp 'VS'
        display(['mu = ', num2str(100*mean(occupancies(1:nd,3)),'%2.2f'),'%, and std = ',num2str(100*std(occupancies(1:nd,3)),'%2.2f'),' (left)']);
        display('-----------------------------------------');
    elseif P > 0.05
        display('-----------------------------------------------------------------------------');
        display('the animal does not show statistically significant preference for either side');
        display('-----------------------------------------------------------------------------');
    end

if femFlag
    display 'results for female day:';
    display('');
% female test
    [h,p] = ztest(occupancies(end-1,4),mean(occupancies(1:end-2,4)),std(occupancies(1:end-2,4)));
    if p < 0.05
        display('-----------------------------------------');
        display(['The mouse spent significantly more time at the female''s location during the female exposure.']);
        display(['P = ', num2str(p,'%1.3f')]); 
    else
        display('-----------------------------------------');
        display(['The mouse did not spent more time at the female''s location during the female exposure.']);
        display(['P = ', num2str(p,'%1.3f')]); 
    end
% recall test        
    [h,p] = ztest(occupancies(end,4),mean(occupancies(1:end-2,4)),std(occupancies(1:end-2,4)));
    if p < 0.05
        display('-----------------------------------------');
        display(['The mouse spent significantly more time at the female''s location during recall.']);
        display(['P = ', num2str(p,'%1.3f')]); 
        display('-----------------------------------------');
    else
        display('-----------------------------------------');
        display(['The mouse did not spent more time at the female''s location during recall.']);
        display(['P = ', num2str(p,'%1.3f')]);  
        display('-----------------------------------------');
    end
end




















