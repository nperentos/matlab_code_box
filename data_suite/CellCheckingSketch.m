
% load('ms.mat')

%% check firing: 
%  Plots traces together with the reconstructed firing rate

vidObj = ms;

Traces2Show = [65 66 68 48];   % Change here the cell you want to look at
numTraces2Show = length(Traces2Show);

figure; 
for i = 1:numTraces2Show
ha(i) = subplot(numTraces2Show,1,i);
plot(vidObj.trace(:,Traces2Show(i)));
hold on
plot(vidObj.firing(:,Traces2Show(i)));
end
linkaxes(ha)
%% Cell contours:
%  Plots contours of detected ROIs on the mean frame

vidObj = ms;

Traces2Show = [65 66 68 48];   % Change here the cell you want to look at

figure; 

red = cat(3, ones(vidObj.alignedHeight(vidObj.selectedAlignment),vidObj.alignedWidth(vidObj.selectedAlignment)), ...
    zeros(vidObj.alignedHeight(vidObj.selectedAlignment),vidObj.alignedWidth(vidObj.selectedAlignment)), ...
    zeros(vidObj.alignedHeight(vidObj.selectedAlignment),vidObj.alignedWidth(vidObj.selectedAlignment)));


for i = Traces2Show;
imagesc(vidObj.meanFrame{1});
colormap(gray)
hold on
% overlay outline of segmentations
h = imshow(red);
set(h, 'AlphaData', vidObj.segementOutline);
end


%% Outline and traces for selected cells 
% Shows outline of selected ROIs on the average frame, together with the
% calcium traces. Useful for checking cross talk (i.e. if two cells have
% very similar activity, one can quickly see if they are close/overlapping)
% also shows dF/F baseline (top right corner), as a sanity check

vidObj = ms;

figure;


Traces2Show = [22 24 30 31 65 66 68 48 52 81 83 84 88 90 92];  % Change here the cells you want to look at
numTraces2Show = length(Traces2Show);


% cell map
subplot(ceil((numTraces2Show+6)/3), 3, [1, 2, 4, 5]);


hold on
red = cat(3, ones(ms.alignedHeight(ms.selectedAlignment),ms.alignedWidth(ms.selectedAlignment)), ...
    zeros(ms.alignedHeight(ms.selectedAlignment),ms.alignedWidth(ms.selectedAlignment)), ...
    zeros(ms.alignedHeight(ms.selectedAlignment),ms.alignedWidth(ms.selectedAlignment)));

imagesc(ms.meanFrame{1})

h = imshow(red);
set(h, 'AlphaData', ms.segementOutline);

for i = 1:numTraces2Show
    text(ms.segCentroid(Traces2Show(i),1), ms.segCentroid(Traces2Show(i),2), num2str(Traces2Show(i)));
end
title('Cells overlayed on meanFrame')

ha(3) = subplot(ceil((numTraces2Show+6)/3), 3, 3);
plot(ms.dFFBaseline);
title('dF/F Baseline');


% traces
for iShow = 1:numTraces2Show
    ha(iShow+6) = subplot(ceil((numTraces2Show+6)/3), 3, iShow+6);
    hold on;
    plot(ms.trace(:,Traces2Show(iShow)))
%     plot(ms.firing(:,Traces2Show(iShow)))
    title(['cell #' num2str(Traces2Show(iShow))])
end

linkaxes(ha)
axis([0 size(ms.originalTrace,1) min(min(ms.originalTrace)) max(max(ms.originalTrace)) ]);
