function h = pupilSummary(fldrName)

if nargin > 1
    error('provide only one input, the folder of interest');
end

try
    fullPath = getFullPath(fldrName);
catch
    error('there is no such folder ... aborting')
end

cd(fullPath);
cd processed;
try
    load pupilResults.mat
catch
    disp('the pupil results file is missing ... please generate first...');
    disp('aborting for now ...');
    return;
end
% pupil size parameters
figure;
h(1)=subplot(411); hold on;
if rem(length(tracked),2); enum = (length(tracked)+1); else enum = length(tracked); end
% check if the detection was done for every second frameand fill in with adjacent values
if enum/length([tracked.Area]) == 2
    x = [tracked.MajorAxisLength;tracked.MajorAxisLength];
    %plot(normalize_array(x(:)),'color',[0.7 0.7 0.7]);
    plot(smooth(normalize_array(x(:))),'rlowess');
    x = [tracked.MinorAxisLength;tracked.MinorAxisLength];
    plot(normalize_array(x(:)),'color',[0.7 0.7 0.7]);
    plot(smooth(normalize_array(x(:))),'rlowess');
    x = [tracked.Area;tracked.Area];
    plot(normalize_array(x(:)),'color',[0.7 0.7 0.7]);        
    plot(smooth(normalize_array(x(:))),'lowess');
else
%     plot(normalize_array([tracked.MajorAxisLength]'),'color',[0.7 0.7 0.7]);
    plot(smooth(normalize_array([tracked.MajorAxisLength]'),'rlowess'));
%     plot(normalize_array([tracked.MinorAxisLength]'),'color',[0.7 0.7 0.7]);
    plot(smooth(normalize_array([tracked.MinorAxisLength]'),'rlowess'));
%     plot(normalize_array([tracked.Area]'),'color',[0.7 0.7 0.7]);
    plot(smooth(normalize_array([tracked.Area]'),'rlowess'));
end

legend('MajorAxis','MinorAxis','Area');
% pupil position parameters
h(2)=subplot(412); hold on;
centroid = [tracked.Centroid];
CentroidX = centroid(1:2:end);
CentroidY = centroid(2:2:end);
if enum/length(CentroidX) == 2
    x = [CentroidX;CentroidX];
    plot(normalize_array(x(:)'));
    x = [CentroidY;CentroidY];
    plot(normalize_array(x(:)'));      
else
    plot(normalize_array(CentroidX'));
    plot(normalize_array(CentroidY'));
end
%plot(centroid(1:2:end));
%plot(centroid(2:2:end));
legend('CentroidX','CentroidY');
% blink measure
h(3)=subplot(413);hold on;
plot(zscore(blI));
plot([xlim],[3 3]); ylim([0 20]);
legend('blinkIndex');
h(4) = subplot(414);
plot(movI);
legend('frameMovement')
linkaxes(h,'x'); axis tight;