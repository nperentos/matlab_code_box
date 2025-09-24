function [] = tMazeTrackRatHelper(fileBase)
% fileBase is the full path to the videos folder
% tMazeTracking helper to get the ROI boxes correct quickly
% guards against movement of the arena which should not happen

%% GET VIDEOS 

clrs = get(gca,'colororder'); close;
if isunix
    cd(fileBase);
    fls = dir('*.avi');
    fls = {fls.name}';
end

for v = 1:length(fls)
    close all;
    figure('pos', [10 10 600 900]);%set(gcf, 'Position', get(0, 'Screensize'));
    % first we check if the ROIs were defined already ~exist(['circularRatTMazeTemplate.mat'])
    if ~exist(['coo_',fls{v}(1:end-3),'mat'])
        fls{v}
        obj = VideoReader(fls{v});
        nrFr = round(obj.Duration*obj.FrameRate);
        bgFr = rgb2gray(im2double(obj.readFrame));
        % load precomputed masks (in the hope that the maze hasnt moved)
        load('/storage2/perentos/code/perentos_data_suite/videoProcessing/ROIs_Rat_Tmaze_Female.mat');
        imshow(bgFr); hold on;
        visboundaries(M_arm ,'color','r');
        visboundaries(C_road,'color','g');
        visboundaries(R_arm ,'color','b');
        visboundaries(L_arm,'color','w');
        visboundaries(R_cage,'color','m');
        visboundaries(L_cage,'color','y');
        % check and redraw ROIs if necessary
        ui = input('do the ROIs look correct?[y/n]:','s');
        if ui == 'n' | ui == 'N'
            xlabel('draw boundary around middle arm - center area gets its own ROI')
        M_arm = roipoly; visboundaries(M_arm,'color','r');
            xlabel('draw boundary around center location')
        C_road = roipoly; visboundaries(C_road,'color','r');
            xlabel('draw boundary around right arm')
        R_arm = roipoly; visboundaries(R_arm,'color','r');
            xlabel('draw boundary around left arm')
        L_arm = roipoly; visboundaries(L_arm,'color','r');
            xlabel('draw boundary around right cage')
        R_cage = roipoly; visboundaries(R_cage,'color','r');
            xlabel('draw boundary around left cage')
        L_cage = roipoly; visboundaries(L_cage,'color','r');
            save(['coo_',fls{v}(1:end-3),'mat'],'M_arm','L_arm','R_arm','C_road','L_cage','R_cage');
        elseif ui == 'y' | ui == 'Y'
            save(['coo_',fls{v}(1:end-3),'mat'],'M_arm','L_arm','R_arm','C_road','L_cage','R_cage');
        end
    else
        display(['ROIs already defined for ', fls{v}]);
    end
end
close;