function  res = processCurrentFrameMorpho(vidFrame,pupilInit)
thrU = 10;    
MSGID = 'images:imfindcircles:warnForLargeRadiusRange';
    warning('off', MSGID);
    MSGID = 'images:imfindcircles:warnForSmallRadius';
    warning('off', MSGID);
    r_z = [         0.166666666666667        0.0833333333333333         0.166666666666667
                    0.0833333333333333                         0        0.0833333333333333
                    0.166666666666667        0.0833333333333333         0.166666666666667];
    I = vidFrame(:,:,1);
    Icr = I(pupilInit.rct(2):pupilInit.rct(2)+pupilInit.rct(4),pupilInit.rct(1):pupilInit.rct(1)+pupilInit.rct(3),:);
    framesize = size(Icr);
    x = nan(framesize(1),framesize(2));
% smooth the subframe
    x(:,:) = conv2(double(Icr(:,:)),r_z,'same');
% normalise subframe
    G_data = x(5:(end-5),5:(end-5));
    frCx = size(G_data,1)/2;
    frCy = size(G_data,2)/2;    
% percentile thresholding
    %tmp_data = G_data;
    %tmpscale = prctile(tmp_data(:),[pupilInit.thr, thrU]);
    tmpscale = prctile(G_data(:),pupilInit.thr);
    %G_data = rescale(tmp_data,tmpscale);
% morphometric operations     
    %Gb=G_data./max(max(G_data)); % normalise to 1
    Gb = imbinarize(G_data,tmpscale(2));         % binarise
    bw = ~bwareaopen(~Gb,20);    % remove small regions (work on inverted image)
    %se = strel('disk',6);        % fill in small diskoid gaps (light reflection)
    %bw = imclose(~bw,se);
% find closed region boundaries    
    trackSuccess = 0;
    [B,L] = bwboundaries(~bw,'noholes');
    if length(B)>0
        trackSuccess = 1;
    else
        res(1) = nan;
        res(2) = nan;
        res(3) = nan;      
        res(4) = nan; 
    end
if trackSuccess    
    %     imshow(label2rgb(L, @jet, [.5 .5 .5])); hold on;    
    for k = 1:length(B)
        boundary = B{k};
        %plot(boundary(:,2), boundary(:,1), 'k', 'LineWidth', 2)
    end
    % extract properties of identified regions    
    stats = regionprops(L,'Area','Centroid','MajorAxisLength','MinorAxisLength');% ,'Solidity'
    diameters = mean([[stats.MajorAxisLength]; [stats(:).MinorAxisLength]]',2);
    radii = diameters/2;
    for k = 1:length(B)            
        centers(k,:) = [stats(k).Centroid(1),stats(k).Centroid(2)];           
        boundary = B{k}; % obtain (X,Y) boundary coordinates corresponding to label 'k'       
        delta_sq = diff(boundary).^2; % estimate perimeter
        perimeter = sum(sqrt(sum(delta_sq,2)));
        area = stats(k).Area;        
        metric(k) = 4*pi*area/perimeter^2; % roundness metric
    end
    % lets sort all regions according to the product of the metric(circleness)
    % and inverse of distance from the center of the image
    prd = (1./sqrt( (frCx-centers(:,2)).^2 + (frCy-centers(:,1)).^2 )).*metric';
    [Y,I] = sort(prd,1,'descend');
    idx = I(1); % index of the selected region
    % collect the results into res
    res(1) = radii(idx);
    res(2) = centers(idx,1);
    res(3) = centers(idx,2);     
    res(4) = prd(idx);
end

% verbose = 0;
% if verbose
%     figure;
%     subplot(1,3,1); hold on;
%     imagesc(x(5:(end-5),5:(end-5))); hold aon;viscircles([res(2),res(3)],res(1),'LineStyle','--'); plot(res(2),res(3),'xr')axis equal; axis off;
%     subplot(1,3,2);
%     imagesc(G_data);hold on;viscircles([res(2),res(3)],res(1),'LineStyle','--'); plot(res(2),res(3),'xr')axis equal; axis off;
%     subplot(1,3,3);
%     imshow(bw); hold on;viscircles([res(2),res(3)],res(1),'LineStyle','--'); plot(res(2),res(3),'xr')
%     colormap gray;
% end



















