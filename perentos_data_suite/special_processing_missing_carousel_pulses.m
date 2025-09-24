% for this session fileBase = 'NP39_2019-11-21_11-44-59', the carousel
% pulses are missing but the ttl pulses are present. Therefore we are
% missing the carousel speed and position variables. We reconstruct these
% by using the fact that trajectories for passive task are stereotypic and
% most likely identical between this session and its previous one. If this
% is true the the mean of all traectories (separated by direction of
% travel) should give a good approximation of the actual individual
% trajectories for the present session. However we observe that the
% trajectories vary in lenth within a range of 300ms or so. We therefore
% turn to the top video and from it we extract the periods of carousel
% movement through frameDiff for an ROI that contains exclusively carousel
% pixels. From this we define start and stop points for each trajectory and
% then in there we insert the relevant mean speed profiles. First we scale
% the magnitude of the speed profiles according to the duration of the
% trajectory so that the integral (distance traveled) is equal across trials. 


% there is a case (and maybe others ?) in which some auxiliary channels
% were not present, probably due to some arduino malfunction or because of
% some wiring being physicaly unpluged by accident. These sessions could be
% salvaged depending on what type of task was running and which of the
% variables went missing. 
% an example is below where at least the carousel pulses were not recorded
% but thankfully the TTL events are present. Since this was a passive task,
% I can use the events to demarkate the carousel movement periods and to be
% more accurate I can extract speed profiles from a close by in date
% passive task recordings and use the average speed profiles (one of reach
% direction) as the speed for each trial in this session. A correction
% factor from the start and stop position can also be built in because the
% carousel keeps spinning for a few more 10s of ms after the TTL due to
% intertia while at the same time, there might be a small delay in 10s of
% ms in starting to turn. 
% First lets create flags in the carousel database spreadsheet that
% indicate which variables are missing. We leave these columns unpopulated
% for efficiency and populate with zeros where a variable is missing.
% Havent done this yet... 
fileBase = 'NP39_2019-11-21_11-44-59';
first = 0;
if first
    % generate average speed profile for each direction with percent markers
    % for start stop position
    preFileBase = 'NP39_2019-09-04_13-25-48';
    %loadSession(preFileBase);% wont work since by def, the pipe didnt finish
    cd(getfullpath(preFileBase));
    load session.mat;
    load behavior_interim.mat;
    nTr = session.info.nTrials;

    %%
    % 1
    figure; subplot(211); jplot(behavior.data(20,:)); % carousel speed
    ylim([-1 20]);
    hold on; 
    Lines(session.events.TTL.atACW,ylim,'r'); % add the events
    Lines(session.events.TTL.atCW,ylim,'b'); % add the events
    Lines(session.events.TTL.atStart,ylim,'k'); % add the events
    % 2
    subplot(212); 
    jplot(session.helper.idxMov);
    hold on; jplot(session.helper.idxTrials./nTr);
    ylim([-0.5 1.5]);
    linkaxes(get(gcf,'children'),'x');
    %%
    % events are generally stored at lfp rate (except events.all which is at
    % dat rate)
    % actually lets use the idxTrial variable to extract the trials and further
    % trim those to just select the movent periods?
    ev = round(session.events.TTL.all(:,1)./30);
    mv = session.helper.idxMov;

    for i = 1:length(ev)
        bnd(i,1) = find(diff(mv(1:ev(i))) ~= 0,1,'last');
        bnd(i,2) = find(diff(mv(ev(i):end)) ~= 0,1,'first') + ev(i);
        trj{i} = behavior.data(20,bnd(i,1):bnd(i,2));
        trj_resampled(i,:) = resample(trj{i},1000,length(trj{i}));
        trjLen(i) = length(trj{i});
    end
    % the plot below thus shows the general trajectory so we could average
    % these and get a mean speed profile for each trial and fill it in
    figure; 
    clrs = [1 0 0; 0 0 0; 0 0 1];
    for i = 1:length(session.events.TTL.all)
        subplot(3,1,session.events.TTL.all(i,2));
        plot(trj{i},'color',clrs(session.events.TTL.all(i,2),:));
        hold on;
        x(i) = length(trj{i}) - (bnd(i,2)-ev(i)); % this is the anchor point within the trajectory onto the TTL event
        plot([x(i) x(i)],ylim,'color',clrs(session.events.TTL.all(i,2),:));
    end
    % plot resampled trajectories
    figure;
    subplot(3,1,1);
    plot(trj_resampled(find(session.events.TTL.all(:,2) == 1),:)','color',clrs(1,:));
    hold on; plot(mean(trj_resampled(find(session.events.TTL.all(:,2) == 1),:))+0,'color',[.5 .5 .5],'linewidth',3);
    subplot(3,1,2);
    plot(trj_resampled(find(session.events.TTL.all(:,2) == 2),:)','color',clrs(2,:));
    hold on; plot(mean(trj_resampled(find(session.events.TTL.all(:,2) == 2),:))+0,'color',[.5 .5 .5],'linewidth',3);
    subplot(3,1,3);
    plot(trj_resampled(find(session.events.TTL.all(:,2) == 3),:)','color',clrs(3,:));
    hold on; plot(mean(trj_resampled(find(session.events.TTL.all(:,2) == 3),:))+0,'color',[.5 .5 .5],'linewidth',3);

    mean_trajectories= [mean(trj_resampled(find(session.events.TTL.all(:,2) == 1),:));...
                        mean(trj_resampled(find(session.events.TTL.all(:,2) == 2),:));...
                        mean(trj_resampled(find(session.events.TTL.all(:,2) == 3),:))];


    Ls = cellfun(@length,trj, 'UniformOutput', true);
    toLHS_Len = mean(Ls(find(session.events.TTL.all(:,2) == 1)));   toLHS_anchor   = mean(x(find(session.events.TTL.all(:,2) == 1)));
    toRHS_Len = mean(Ls(find(session.events.TTL.all(:,2) == 3)));   toRHS_anchor   = mean(x(find(session.events.TTL.all(:,2) == 3)));
    toStart_Len = mean(Ls(find(session.events.TTL.all(:,2) == 2))); toStart_anchor = mean(x(find(session.events.TTL.all(:,2) == 2)));

    anchors_resampled = (x'./trjLen').*1000; % these anchors are not relevant for the actual dat file to be corrected...

    % at this point we have the positions onto which to inject the guessed
    % speed trajectories for each event as well as the speed trajectories which
    % will need to be resampled again according to the mean trajectory
    % durations
    % vars to use:
    % anchors_resampled; mean_trajectories; toLHS_Len; toRHS_Len; toStart_Len

    % a more accurate way might be to stretch these trajectories according to
    % some start stop times that can be extracted by the video...






    % 
    fileBase = 'NP39_2019-11-21_11-44-59';

    cd(getFullPath(fileBase)); cd video;
    obj = VideoReader('top_cam_0_date_2019_11_21_time_11_44_51_v001.avi');

    fr1 = obj.readFrame;
    fr1 = im2double(fr1(:,:,1));
    figure; imagesc(fr1);
    % choose a carousel section that includes its edge since I believe
    % where there are no pysical stimuli, there is little framediff...
    %sF = getrect;
    % lets just hardcode the one that worked - would need to change for
    % other sessions
    sF = [415.553191489362          181.225806451613          260.425531914894 265.645161290323];
    fr1 = fr1(sF(2):sF(2)+sF(4) , sF(1):sF(1)+sF(3));

    % now lets perform the framDiffs

    i = 2; % 
    while hasFrame(obj)
        fr2 = obj.readFrame;
        fr2 = im2double(fr2(:,:,1));
        fr2 = fr2(sF(2):sF(2)+sF(4) , sF(1):sF(1)+sF(3));    
        frDiff(i) = sum(sum(abs(fr1-fr2)));
        fr1 = fr2; i = i + 1;
    end
    
    thr = 400;
    % thr = mode(frDiffSm)*1.5; % didnt work very well switch to hard thr
    figure; jplot(frDiff);
    hold on; jplot(smooth(frDiff,10)); 
    jplot(xlim,[thr thr]); 
    frDiffSm = smooth(frDiff,10);
    
    
    % find movment periods
    mv = (frDiffSm > thr);
    mv = mean([circshift(mv,-1),mv,circshift(mv,-1)],2); % jtter by one - might help
    mv(mv>=2/3) = 1; mv(mv<=2/3) = 0;
    
    
    
    
    % lets now save the workspace
    cd(getfullpath(fileBase));
    save('carouselSpeedPositionManualCorrection_Workspace.mat');
else
    cd(getfullpath(fileBase));
    load('carouselSpeedPositionManualCorrection_Workspace.mat');
end


% we now have chunks of periods were there is movement but some of them
% suffer from disjoint movements at the end (prob. rebound after motor is
% locked or something similar
% Procedure for deducing start and stop times:
% for each event (signifying the vicinity of the end of the trajectory we
% expand left and right wards by 5 - 10 samples untill all new samples = 0


load session.mat;
load behavior_interim.mat;

%% get extents
ev = session.events.TTL.all;
ev(:,1) = round(ev(:,1)./30);% events at lfp rate
% we need to use the mv variable but first must bring it to lfp rate (its
% at video rate). Therefore we need the pulse times
vp = find(session.helper.vidPulses); % this is at lfp rate
Vq = interp1(vp,double([0; mv; 0]),[1:length(behavior.data)],'nearest');
stp = 100; % 100 works well...
for i = 1:size(ev,1) % for each event, get extents
    evi = ev(i,1);
    % search on either side 
    tmp = 1; from = evi; % start of this trajectory
    while tmp
        from = from - stp;
        tmp = sum(Vq(from:from + stp));
    end
    bounds(i,1) = from+stp;
    tmp = 1; to = evi; % end of this trajectory
    while tmp
        to = to + stp;
        tmp = sum(Vq(to-stp:to));
    end
    bounds(i,2) = to-stp;
end
%% visual confirmation that this worked
close all;
figure('pos',[56          54        1983         399]); 
%jplot(Vq,'k');
plot(Vq/max(Vq)*0.9,'g');
ylim([-1 2]);hold on; 
Lines(bounds(:,1),ylim,'r','-',1);
Lines(bounds(:,2),ylim,'m','-',1);
Lines(ev(:,1),ylim,'b','-',1);

%xlim([1032096   1042463]);
%xlim([1900060.41478191          2060505.33626998]);
% lets check them one by one to be sure
% for i = 1:length(ev)
%     xlim([ev(i)-10e3,ev(i)+10e3]);
%     pause;%waitforbuttonpress
% end

%% we now have the periods to fill in
% now lets fill in the templates but we need to scale them by the ratio of
% the average duration to the current duration.
    fsc(1) = toLHS_Len;
    fsc(2) = toRHS_Len;   
    fsc(3) = toStart_Len; 
    
    anchors(1) = toLHS_anchor;
    anchors(2) = toRHS_anchor;
    anchors(3) = toStart_anchor;


% the final waveforms to inject
for i = 1:length(ev)
    wv = mean_trajectories(ev(i,2),:);
    wv = wv.*((bounds(i,2)-bounds(i,1))/fsc(ev(i,2)));
    wvs{i} = wv;
end
   

% % manually modify anchors as it doesnt seem to match. But why?
% anchors = anchors + [900 900 0];
% % they need to be injected at the ev positions but scaled according to
% % length
% carouselSpeed = zeros(1, size(behavior.data,2));
% for i = 1:length(ev) 
%     % how much of the template goes before and how much after the trigger
%     ratio = anchors(ev(i,2))/fsc(ev(i,2));
%     L = bounds(i,2)-bounds(i,1); % the actual length of this trial
%     L1 = round(L*ratio);
%     L2 = L - L1;
%     % now we need to interpolate the wv template to match current trial L
%     inj = interp1(linspace(0,1,length(wvs{i})),wvs{i},linspace(0,1,L));
%     % where to inject
%     ps = ev(i,1) - L1;
%     carouselSpeed(ps:ps+L-1) = inj;
% end


% in fact we do not need the anchors it appears since we can use the start
% of the verified movement as we obtain it from the video. This can be our
% anchor so need to split into before and after the TTL...
carouselSpeed = zeros(1, size(behavior.data,2));
carouselPosition = zeros(1, size(behavior.data,2));
for i = 1:length(ev) 
    L = bounds(i,2)-bounds(i,1); % the actual length of this trial
    % now we need to interpolate the wv template to match current trial L
    inj = interp1(linspace(0,1,length(wvs{i})),wvs{i},linspace(0,1,L));
    carouselSpeed(bounds(i,1):bounds(i,2)-1) = inj;
    
    % position
    tmp = cumsum( (inj/sum(inj)) .* 120);
    % correct it for direction of travel
    if ev(i,2) == 1; disp('as is'); end
    if ev(i,2) == 2 && ev(i-1,2) == 1; tmp = abs(tmp-120); end 
    if ev(i,2) == 2 && ev(i-1,2) == 3; tmp = -abs(tmp-120); end 
    if ev(i,2) == 3; tmp = -tmp; end
    % but still we need to fill in the inbetweens where animal is
    % stationary at 120 or -120
    carouselPosition(bounds(i,1):bounds(i,2)-1) = tmp;
    if i ~= length(ev)
        carouselPosition(bounds(i,2):bounds(i+1,1)-1) = tmp(end);
    end
end
figure; plot([carouselPosition;carouselSpeed]');





%% visual confirmation that it worked
close all;
figure('pos',[56          54        2283         399]);  hold on;
plot(Vq,'color',[.7 .7 .7]);

plot(carouselSpeed,'color',[.1 .1 .1]);
plot(carouselPosition,'color',[.5 .5 0]);
%ylim([-1 2]);
Lines(bounds(:,1),ylim,'r','-',1);
Lines(bounds(:,2),ylim,'m','-',1);
Lines(ev(:,1),ylim,'b','-',1);
%xlim([1032096   1042463]);
%xlim([1900060.41478191          2060505.33626998]);
% lets check them one by one to be sure
% for i = 1:length(ev)
%     xlim([ev(i)-10e3,ev(i)+10e3]);
%     pause;%waitforbuttonpress
% end
 

%% up to now we have succesfully estimated the carousel speed and position
% now lets update the behavior and session variables accordingly
behavior.data(find(strcmp(behavior.name,'carouselSpeed')),:) = carouselSpeed;
behavior.data(find(strcmp(behavior.name,'position')),:) = carouselPosition;
% still must fix 
Vq(isnan(Vq)) = 0;
session.helper.idxMov = Vq;
% and finally

% session.helper.positionBinCenters
bnsz = 1;
posEdges = [-360:bnsz:360];
posDiscr = discretize(carouselPosition, posEdges);
binCenters = posEdges-(bnsz/2)*sign(posEdges);
helper.positionBinCenters = binCenters;

% session.helper.position_context
% get transitions of carousel since position is not enough - we need to
% know the context as well i.e. inbound vs outbound
position = carouselPosition;
ipt = findchangepts(position([1:10:end]),'Statistic','linear','MaxNumChanges',length(session.events.TTL.all)*2);    
ipt = ipt*10;
% from this lets extract the slop for each segment
tmp_ipt = [1 ipt length(position)];
for i = 1:length(tmp_ipt)-1
    seg = position(tmp_ipt(i):tmp_ipt(i+1));
    slp(i) = (seg(end)-seg(1))/length(seg);
    mu(i) = mean(seg);
end
% original values that I needed to modify - some scaling issue?
% % % negative mean and negative slope is approach to right
% % % toR = find(slp<-0.2 & mu<-200);clr(toR) = 1; 
% % % % negative mean and positive slope is return to origin from right
% % % fromR = find(slp>0.2 & mu<-200);clr(fromR) = 2;
% % % % positive mean and positive slope is approach to left
% % % toL = find(slp>0.2 & mu>200);clr(toL) = 3;
% % % % positive mean and negative slope is return to orogin from left
% % % fromL = find(slp<-0.2 & mu>200);clr(fromL) = 4;
% % % % 0 mean and 0 slope is wait at origin
% % % atO = find(slp<0.1 & slp>-0.1 & mu>-200 & mu<200);clr(atO) = 5;
% % % % negative mean and 0 slope is waiting at right
% % % atR = find(slp<0.1 & slp>-0.1 & mu < -1000);clr(atR) = 6;
% % % % positive mean and 0 slope is waiting at left
% % % atL = find(slp<0.1 & slp>-0.1 & mu > 1000);clr(atL) = 7;
% % % toR = find(slp<-0.2 & mu<-200);clr(toR) = 1; 
% modified
% negative mean and positive slope is return to origin from right
toR = find(slp<-0.01 & mu<-50);clr(toR) = 1; 
% negative mean and positive slope is return to origin from right
fromR = find(slp>0.02 & mu<-50);clr(fromR) = 2;
% positive mean and positive slope is approach to left
toL = find(slp>0.02 & mu>50);clr(toL) = 3;
% positive mean and negative slope is return to orogin from left
fromL = find(slp<-0.02 & mu>50);clr(fromL) = 4;
% 0 mean and 0 slope is wait at origin
atO = find(slp<0.01 & slp>-0.01 & mu>-50 & mu<50);clr(atO) = 5;
% negative mean and 0 slope is waiting at right
atR = find(slp<0.01 & slp>-0.01 & mu < -100);clr(atR) = 6;
% positive mean and 0 slope is waiting at left
atL = find(slp<0.01 & slp>-0.01 & mu > 100);clr(atL) = 7;

% just to confirm that we captured all of them
%sort([toR fromR toL fromL atO atL atR])
% turn position into radians
position = position.*(deg2rad(120)/max(abs(position)));
figure('pos',[100 100 1700 1400]); 
subplot(211); jplot(position); axis tight;
subplot(212);
gscatter(mu,slp,clr);
title('contextual chunks');
xlabel('mean position (-ve right, +ive left)');
ylabel('slope(-ve right, +ive left)');
legend('toR', 'fromR', 'toL', 'fromL', 'atO', 'atL', 'atR');
% PRINT
print(fullfile(getfullpath(fileBase),'position_report'),'-djpeg','-r300');
position_context.segs = [tmp_ipt(1:end-1);tmp_ipt(2:end)]';
position_context.context = clr;
position_context.labels = ['1:toR', '2:fromR', '3:toL', '4:fromL', '5:atO', '6:atL', '7:atR'];

session.helper.position_context = position_context;

%% SAVE
processedPath = getfullpath(fileBase);
save(fullfile(processedPath,'session.mat'),'session','-v7.3');
save(fullfile(processedPath,'behavior_interim.mat'),'behavior','-v7.3');
