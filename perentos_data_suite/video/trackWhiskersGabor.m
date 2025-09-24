function trackWhiskersGabor(fileBase,varargin)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% trackWhiskers tracks whisker movement using a battery of gabor orientend 
% filters inside an ROI in which the whiskers could move. Two ROIs
% need to be defined, one for the left and one for the right whisker. 
% INPUTS: fileBase: recording session folder name
%         init: a flag for ROI initialisation (ignored if pre initialised,
%         unless you delete the initialisation paramets (whiskerROIs.mat)
% OUTPUTS: whisker.angle: filter angle that best matches the image
%          whisker.mag: magnitude response of the selected filter
%          whisker.name: {leftWhisker,rightWhisker}
%          (can be used as a measure of confidence, potentially...)
% NOTE: some hand tuned parameters: K= 1, sigma=0.5 of wavelength,
% wavelength of 5 pixels and orientations spanning 80:-80:- degrees
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%% PREREQUISITES
    options = {'init',1,'track',0,'session_pth',[],'vidName','whisker','abs_vid_path',[],'verbose',0,'ROI',[]};
    options = inputparser(varargin,options);
    ROI = [];
    lastsize = 0;

    if ~isempty(options.session_pth)
        fullPath = getFullPath(fileBase,options.session_pth); % path to session
    else
        fullPath = getFullPath(fileBase); % path to session
    end
    
    if isempty(options.abs_vid_path) % assume NPerentos file strcuture
        disp('no video file was specified so going with the default whisker option of top*.avi');
        test = (dir(fullfile(fullPath,'video','top*.avi')));
        if ~size(test,1)
            warning('there is no video file .. aborting');
            return
        elseif size(test,1) == 1
            disp 'found a top* video file; continuing with data processing...'
            fileName = [test.folder,'/',test.name];
            [vid_pth,fle,ext] = fileparts(fileName);
            options.vidName = 'whisker';
        end
    else
        if exist(options.abs_vid_path)
            [vid_pth,fle,ext] = fileparts(options.abs_vid_path);
        else
            error(['there is no such video so aborting',options.abs_vid_path]);
        end
    end
        
    if isempty(options.ROI) % these are Nikolas' default ROIs
        options.ROI.names = {'leftWhisker','rightWhisker'};
        options.ROI.pts = zeros(length(options.ROI.names),4);
    end
    
    % get video object
    obj = VideoReader(fileName);
    nFr = obj.Duration*obj.FrameRate;
    %nFr = 5000; %for testing purposes
    strt = obj.CurrentTime;
    

%% DEFINE ROIS 
    
    try
        load(fullfile(getfullpath(fileBase),[options.vidName,'ROIs.mat']));
    catch
        initialise;
    end

    
%% TRACK
if options.track
    whisker.mag   = zeros(2,nFr);
    whisker.angle = zeros(2,nFr);
    whisker.names = ROI.names;
    j=1;
    wavelength = [5]; orientation = [-80:15:80];%orientation = [30:-15:-55];
    g = gabor(wavelength,orientation);

    if options.verbose
        figure(1)
        set(gcf,'pos',[107   542   970   456]);
        figure(2) 
        set(gcf,'pos',[138 0 2216 456]);    
    end

    fp = rgb2gray(im2double(obj.readFrame));
    tic;

    while hasFrame(obj)    
        fc = rgb2gray(im2double(obj.readFrame));
        A = fc-fp;

        tmp{1} = imcrop(A,ROI.pts(1,:));
        tmp{2} = imcrop(A,ROI.pts(2,:));    
        for roi = 1:2        
            gabormag = imgaborfilt(tmp{roi},g);
            for i = 1:length(g)
                sigma = 0.5*g(i).Wavelength;
                K = 1;
                gabormag(:,:,i) = imgaussfilt(gabormag(:,:,i),K*sigma); 
            end

            % pick gabor with highest magnitude
            for i = 1:size(gabormag,3)
                sm(i) = max(vc(gabormag(:,:,i)));            
            end
            [bestMag,bestI] = max(sm,[],2);
            whisker.mag(roi,j) = bestMag;
            whisker.angle(roi,j) = bestI;            
            if options.verbose 
                figure(1);
                subplot(2,3,3); imshow(real(g(whisker.angle(roi,j)).SpatialKernel),[]);
                subplot(2,3,2); imshow(tmp{roi},[]);
                subplot(2,3,1); imshow(imcrop(fc,ROI.pts(roi,:)),[]);
                subplot(2,3,[4 5]); plot(sm); box off;

                figure(2);
                cx = [0,0];
                ha = tight_subplot(2,length(orientation),0,0,0);
                for i = 1:length(orientation)                 %subplot(i,length(orientation));
                    axes(ha(i));
                    imagesc(gabormag(:,:,i));                
                    cx = [cx;caxis];
                end
                cx = max(cx); set(all_subplots(gcf),'CLim',cx);
                for i = 1:length(orientation)
                    axes(ha(i+length(orientation)));%tight_subplot(2,length(orientation),i); %subplot(i,length(orientation));
                    imagesc(real(g(i).SpatialKernel)); 
                    colormap(gca,'gray');               
                end                        

                drawnow;
            end         
        end
        j = j+1;
        fp=fc;   
        if ~rem(j,1000)
            fprintf(repmat('\b', 1, lastsize));
            lastsize = fprintf('whisker tracking at frame: %d / %d', j, nFr);
            %disp(['whisker tracking frame: ',int2str(j),'/',int2str(nFr)]);
        end
    end

%% SAVE
    disp('saving...');
    save(fullfile(getfullpath(fileBase),[options.vidName,'_whiskerTracking.mat']),'whisker');  
    t3 = toc
    disp(['Finished whisker tracking. Data saved in ', options.vidName,'_Tracking.mat',', elapsed time: ', num2str(t3)]);
    disp('DONE!');    
    
%% PLOT A REPORT
    figure('pos',[ 527 181 3299 1660]);
    clrs = get(gca,'colororder');
    hx = tight_subplot(2,1,0.1, 0.1,0.1);
    axes(hx(1));
        jplot(whisker.angle(1,:),'color',[.5 .5 .5]); hold on;
        jplot( smooth(whisker.angle(1,:),6),'color',clrs(1,:),'linewidth',2);
        jplot(-whisker.angle(2,:),'color',[.5 .5 .5]); 
        jplot(-smooth(whisker.angle(2,:),6),'color',clrs(2,:),'linewidth',2);axis tight;
    dv1 = normalize_array1(whisker.mag(1,:)); 
    dv2 = normalize_array1(whisker.mag(2,:)); 
    axes(hx(2));
        jplot(1./dv1,'color',clrs(1,:)); hold on;
        jplot(-1./dv2,'color',clrs(2,:));
    axis tight;linkaxes(hx,'x');

    print(fullfile(getfullpath(fileBase),['whisker_tracking.jpg']),'-djpeg'); %,'-r300'   
        
end




 %% INITIALISE
    function initialise
        disp 'in initialise';
%         if ~exist(fullfile(getfullpath(fileBase),[options.vidName,'ROIs.mat']),'file')
            
            pos = [302         233        1210         839];
            figure('color','k','position',pos); colormap gray
            vidFrame = readFrame(obj);
            vidFrame = rgb2gray(im2double(vidFrame));             
            
            for r = 1:length(options.ROI.names) 
               disp(['draw square around ''',options.ROI.names{r},'''']);
               imagesc(vidFrame); axis equal;
               title(['draw square around ''',options.ROI.names{r},''''],'color','w','interpreter','none');
               tmp = getrect(gcf);
               tmp = floor(tmp);
               options.ROI.pts(r,:) = tmp;
               clf; imagesc(vidFrame(tmp(2):tmp(2)+tmp(4),tmp(1):tmp(1)+tmp(3),:)); axis equal;pause(0.5);% to verify only
               clear tmp; clf;
            end
            
            ROI = options.ROI;
            save(fullfile(getfullpath(fileBase),[options.vidName,'ROIs.mat']),'ROI');
            disp('subframes succesfuly defined.');
            clear ROI tmp; close;
%         else
%             disp(['ROIs previously initialised will load from ',options.vidName,'ROI.mat']);
%         end
    end    
end % end of main function  

%{ 
figure('pos',[ 527 181 3299 1660]);
clrs = get(gca,'colororder');
hx = tight_subplot(2,1,0.1, 0.1,0.1);
axes(hx(1));
    jplot(whisker.angle(1,:),'color',[.5 .5 .5]); hold on;
    jplot( smooth(whisker.angle(1,:),6),'color',clrs(1,:),'linewidth',2);
    jplot(-whisker.angle(2,:),'color',[.5 .5 .5]); 
    jplot(-smooth(whisker.angle(2,:),6),'color',clrs(2,:),'linewidth',2);axis tight;
dv1 = normalize_array1(whisker.mag(1,:)); 
dv2 = normalize_array1(whisker.mag(2,:)); 
axes(hx(2));
    jplot(1./dv1,'color',clrs(1,:)); hold on;
    jplot(-1./dv2,'color',clrs(2,:));
axis tight;linkaxes(hx,'x');
%}
