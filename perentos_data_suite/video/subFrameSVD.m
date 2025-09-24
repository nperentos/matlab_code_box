function [t1 t2 t3]=subFrameSVD(fileBase,varargin)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% processFaceVideo processes a video from a headfixed recording to produce
% 1. ROI activties computed as absolute diffs of successive frames
% 2. Singular value decompositions of user define ROIs and saving
% the first 10 components of these of these decompositions
% for 6 ROIs and 30fps this script runs at 0.85 of the actual rec. time
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% PREREQUISITES

    options = {'flag',1,'track',0,'session_pth',[],'vidName','face','abs_vid_path',[],'verbose',0,'ROI',[],'ncomp',10};
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
    

%% DEFINE ROIS (IF NEEDED)    
    try
        load(fullfile(getfullpath(fileBase),[options.vidName,'ROIs.mat']));
    catch
        initialise;
    end

%% TRACKING    
if options.track    
    if exist([pr_pth,'face_wholeFrameSVD__Activations.mat'],'file') && exist([pr_pth,'face_wholeFrameSVD_U.mat'],'file')
        warning(sprintf(['whole frame svd has already been performed.\n',...
        'If you want to rerun this analysis, you must delete the output files first']));
        return
    end
% COMPUTE ROI ACTIVITIES FROM FRAME DIFFS
    tic;
    disp('computing frame diff for all requested ROIs'); tic;    
    nROI = length(ROI.names);
    activity = zeros(nFr-1,nROI);
    obj.CurrentTime = strt;
    fr1 = rgb2gray(im2double(obj.readFrame));
        
    for i = 2:nFr
        fr2 = rgb2gray(im2double(obj.readFrame));
        fr = abs(fr2-fr1);
        for j = 1:nROI
            activity(i,j) = sum(sum(abs(fr(ROI.pts(j,2):ROI.pts(j,2)+ROI.pts(j,4)  ,  ROI.pts(j,1):ROI.pts(j,1)+ROI.pts(j,3)))));           
        end 
        if ~rem(i,2000); 
            disp(['processed frame ',num2str(i), ' out of ', num2str(nFr)]); 
        end        
        fr1 = fr2;
    end
        
    save(fullfile(getfullpath(fileBase),[options.vidName,'_ROI_energies.mat']),'activity','ROI');
    t1 = toc;
    disp(['Finished frame diff for all ROIs. Data saved in ', options.vidName,'_ROI_Activities.mat','elapsed time: ', num2str(t1)]);
    
    
% COMPUTE VIDEO SVDs
    tic;
    obj.CurrentTime = strt;
    tmp = rgb2gray(im2single(obj.readFrame));
    
% generate U matrices
    disp('subFrame SVD'); tic;  
    for k = 1:nROI % we skip the first one which is an irregular mask and not so useful cause its the full face
        disp 'computing final matrix for this subframe';
        clear G Gcov U Uf Ui S V;
        obj.CurrentTime = strt;
        % decomposition
        segLen = 500;
        tmp = rgb2gray(im2single(obj.readFrame));
        % get the number of pixels to preassign size for G
        tmp = imcrop(tmp,ROI.pts(k,:));
        tmp = tmp(1:2:end,1:2:end);
        tmp = tmp(:);
        G = zeros(segLen,length(tmp));        
        nseg = round(nFr/segLen);%nseg = 100; % if there arent enough frames in the last segment, code fails. By using round we ensure that the last segment will have at least nseg/2 frames to work with thus being able to produce at last 10 PCs
        
        npixel = numel(tmp);
        Uf = zeros(npixel,options.ncomp,nseg);        
        for j = 1:nseg
            fprintf(repmat('\b', 1, lastsize));
            lastsize = fprintf('   subFrameSVD: %d / %d', j, nseg);
            for i = 1:segLen
                if hasFrame(obj)
                    tmp = rgb2gray(im2single(obj.readFrame));
                    % keep only the subframe
                    tmp = imcrop(tmp,ROI.pts(k,:));%tmp = tmp(px{k});
                    tmp = tmp(1:2:end,1:2:end);
                    G(i,:) = tmp(:);
                else
                    %display('hmmmmm');
                    G(i:end,:) = [];
                    break;                        
                end
            end
            G = diff(G,1);
            Gcov = G*G';
            [U,S,V] = svd(Gcov,'econ'); 
            Ui = G'*V(:,1:min([options.ncomp size(V,2)])); % note that V and U are the same b/c Gcov is symmetric
            % lets fill in with zeros temporarily to test Ufin size
            %Ui = G'*V(:,1:min([options.ncomp size(V,2)])); % note that V and U are the same b/c Gcov is symmetric
            %Ui = [Ui zeros(size(Ui,1),options.ncomp-size(Ui,2))];
            Uf(:,:,j) = Ui;                
        end            
        fprintf( 'computing final matrix for this subframe');
        [Ufin{k},S,V] = svd(reshape(Uf, npixel, []),'econ'); 
        fprintf('... DONE\n');
        
    end     
    
    U = Ufin; clear Ufin S V G Ui Uf;
    disp(['saving the SVD matrix in ',options.vidName,'vidSVD_U.mat ...']);
    save(fullfile(getfullpath(fileBase),[options.vidName,'_SVD_ROI_U.mat']),'U');
    % when matlab saves a matrix its file size depends not only on the size
    % but also on the entries. zeros ones and 1,5s take progressively more
    % space! So it looks like bits or bytes are spared !
    % note that the final U is actually not square but can be square if the
    % number of pixels is as many as the number of segments times the
    % number of components kept. So it can be square if the number of
    % pixels is less than segmentsXcomponents but not square if not
    t2 = toc;
    disp(['Finished frame diff for all ROIs. Data saved in ', options.vidName,'_SVD_ROI_U.mat','elapsed time: ', num2str(t2)]);
    
    
