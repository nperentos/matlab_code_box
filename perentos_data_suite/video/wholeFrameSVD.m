function [t2 t3] = wholeFrameSVD(fileBase,varargin)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% wholeFrameSVD(fileBase,varargin) processes a video from a headfixed
% recording to produce
% 1. ROI activities computed as absolute diffs of successive frames
% 2. Singular value decompositions of user define ROIs and saving
% the first 10 components of these decompositions
% for 6 ROIs and 30fps this script runs at 0.85 of the actual rec. time
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% PREREQUISITES

    options = {'flag',1,'session_pth',[],'vidName','face','abs_vid_path',[],'verbose',0,'ROI',[],'ncomp',40};
    options = inputparser(varargin,options);
    ROI = [];
    lastsize = 0;
    
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
    pr_pth = fullfile(getfullpath(fileBase))    
    if exist([pr_pth,'face_whole_FrameSVD_Activations.mat']) && exist([pr_pth,'face_wholeFrame_SVD_U.mat'])
        warning(sprintf(['whole frame svd has already been performed.\n',...
            'If you want to rerun this analysis, you must delete the output files first']));
        return
    end
    options.ROI.names = {'whole'};
    obj = VideoReader(fileName);
    options.ROI.pts = [1 1 obj.Width obj.Height];
    ROI.pts = options.ROI.pts;
    
    % get video object
    obj = VideoReader(fileName);
    nFr = obj.Duration*obj.FrameRate;
    %nFr = 5000; %for testing purposes
    strt = obj.CurrentTime;
    nROI = 1;
    
% COMPUTE VIDEO SVDs
    tic;
    
% generate U matrices
    for k = 1:nROI % we skip the first one which is an irregular mask and not so useful cause its the full face
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
        nseg = floor(nFr/segLen);%nseg = 100;
        
        npixel = numel(tmp);
        Uf = zeros(npixel,options.ncomp,nseg);        
        for j = 1:nseg
            fprintf(repmat('\b', 1, lastsize));
            lastsize = fprintf('wholeFrame_SVD: %d / %d', j, nseg);
            for i = 1:segLen
                tmp = rgb2gray(im2single(obj.readFrame));
                % keep only the subframe
                tmp = imcrop(tmp,ROI.pts(k,:));%tmp = tmp(px{k});
                tmp = tmp(1:2:end,1:2:end);
                G(i,:) = tmp(:);
% turns out that its fine to skip the last few frames since their actual
% components will be computed later anyway and its unlikely that a small
% nmber of frames is going to give any new information
                %                 if hasFrame(obj)
%                     tmp = rgb2gray(im2single(obj.readFrame));
%                     % keep only the subframe
%                     tmp = imcrop(tmp,ROI.pts(k,:));%tmp = tmp(px{k});
%                     tmp = tmp(1:2:end,1:2:end);
%                     G(i,:) = tmp(:);
%                 else
%                     display('hmmmmm');
%                     G(i:end,:) = [];
%                     break;                        
%                 end
            end
            G = diff(G,1);
            Gcov = G*G';
            [U,S,V] = svd(Gcov,'econ'); 
            Ui = G'*V(:,1:options.ncomp); % note that V and U are the same b/c Gcov is symmetric
            Uf(:,:,j) = Ui;                
        end            
        disp 'computing final matrix';
        [Ufin{k},S,V] = svd(reshape(Uf, npixel, []),'econ'); 
        
    end     
    
    U = Ufin; clear Ufin S V G Ui Uf;
    disp(['saving the SVD matrix in ',options.vidName,'wholeFrame_SVD_U.mat ...']);
    save(fullfile(getfullpath(fileBase),[options.vidName,'_wholeFrame_SVD_U.mat']),'U','-v7.3');
    % when matlab saves a matrix its file size depends not only on the size
    % but also on the entries. zeros ones and 1,5s take progressively more
    % space! So it looks like bits or bytes are spared !
    % note that the final U is actually not square but can be square if the
    % number of pixels is as many as the number of segments times the
    % number of components kept. So it can be square if the number of
    % pixels is less than segmentsXcomponents but not square if not
    t2 = toc;
    disp(['Finished whole SVD. Data saved in ', options.vidName,'_wholeFrame_SVD_U.mat',', elapsed time: ', num2str(t2)]);
    
    
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
    save(fullfile(getfullpath(fileBase),[options.vidName,'_wholeFrame_SVD_Activations.mat']),'activity','-v7.3');  
    t3 = toc;
    disp(['Finished whole frame component activations computation. Data saved in ', options.vidName,'_wholeFrameSVD_ROI_Activations.mat',', elapsed time: ', num2str(t3)]);
    disp('DONE!');              
   
end % end of main function  