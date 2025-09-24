% this script quantifies the distribution of pupil area values for first
% block, second block and first trial of second block so as to compare the
% statistics of the distributions. The hypothesis is that the first time
% the animal experiences the manipulation (in the first trial of the second
% block) the statistics should show increase in pupil area. 
% Further in order to elimnate the possibility that the pupil tracking
% suffers from the extreme pupil size expected at exposure, we generate a
% short video with labels and  tracking superimposesd that displays the
% second last trial of block 1 followed by the first trial of block 2
doVideo = 1;


%% first we use sessions of Natalia
    i_Sessions =  [ 6 7 12 16 17 38 41 44 ...
        46 47 51 70 87 99 101  129 ...
        132 134 137 139 147 155 ];
    T = getCarouselDataBase;  
    myDB = T.session(i_Sessions);
    % removed 132 from Natalias lot

%%
fileID = fopen('/storage2/perentos/data/recordings/reportpup.txt','a');
close all;
for i = 4%:length(myDB) %
    fprintf('\n**************************\n');
    fprintf(['currently processing: ',int2str(i),'/',int2str(length(myDB))])
    fprintf('\n**************************\n')
    fileBase = myDB{i};
    goto(fileBase);

    
%% extract indices for a) first trial of second block and b) whole second block
    [session, behavior]=loadSession(fileBase);
    posI = find(strcmp('posDiscr',behavior.name));
    pos = behavior.data.data(:,posI);
    trials = session.helper.idxTrials;
    %figure; subplot(211);plot(trials); subplot(212);plot(pos);
    %linkaxes(get(gcf,'children'),'x')
    tr1 = session.info.trialsPerBlock(1)+1;
    ts_tr1 = find(session.helper.idxTrials == tr1);
    % end of block 2 (exclude the last break period
    tr_last = sum(session.info.trialsPerBlock(1:2));% the last trial but maybe contains the last break
    idx = find(session.helper.idxTrials == tr_last);
    posTmp = pos(idx);    
    [a,b]=max(posTmp);
    EndB2 = idx(b);
       
    
%% video frame of interest   
    vidTimes = find(session.helper.vidPulses); % indices of video frames
    
    % BASELINE - LAST TRIAL
    tmp = session.info.trialsPerBlock(1); % the last trial of block one but it contains the break period in it too. Trim it out
    idx = find(session.helper.idxTrials == tmp); % indices of relevant trial timeponts    
    posTmp = pos(idx);    
    [a,b]=max(posTmp);
    EndB1 = idx(b);
    Bl1_start = find(session.helper.idxTrials == 1, 1, 'first');
    bsl_frames = [find(vidTimes >= idx(1),1,'first'):find(vidTimes <= EndB1,1,'last')];    
    %display(['last trial of block 1: ~',int2str(length(bsl_frames)),' secs']);
    
    % MANIPULATION - FIRST TRIAL
    tmp = session.info.trialsPerBlock(1) + 1;
    if strcmp('NP53_2020-06-11_14-09-15',fileBase)
        tmp = session.info.trialsPerBlock(1) + 3;
    end
    idx = find(session.helper.idxTrials == tmp);    
    fem_frames = [find(vidTimes >= idx(1),1,'first'):find(vidTimes <= idx(end),1,'last')];    
    %display(['first trial of block 2: ~',int2str(length(fem_frames)),' secs']);        
    
    figure('visible','off'); % validate correct definition of data blocks
    pts = [Bl1_start EndB1 ts_tr1(1) ts_tr1(end) EndB2];
    plot(pos);hold on; plot(pts,pos(pts),'r*');
    print(fullfile(getfullpath(fileBase),'tmpPoints'),'-djpeg','-r300');
    
%% generate video segment and annotate it    
    if doVideo
        displayFramesSideBySide(fileBase,{bsl_frames,fem_frames});
        delete('pupil_last_bsl_vs_first_manipulation.avi');
        !ffmpeg   -i vid1.avi   -i vid2.avi   -filter_complex '[0:v]pad=iw*2:ih[int];[int][1:v]overlay=W/2:0[vid]'   -map '[vid]'   -c:v libx264   -crf 23   -preset veryfast   pupil_last_bsl_vs_first_manipulation.avi
        delete(['vid1.avi'],['vid2.avi']);
    end
    
    
%%  histograms of all baseline trials, 1st manipulation trial and all manipulation trials
% AS IS USES THE UPSAMPLED DATA WHICH INFLATES THE SAMPLE SIZE BY A FACTOR
% OF 30. CAN AVOID THIS BY USING ONLY THE VIDTIMES DATA 
    tmp = find(strcmp(behavior.name,'pupil_area'));
    pup = behavior.data.data(:,tmp);
    % in some cases we have to use DLC pupil data (if session.info.useDLCPupil exist and is 1)
    if isfield(session.info,'useDLCPupil') & session.info.useDLCPupil % in case DLC pupil was flagged
        tmp = find(strcmp(behavior.name,'pupilDLC_area'));
        pup = behavior.data.data(:,tmp);
    end
    % plot the distribution of pupil areas
    figure('visible','off','pos',[251 176 775 628]);
    BinEdges = [0:10:1000];
        
    % use video frame idxs only (no upsampling = truer stats)
    bl1_all   = vidTimes(vidTimes >= pts(1) &  vidTimes <= pts(2));
    bl1_last  = [];
    bl2_all   = vidTimes(vidTimes >= pts(3) &  vidTimes <= pts(5));
    bl2_first = vidTimes(vidTimes >= pts(3) &  vidTimes <= pts(4));        
    
    subplot(311);H1 = histogram(pup(bl1_all),'binedges',BinEdges,'normalization','probability','facecolor',[.5 .5 .5]); 
    title('all baseline trials');    
    axis tight; yl = ylim;
    medn = median(pup(bl1_all));
    hold on; plot([medn,medn],[yl],'b','linewidth',2);
    ylim([yl]);
    
    subplot(312);H2 = histogram(pup(bl2_first),'binedges',H1.BinEdges,'normalization','probability','facecolor',[.5 .5 .5]); 
    title(['first manipulation trial - ', [session.info.conditions{2}]]);
    axis tight; yl = ylim;
    hold on; plot([medn,medn],[yl],'b','linewidth',2); 
    plot([median(pup(bl2_first)),median(pup(bl2_first))],[yl],'r','linewidth',2);
    ylim([yl]);
    
    subplot(313);H2 = histogram(pup(bl2_all),'binedges',H1.BinEdges,'normalization','probability','facecolor',[.5 .5 .5]); 
    title(['all manipulation trials - ', [session.info.conditions{2}]]);
    axis tight; yl = ylim;
    hold on; plot([medn,medn],[yl],'b','linewidth',2); 
    plot([median(pup(bl2_all)),median(pup(bl2_all))],[yl],'r','linewidth',2);
    
    ylim([yl]);
    stampFig(fileBase);
    ForAllSubplots('xlim([0 1000])');
    axes('pos',[0 0 1 1]);text(0.65,0.98,'pupil size distributions','fontsize',12);axis off;
    ForAllLabels(gcf,'FontWeight','normal','fontsize',12);        
    print(fullfile(getfullpath(fileBase),'pupil_distributions'),'-djpeg','-r300');

    %% stat comparison
%     [Ho1,P1,CI1,STATS1] = ranksum(pup(1:ts_tr1(1)),pup(ts_tr1)) % all before vs 1st manipulation trial with control/female/novel object
     %[Ho2,P2,CI2,STATS2] = ttest2(pup(Bl1_start:EndB1),pup(ts_tr1(1):EndB2));    % all before vs all after manipulation
%      [Ho2,P2,CI2,STATS2] = ttest2(pup(Bl1_start:EndB1),pup(ts_tr1));    % all before vs all after manipulation
     [Ho2,P2,CI2,STATS2] = ttest2(pup(bl1_all),pup(bl2_all));    % all before vs all after manipulation
%     [Ho3,P3,CI3,STATS3] = ranksum(pup,pup(ts_tr1(1):End))    % all vs first trial after manipulation
    
%     [P1,Ho1,STATS1] = ranksum(pup(1:ts_tr1(1)),pup(ts_tr1)) % all before vs 1st manipulation trial with control/female/novel object
%     [P2,Ho2,STATS2] = ranksum(pup(1:ts_tr1(1)),pup(ts_tr1(1):End));    % all before vs all after manipulation
%     [P3,Ho3,STATS3] = ranksum(pup,pup(ts_tr1(1):End))    % all vs first trial after manipulation    
%     [P4,Ho4,STATS4] = ranksum(pup,pup(ts_tr1)) 
    
    nm = session.info.conditions(2);
    fprintf(fileID,'%s %s %f %f \n',fileBase, session.info.conditions(2),P2,mean(CI2));       
        
end
fclose(fileID);
    
% %%  histograms of all baseline trials, 1st manipulation trial and all manipulation trials
% % AS IS USES THE UPSAMPLED DATA WHICH INFLATES THE SAMPLE SIZE BY A FACTOR
% % OF 30. CAN AVOID THIS BY USING ONLY THE VIDTIMES DATA 
%     tmp = find(strcmp(behavior.name,'pupil_area'));
%     pup = behavior.data.data(:,tmp);
%     % in some cases we have to use 
%     
%     % plot the distribution of pupil areas
%     figure('visible','off','pos',[251 176 775 628]);
%     BinEdges = [0:10:1000];
%     
%     subplot(311);H1 = histogram(pup(Bl1_start:EndB1),'binedges',BinEdges,'normalization','probability','facecolor',[.5 .5 .5]); 
%     title('all baseline trials');    
%     axis tight; yl = ylim;
%     hold on; plot([median(pup),median(pup)],[yl],'b','linewidth',2);
%     ylim([yl]);
%     
%     subplot(312);H2 = histogram(pup(ts_tr1),'binedges',H1.BinEdges,'normalization','probability','facecolor',[.5 .5 .5]); 
%     title(['first manipulation trial - ', [session.info.conditions{2}]]);
%     axis tight; yl = ylim;
%     hold on; plot([median(pup),median(pup)],[yl],'b','linewidth',2); 
%     plot([median(pup(ts_tr1)),median(pup(ts_tr1))],[yl],'r','linewidth',2);
%     ylim([yl]);
%     
%     subplot(313);H2 = histogram(pup(ts_tr1(1):EndB2),'binedges',H1.BinEdges,'normalization','probability','facecolor',[.5 .5 .5]); 
%     title(['all manipulation trials - ', [session.info.conditions{2}]]);
%     axis tight; yl = ylim;
%     hold on; plot([median(pup),median(pup)],[yl],'b','linewidth',2); 
%     plot([median(pup(ts_tr1(1):EndB2)),median(pup(ts_tr1(1):EndB2))],[yl],'r','linewidth',2);
%     
%     ylim([yl]);
%     stampFig(fileBase);
%     ForAllSubplots('xlim([0 1000])');
%     axes('pos',[0 0 1 1]);text(0.65,0.98,'pupil size distributions','fontsize',12);axis off;
%     ForAllLabels(gcf,'FontWeight','normal','fontsize',12);        
%     print(fullfile(getfullpath(fileBase),'pupil_distributions'),'-djpeg','-r300');
% 
%     %% stat comparison
% %     [Ho1,P1,CI1,STATS1] = ranksum(pup(1:ts_tr1(1)),pup(ts_tr1)) % all before vs 1st manipulation trial with control/female/novel object
%      %[Ho2,P2,CI2,STATS2] = ttest2(pup(Bl1_start:EndB1),pup(ts_tr1(1):EndB2));    % all before vs all after manipulation
%      [Ho2,P2,CI2,STATS2] = ttest2(pup(Bl1_start:EndB1),pup(ts_tr1));    % all before vs all after manipulation
% %     [Ho3,P3,CI3,STATS3] = ranksum(pup,pup(ts_tr1(1):End))    % all vs first trial after manipulation
%     
% %     [P1,Ho1,STATS1] = ranksum(pup(1:ts_tr1(1)),pup(ts_tr1)) % all before vs 1st manipulation trial with control/female/novel object
% %     [P2,Ho2,STATS2] = ranksum(pup(1:ts_tr1(1)),pup(ts_tr1(1):End));    % all before vs all after manipulation
% %     [P3,Ho3,STATS3] = ranksum(pup,pup(ts_tr1(1):End))    % all vs first trial after manipulation    
% %     [P4,Ho4,STATS4] = ranksum(pup,pup(ts_tr1)) 
%     
%     nm = session.info.conditions(2);
%     fprintf(fileID,'%s %s %f %f \n',fileBase, session.info.conditions(2),P2,mean(CI2));       
%         
% end
% fclose(fileID);