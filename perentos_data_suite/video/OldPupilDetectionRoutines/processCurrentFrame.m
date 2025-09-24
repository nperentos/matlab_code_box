function  res = processCurrentFrame(vidFrame,pupilInit)
    MSGID = 'images:imfindcircles:warnForLargeRadiusRange';
    warning('off', MSGID);
    MSGID = 'images:imfindcircles:warnForSmallRadius';
    warning('off', MSGID);
    r_hat = 2;
    r_r = -1:1;
    r_z = bsxfun(@plus,r_r'.^2, r_r.^2);
    r_z = r_z/sum(r_z(:));
    I = vidFrame(:,:,1);
    Icr = I(pupilInit.rct(2):pupilInit.rct(2)+pupilInit.rct(4),pupilInit.rct(1):pupilInit.rct(1)+pupilInit.rct(3),:);
    framesize = size(Icr);
    x = nan(framesize(1),framesize(2));
% smooth the subframe
    x(:,:) = conv2(double(Icr(:,:)),r_z,'same');
% normalise subframe
    G_data = x;
    G_data = G_data(5:(end-5),5:(end-5));
    frCx = size(G_data,1)/2;
    frCy = size(G_data,2)/2;    
    ctr = @(x)(x-min(x(:))/(max(x(:))-min(x(:))));
% do a percentile thresholding to avoid hard threshold
    nclu = 6;%
    tmp_data = G_data;
    tmpscale = prctile(tmp_data(:),[pupilInit.thr, 25]);
    G_data = rescale(tmp_data,tmpscale);
    tmp_data1 = G_data(:,:);
    % cluster pixels using kmeans
    [u,C,ntmp_data] = smoothKNNgray(tmp_data1,nclu);%,u_init(:,nclu)
    tmp_u = reshape(u==1,size(ntmp_data));
    % detect ROIs
    [centers,radii,metric] = imfindcircles(tmp_u,[5 40],'ObjectPolarity','bright','sensitivity',0.75);
    N = length(radii);
    trackSuccess = 0;
    if N>1
        trackSuccess = 1;
        for i = 1:N
            cntr(i) = (centers(i,1) - frCx)^2 + (centers(i,2) - frCy)^2;
        end
        % compute product of circleness and centerdness
        [~,idx] = min(cntr);
        clear cntr rAxes;
    elseif N == 1
        idx = 1;
        trackSuccess = 1;
    end
    if ~trackSuccess 
        %disp 'no ROI detected';
        res(1) = nan;
        res(2) = nan;
        res(3) = nan;      
        res(4) = nan; 
    end
    % store the data
    if trackSuccess
        res(1) = radii(idx);
        res(2) = centers(idx,1);
        res(3) = centers(idx,2);      
        res(4) = metric(idx); 
    end

