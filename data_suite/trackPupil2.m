
function [pupilData] = getTrackingProperties(fileName, thr)
%% 
if nargin <2
    thr = 0.1;
end
close
tic;
MSGID = 'images:imfindcircles:warnForLargeRadiusRange';
warning('off', MSGID)
keepLooking = 1; frame = 1; verbose = 1; 
try
    [video, audio] = mmread(fileName,[frame]);
catch
    error('exceeded the maximum number of frames available')
end     
I = video.frames(1).cdata;
figure('Position',[-1024 391 990 937]);
subplot(331); imagesc(I); title('original');
fprintf(2,'\nPlease draw rectangle over pupil (compulsory)') 
fprintf(2,'\nMust start from top left\n') 
rct = getrect(gcf);
disp 'Thanks, the coordinates are:'
rct = floor(rct);
rct
la_imagen = I(rct(2):rct(2)+rct(4),...
    rct(1):rct(1)+rct(3),:);
subplot(332); imagesc(la_imagen); title('cropped');

filas=size(la_imagen,1);
columnas=size(la_imagen,2);
centro_fila=round(filas/2);
centro_columna=round(columnas/2);
if size(la_imagen,3)==3
la_imagen=rgb2gray(la_imagen);
end    
subplot(333); imagesc(la_imagen); colormap('gray'); title('grayscale');
disp 'Decting pupil, standby for confirmation...'
  
%%
while keepLooking
    
    piel=~im2bw(la_imagen,thr); % piel=~im2bw(la_imagen,0.19);
    subplot(334); cla; imagesc(piel); title(['thr=',num2str(thr)])
    piel=bwmorph(piel,'close');
    subplot(335); cla; imagesc(piel);
    %     piel=bwmorph(piel,'open');
    %     subplot(336); imagesc(piel);
    piel=bwareaopen(piel,200);
    subplot(337); cla; imagesc(piel);
    piel=imfill(piel,'holes');
    subplot(338); cla; imagesc(piel);  
    
    % Tagged objects in BW image
    L=bwlabel(piel);
    % Get areas and tracking rectangle
    out_a=regionprops(L,'Area','Centroid','BoundingBox','MajorAxisLength','MinorAxisLength');
    % Count the number of objects
    N=size(out_a,1);
    if N < 1 || isempty(out_a) % Returns if no object in the image
        solo_cara=[ ];
        disp 'no areas of interest were discovered -- channging threshold...'
        thr = thr + .1;
        continue
    elseif N>1
        rAxes=[out_a.MajorAxisLength]./[out_a.MinorAxisLength];
        % select most circular ROI as the most likely candidate for pupil
        [~, idx] = sort(rAxes);
    else
        idx = 1;
    end
    
    
    % draw bounding box on the B&W image
    subplot(339); cla; imagesc(la_imagen); hold on;
    rectangle('Position',out_a(idx(1)).BoundingBox,'EdgeColor',[1 0 0])
    centro=round(out_a(idx(1)).Centroid);
    X=centro(1);
    Y=centro(2);
    plot(X,Y,'g+');
    
    
    disp 'Putative pupil has been marked';
    prompt = 'Does it look correct? Y/N [Y]: ';
    str = input(prompt,'s');
    
    while isempty(str)
        disp 'must enter 'y' or 'n'. Try again'
        str = input(prompt,'s');
    end
    if str == 'y'        
        pupilData.rct=rct;
        pupilData.thr = thr;
        keepLooking = 0;
        disp 'a threshold and a search area of interest has been defined'
        disp 'ready to track the pupil..'
    elseif str =='n'
        thr = thr + .1;
    end    
end