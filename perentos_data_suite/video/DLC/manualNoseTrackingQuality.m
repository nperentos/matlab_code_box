%% visualise nose tracking for all sessions
function noseTrackingIssue = manualNoseTrackingQuality
%T = readtable('/storage2/perentos/data/recordings/animals_and_recording_session_particulars.xlsx','Sheet','AnalysisVars');
T = getCarouselDataBase;
close all;
global yes no u; 
load('/storage2/perentos/data/recordings/noseTrackingIssue.mat')
for i = length(noseTrackingIssue)+1:height(T)
    display(['processing ',num2str(i), ' out of ', num2str(height(T)), '. fileBase is: ', T.Session{i}])
    out = plotNoseTracking(T.Session{i});
    yes = 0; no = 0; u = 0;
    % get user input
    figure();
    set(gcf, 'KeyPressFcn', @KeyPressedFcn);
    text(.5,.5,'did you observe any out of place markers? (y/n/u):','HorizontalAlignment','Center','FontSize',20);axis off;
    if isnan(out)
        hold on;
        text(.5,.7,'no video so file was skiped. Please press u','HorizontalAlignment','Center','FontSize',20,'Color','r');axis off;
    end
    keepLooking = 1;
    while keepLooking
        if yes
            noseTrackingIssue(i) = 1;
            keepLooking = 0;
        elseif no 
            noseTrackingIssue(i) = 0;
            keepLooking = 0;
        elseif u 
            noseTrackingIssue(i) = nan;
            keepLooking = 0;
        end        
        pause(0.2);
    end
    close;
    noseTrackingIssue
    save(fullfile('/storage2/perentos/data/recordings',['noseTrackingIssue.mat']),'noseTrackingIssue')
end

end

%% keypressdetect
function KeyPressedFcn(hObject, keyEvent)
    global yes no u
    if keyEvent.Character == 'y'
        disp('marked video as potentially problematic')
        yes = 1;
    elseif keyEvent.Character == 'n'
        disp('video OK continuing...')
        no  = 1;
    elseif keyEvent.Character == 'u'
        disp('video OK continuing...')
        u  = 1;        
    end
end