% generate activation matrices
    disp 'generating activation matrices';
    tic;%warning('off');    
    W = zeros(options.ncomp,nFr-1,nROI);
    obj.CurrentTime = strt;
    fr1 = rgb2gray(im2single(obj.readFrame));
    for i = 1:nFr-1
        fr2 = rgb2gray(im2single(obj.readFrame));
        fr = abs(fr2-fr1);
        for j = 1:nROI
            df = imcrop(fr,ROI.pts(j,:));
            df = df(1:2:end,1:2:end);
            df = df(:);            
            for k = 1:options.ncomp
                W(k,i,j) = df'*U{j}(:,k); % frames x components x ROI
            end
            fr1 = fr2;
        end 
    end
    
    disp('saving the SVD ROI Activations.mat ...');
    activity = W;
    activity =cat(2,zeros(size(activity(:,1,:))),activity);
    save(fullfile(getfullpath(fileBase),[options.vidName,'_SVD_ROI_Activations.mat']),'activity','-v7.3');  
    t3 = toc;
    disp(['Finished frame diff for all ROIs. Data saved in ', options.vidName,'_SVD_ROI_U.mat','elapsed time: ', num2str(t3)]);
    disp('DONE!');
    
    
    
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
%             disp(['ROIs previously initialised will load from ',options.vidName,'ROIs.mat']);
%         end
    end    
end % end of main function  

%  tmp = zscore(activity); % pays off to have cases on the first dimension which is row (features on second)
%  tmp = tmp+repmat([0:5],length(tmp),1);

 
 
% componenets projected back to frame space
%     i=0;
%     figure('color','w','position',[312   173   960   456]);
%     for j = 1:options.ncomp
%         for k =1:size(ROI.pts,1)
%             i = i+1;
%             subplot(options.ncomp,size(ROI.pts,1),i)
%             imagesc(reshape(U{k}(:,j), 1+floor(ROI.pts(k,4)/2), []));
%             caxis([0 0.051]);
%         end
%     end



% % load U and activity and try to plot or reconstruct activities....
% load face_SVD_ROI_U.mat
% U2=U{2};
% A2 = activity(:,:,2);
% 
% figure; plot(A2(1,:))
% 
% test = U2(:,1:10)*A2;
% 
% 
% 
% %check that we are reading the frames
% figure;
% 
% for i = 1:100
%     fr = obj.readFrame;
%     fr = obj.readFrame;
%     fr = obj.readFrame;
%     imshow(fr);
%     drawnow;
% end

% BELOW WORKS FINE BUT WILL TRY TO PUT THE ROIS INSIDE THE INNERMOST LOOP
% generate U matrices
%     for k = 1:nROI % we skip the first one which is an irregular mask and not so useful cause its the full face
%         clear G Gcov U S V;
%         % decomposition
%         segLen = 500;
%         tmp = rgb2gray(im2single(obj.readFrame));
%         % get the number of pixels to preassign size for G
%         tmp = imcrop(tmp,ROI.pts(k,:));
%         tmp = tmp(1:2:end,1:2:end);
%         tmp = tmp(:);
%         G = zeros(segLen,length(tmp));
%         obj.CurrentTime = strt;
%         nseg = ceil(nFr/segLen);%nseg = 100;
%         
%         npixel = numel(tmp);
%         Uf = zeros(npixel,options.ncomp,nseg);        
%         for j = 1:nseg
%             disp(['processing segment ', int2str(j),' out of ',num2str(nseg)]);
%             for i = 1:segLen
%                 if hasFrame(obj)
%                     tmp = rgb2gray(im2single(obj.readFrame));
%                     % keep only the subframe
%                     tmp = imcrop(tmp,ROI.pts(k,:));%tmp = tmp(px{k});
%                     tmp = tmp(1:2:end,1:2:end);
%                     G(i,:) = tmp(:);
%                 else
%                     G(i:end,:) = [];
%                     break;                        
%                 end
%             end
%             G = diff(G,1);
%             Gcov = G*G';
%             [U,S,V] = svd(Gcov,'econ'); 
%             Ui = G'*V(:,1:options.ncomp); % note that V and U are the same b/c Gcov is symmetric
%             Uf(:,:,j) = Ui;                
%         end            
%         disp 'computing final matrix for this subframe';
%         [Ufin{k},S,V] = svd(reshape(Uf, npixel, []),'econ');            
%         obj.CurrentTime = strt;
%     end     
%     
%     U = Ufin; clear Ufin S V G Ui Uf;
%     disp(['saving the SVD matrix in ',options.vidName,'vidSVD_U.mat ...']);
%     save(fullfile(getfullpath(fileBase),[options.vidName,'_SVD_ROI_U.mat']),'U','-v7.3');
%     save(fullfile(getfullpath(fileBase),[options.vidName,'_SVD_ROI_Unotv73.mat']),'U');
%     t2 = toc;
%     disp(['Finished frame diff for all ROIs. Data saved in ', options.vidName,'_SVD_ROI_U.mat','elapsed time: ', num2str(t2)]);
%     