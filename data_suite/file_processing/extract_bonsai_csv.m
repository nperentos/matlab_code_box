function info = extract_bonsai_csv(dirname)

%% Behavior
dirname = directory_sanitizer(dirname);
eventsfn = get_lfp_filename(dirname,'events.csv');
csvfn = get_lfp_filename(dirname,'mov.csv');

names = {'Timestamp','CentroidX','CentroidY','Orientation','MajorAxisLength','MinorAxisLength','Area', 'HeadX', 'HeadY', 'TailX', 'TailY','SpeedX', 'SpeedY', 'FrameXOR'};

tmp = dlmread(csvfn,'',1,0);

info.data = array2table(tmp(:,1:end-2),'VariableNames',names);
info.arenaWidth = mean(tmp(:,end-1));
info.arenaHeight = mean(tmp(:,end));

%% Events
try;
    fileID = fopen(eventsfn);
    tmp = textscan(fileID,'%s %f');
    fclose(fileID);
    
    tmp1 = split_string(tmp{1}{1},'T');
    info.date = tmp1{1};
    info.time = tmp1{2};
    
    events = tmp{2};
    
    info.start_time = events(2);
    info.stop_time = events(end);
    
    info.data.Timestamp = (info.data.Timestamp - info.start_time)/1000; % in seconds
catch;
end

%% Mean frame
try;
    videofn = get_lfp_filename(dirname,'cropped.avi');
    info.filename = videofn;
    
    obj = VideoReader(videofn);
    
    out = rgb2gray(obj.read(1));
    frameidx = 1:obj.FrameRate:obj.NumberOfFrames;
    out = zeros(size(out,1),size(out,2),length(frameidx),'uint8');
    
    for c=1:length(frameidx)
        out(:,:,c) = rgb2gray(obj.read(frameidx(c)));
    end
    
    info.background = median(out,3);
catch;
    info.background = [];
end;

%% Basic plots
pos = [info.data.CentroidX info.data.CentroidY];

%% Exploration

fig; 
if ~isempty(info.background);
    imshow(info.background);
    hold on;
end
jplot(pos(:,1),pos(:,2),'k')

fixfig([dirname 'exploration']);

%% Occupancy
fig; 
if ~isempty(info.background);
    imshow(info.background);
    freezeColors
    hold on;
end

[Out, XBins, YBins] = hist2(pos,40,20);
%h = imagesc(XBins, YBins, Out(:,end:-1:1)');
%set(gca, 'ydir', 'normal')
h = imagesc(XBins, YBins, Out');
colormap jet
set(h,'AlphaData',0.5)
fixfig([dirname 'occupancy']);
