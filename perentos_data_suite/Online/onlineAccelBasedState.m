% script to read accelerometer channels and compute mean threshold
pth2folder = '/storage2/perentos/data/recordings/NP28/NP28_2019-07-09_18-31-05';
global act keyPressed keyIs; act = 0; keyPressed = 0; keyIs = 0;
SR = 30e3;
interval = 15*SR;
dsr = 120; % downsampling ration
% define the 3 files to read
fls = dir([pth2folder,'/*AUX*.continuous']);
for i = 1 :3
    filename{i} = fullfile( fls(i).folder, fls(i).name); 
end

ofsIn = 0;loC = 1; highC = 15; Xv = [0]; Yv = [0]; Zv = [0]; first = 1;

while keepLooking
    % read in and keep last x seconds
    tic
% X

    [X, ~, ~, ofsOut]  = readContinuousUpTo(filename{1}, ofsIn);  
    
    idx = length(X)-interval:length(X)-1000;% indices of last 5 minutes
    X = double(X(idx));
    Xv = [Xv, std(X)]
    %     X = resample(double(X),1,dsr);
    %     X = ButFilter(X,2,[loC ]./SR/dsr/2,'low');
    %     X = abs(hilbert(X))';
    
% Y ( the assumption here is that Y and Z being read after X will have more data  in them)

    [Y, ~, ~]          = readContinuousUpTo(filename{2}, ofsIn);
    
    Y = double(Y(idx));
    Yv = [Yv, std(Y)]
    %     Y = resample(double(Y),1,dsr);
    %     Y = ButFilter(Y,2,[loC ]./SR/dsr/2,'low');
    %     Y = abs(hilbert(Y))';
    
% Z ( the assumption here is that Y and Z being read after X will have more data  in them)

    [Z, ~, ~]          = readContinuousUpTo(filename{3}, ofsIn);
    
    Z = double(Z(idx)); % trim 
    Zv = [Zv, std(Z)]; 
    %     Z = resample(double(Z),1,dsr);
    %     Z = ButFilter(Z,2,[loC ]./SR/dsr/2,'low');
    %     Z = abs(hilbert(Z))';
    subplot(2,3,[1 2 3]); cla; 
    plot([X-mean(X) Y-mean(Y) Z-mean(Z)]);
    subplot(2,3,[4]); cla;plot([Xv]);
    subplot(2,3,[5]); cla;plot([Yv]);
    subplot(2,3,[6]); cla;plot([Zv]);

    if length(Xv) > 5
        if mean(Xv(end-5:end),Yv(end-5:end),Zv(end-5:end))>1000
            set(gca,'color','g')
            mtit('quiescence')
        else
            set(gca,'color','r')
            mtit('likely awake')
        end
    end
    
    toc
    ofsIn = ofsOut;
    
    
end
    
    
    
    
    
%% keypressdetect
function KeyPressedFcn(hObject, keyEvent)
global keyPressed keyIs
if keyEvent.Character == 'q';
    disp('q was pressed')
    keepLooking = 0;
elseif keyEvent.Character == 'r';
    keyPressed  = 1;
end
disp('key is pressed')
end
    