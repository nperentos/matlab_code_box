function [out] = getGummyEye(fileBase,varargin)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function [out] = getGummyEye(fileBase) used predefined eyeROI from side
% video of headfixed recording to compute the amount of whiteness insde
% this subframe. The whiteness of this grayscale video is used here as an
% estimate of the possibility that the animal has gummy eye, which can then
% be used to define reliable and unreliable frames within the recording. 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% PRE
    options = {'motherFrame', 1,'flag',1,'track',1,'session_pth',[],'vidName','face','abs_vid_path',[],'verbose',0,'ROI',[],'ncomp',10};
    options = inputparser(varargin,options);
    ROI = [];
    lastsize = 0;
    pr_pth = fullfile(getfullpath(fileBase));
    
    if ~isempty(options.session_pth)
        fullPath = getFullPath(fileBase,options.session_pth); % path to session
    else
        fullPath = getFullPath(fileBase); % path to session
    end
    
    if isempty(options.abs_vid_path) % assume NPerentos file strcuture
        disp('no video file was specified so going with the default option of side*.avi');
        test = (dir(fullfile(fullPath,'video','side*.avi')));
        if ~size(test,1)
            warning('there is no video file .. aborting');
            return
        elseif size(test,1) == 1
            disp 'found a side* video file; continuing with data processing...'
            fileName = [test.folder,'/',test.name];
            [vid_pth,fle,ext] = fileparts(fileName);
            options.vidName = 'face';
        end
    else
        if exist(options.abs_vid_path)
            [vid_pth,fle,ext] = fileparts(options.abs_vid_path);
        else
            error(['there is no such video so aborting',options.abs_vid_path]);
        end
    end
        
    if isempty(options.ROI) % these are Nikolas' default ROIs
        options.ROI.names = {'fixed_point','whisker_pad','snout','tongue','ear','eye'};
        options.ROI.pts = zeros(length(options.ROI.names),4);
    end
    
    % get video object
    obj = VideoReader(fileName);
    nFr = obj.Duration*obj.FrameRate;
    %nFr = 5000; %for testing purposes
    strt = obj.CurrentTime;

    % pull in exisiting ROIs, otherwise abort to avoid additional checks
    if exist(fullfile(getfullpath(fileBase),[options.vidName,'ROIs.mat']),'file')
        load(fullfile(getfullpath(fileBase),[options.vidName,'ROIs.mat']));        
        idx = find(strcmp(ROI.names,'eye'));
        if ~isempty(idx)
            pts = ROI.pts(idx,:);
        else
            error('I can see an ROIs.mat but it does not contain an eye ROI. Please investigate ... Aborting');
        end
            
    else
        error('I cannot find ROI definitions. Please make sure to first run initialiseVideoAnalysis.m ... Aborting');
    end

%% COMPUTE THE GAMMUT OF EACH FRAME
    fprintf('computing image histograms and correlation of frames with mother frame...');
    tic
    mFr = rgb2gray(im2double(obj.readFrame)); % the mother frame    
    mFr = mFr(pts(2):pts(2)+pts(4) , pts(1):pts(1)+pts(3) );
    activity = nan(nFr,50);
    CC = nan(nFr,1);
    obj.CurrentTime = strt;
    for i = 1:nFr
        fr = rgb2gray(im2double(obj.readFrame));
        sFr = fr(pts(2):pts(2)+pts(4) , pts(1):pts(1)+pts(3) );
        [activity(i,:),b] = hist(sFr(:),50);
        CC(i) = corr(sFr(:),mFr(:));
    end
    fprintf(' DONE.\n');    


%% CLUSTER THE PIXEL INTENSITY DISTRIBUTIONS
    nClu = 3; clr = {'r','g','b'};
    [IDX, C, ~, D] = kmeans(activity, nClu);
    
    
    
%%  SAVE
    fprintf('saving ''gummy eye'' data...');
    gummyEye.pxIntensity = activity;
    gummyEye.CC = CC;  
    gummyEye.motherFrame = mFr;
    save(fullfile(getfullpath(fileBase),'gummyEye.mat'),'gummyEye','-v7.3');  
    
    % print a figure
    figure('pos',[603 231 1380 1413]); 
    subplot(7,3,[1:6]); imagesc(gummyEye.pxIntensity'); 
        xlabel('time');set(gca,'XTick',[]);ylabel('intensity histograms'); 
    subplot(7,3,[7:9]); imagesc(IDX'); axis on; ylabel('clusters');xlabel('time');set(gca,'XTick',[]);
        colormap(gca,[1 0 0; 0 1 0; 0 0 1]);
    subplot(7,3,[10:10+5]); gscatter([1:1:length(gummyEye.CC)],gummyEye.CC,IDX); 
        axis tight; xlabel('time'); ylabel('CC with ''good'' frame');  
    mtit('gummyEye detection');
    % use the centroids to find representative frames and plot them below
    for i = 1:nClu
        subplot(7,3,[15+i, 18+i]); 
        [~,frfr] = min(D(:,i)); 
        obj.CurrentTime = frfr;
        imshow(rgb2gray(im2double(obj.readFrame)));
        title(['clu:',num2str(i)],'FontSize',14,'FontWeight','bold','Color',clr{i})
    end
    
    
    print(fullfile(getfullpath(fileBase),'gummyEye_summary.jpg'),'-djpeg');
    disp('DONE!\n');
    
    
    % just a visualisation during development - not needed otherwise
    %     figure; subplot(311); imshow(sFr); subplot(312);imhist(sFr);   
    %     [a,b] = hist(sFr(:),100);    
    %     subplot(313);bar(b,a);
    %     
    %     
    %     sFr(1:20,1:30) = 1;
    %     
    %     
    %     figure; subplot(311); imshow(sFr); subplot(312);imhist(sFr);   
    %     [a,b] = hist(sFr(:),100);    
    %     subplot(313);bar(b,a);   
    
    if options.verbose
        figure('pos',[192 -404 960 1315]); subplot(211); imagesc(log(activity')); ylabel('CLLICK HERE TO EXIT...')
        x = 1; cont = 1;
        %axes('pos',[0.01 0.95 0.2 0.05]); 
        %plot(0.1 ,0.5,'or','markersize',12,'markerfacecolor','r');
        %text(0.15,0.5,'click here to exit');
        %axis off;xlim([0 1]);ylim([0 1]);
        while cont 
            [x,~] = ginput(1);
            if x < 0
                cont = 0;
                x=1;
                continue;
            end
            obj.CurrentTime = round(x);
            subplot(212);
            imshow(rgb2gray(im2double(obj.readFrame)));
            %waitforbuttonpress
        end
        close;
      display('exited the visualiser');
    end
      
      
      
      
    
      
      
      
      
