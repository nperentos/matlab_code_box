% batch process all OE files that relate to the Video only behavioral
% recordings.

%% load paths
fid = fopen('/storage2/perentos/code/BehaviourOnly/behaviouralVideoList.txt');
colororder = get(gca,'colororder');
tline = fgetl(fid);
i=1; ii = [];
while ischar(tline)
    f{i}=(tline)
    tline = fgetl(fid);
    i = i + 1
end
fAll = f;
for i = 1:length(f)
    if strcmp(f{i},'waterVsNothing'); ii = [i ii]; end
    if strcmp(f{i},'aversiveVsAppetitive'); ii = [i ii]; end
    if strcmp(f{i},'femaleVsNothing'); ii = [i ii]; end
end
f(ii) = [];
fclose(fid);

%% stuff that should only run once
ifDo = 0;

if ifDo
% covert OE data
    for  i = 3:length(f)
        convertData(f{i});
    end

% extract data of interest (mainly peripherals)
    for  i = 1:length(f)
        %fldr = 'NP3_2018-04-11_19-37-06';
        processedPath = getfullpath(f{i}); % folder to keep processed data figs etc
        % check if peripherals structure was already generated
        if ~exist([processedPath,'peripherals.mat'],'file') == 2
            disp '>loading preprocessed peripherals<';
            load([processedPath,'peripherals.mat']);
        else
            display(['>generating peripheral channels< ',int2str(i)]);
            % get all channels into workspace
            [data,settings,tScale] = getLFP(f{i});
            [chanTypes] = getChanTypes(settings);
            chPeriph = find(chanTypes == 2);

            if numel(chPeriph) == 4
                runCh = chPeriph(1); lickCh = chPeriph(2); carouselCh = chPeriph(3); rewardCh = chPeriph(4); 
            elseif numel(chPeriph) == 5
                runCh = chPeriph(1); lickCh = chPeriph(2); carouselCh = chPeriph(3); rewardCh = chPeriph(4); vidPulsesCh = chPeriph(5);
            else
                error('I was expecting 4 or 5 ADC channels - aborting');
            end

            % need 30kHz to detect all the pulses from encoders
            [data30k,settings30k,tScale30k] = getDAT(f{i},chPeriph);

            events          = getRewards(data30k(4,:),1);         % REWARD TIMEPOINTS - reward channel = 38
            runSpeed        = getRunSpeed(data30k(1,:));        % RUNNING SPEED
            carouselSpeed   = getCarouselSpeed(data30k(3,:));   % CAROUSEL SPEED 
            %location        = getLocation(data30k(3,:),rewards);% CAROUSEL LOCATION
            licks           = getLicks(data(lickCh,:));         % LICKING AS A FUNCTION OF LOCATION 

            % scan carousel speed for rotation periods
            idxRot = carouselSpeed > 4;
            % get also the start points of the rotation (the tp for which we do
            % not have a pulse sequence from OE NOTE this should be included in
            % future versions of carousel stuff
            iTmp1 = [carouselSpeed(1:end-1) > 4];
            iTmp2 = [carouselSpeed(2:end) > 4];
            iTmp = iTmp2-iTmp1; iTmp = find(iTmp == 1);
            events.toTarget = iTmp; clear iTmp iTmp1 iTmp2;

            if numel(chPeriph) == 5
                vidPulses       = getVidTimes(data30k(5,:));        % A PULSE FOR EACH ACQUIRED VIDEO FRAME   
                save([processedPath,'peripherals.mat'],'data','events','runSpeed','carouselSpeed','licks','vidPulses','tScale');
            else
                save([processedPath,'peripherals.mat'],'data','events','runSpeed','carouselSpeed','licks','tScale');
            end
            clearvars -except f i
        end
    end
end

%% Plots for first experiment
mouse = {'NP18','NP19','NP20','NP21','NP22'};
for x = 1:5
    cd([getFullPath(f{x}),'processed/']);
    load peripherals.mat
    clrs = colororder;
    % LICKING
        %close all;
        figure('position',[100   100   400   400]); 
        %figure('position',[842   -41   960   820]);
        subplot(4,1,[1 2 3])
    % around clockwise target
        val = 3000;
        for  i = 1:length(events.atCW)
            licksPreCW(i,:) = licks(events.atCW(i)-val:events.atCW(i));
        end
        A = shadedErrorBar([-val:1:0],mean(licksPreCW),std(licksPreCW)./sqrt(size(licksPreCW,1)),{'color',clrs(1,:),'linestyle','--'})
        hold on;
        for  i = 1:length(events.atACW)
            licksPreACW(i,:) = licks(events.atACW(i)-val:events.atACW(i));
        end
        B = shadedErrorBar([-val:1:0],mean(licksPreACW),std(licksPreACW)./sqrt(size(licksPreACW,1)),{'color',clrs(2,:),'linestyle','--'})

    % around anticlockwise target
        for  i = 1:length(events.atCW)
            licksPstCW(i,:) = licks(events.atCW(i):events.atCW(i)+val);
        end
        shadedErrorBar([0:1:val],mean(licksPstCW),std(licksPreCW)./sqrt(size(licksPstCW,1)),{'color',clrs(1,:)})
        hold on;
        for  i = 1:length(events.atACW)
            licksPstACW(i,:) = licks(events.atACW(i):events.atACW(i)+val);
        end
        shadedErrorBar([0:1:val],mean(licksPstACW),std(licksPstACW)./sqrt(size(licksPstACW,1)),{'color',clrs(2,:)})


    % add bits and bobs
    box off;
    text(val/2,750,'at target','fontsize',16,'horizontalalignment','center');
    text(-val/2,750,'approaching target','fontsize',16,'horizontalalignment','center');

    plot([-val -100],[680 680],'--k','linewidth',2);
    plot([100 val],[680 680],'--k','linewidth',2);
    ylim([0 800]);
    plot([0 0],[ylim],'k','linewidth',6);

    plot([-val+100 -val+300],[500 500],'color',clrs(1,:),'linewidth',8);
    text(-val+400,500,'neutral side','fontsize',16);
    plot([-val+100 -val+300],[550 550],'color',clrs(2,:),'linewidth',8);
    text(-val+400,550,'rewarded side','fontsize',16);
    set(gca,'tickdir','out');
    % around start position
    subplot(4,1,4);
    for  i = 1:length(events.atStart)
        licksAtStart(i,:) = licks(events.atStart(i)-val:events.atStart(i)+val);
    end
    A = shadedErrorBar([-val:1:val],mean(licksAtStart),std(licksAtStart)./sqrt(size(licksAtStart,1)),{'color',clrs(3,:),'linestyle','--'})
    hold on;

    plot([val-1300 val-1100],[300 300],'color',clrs(3,:),'linewidth',8);
    text(val-1000,300,'center (no reward)','fontsize',16);
    box off;
    plot([0 0],[ylim],'k','linewidth',6);
    xlabel('time (ms)','fontsize',16)
    set(gca,'tickdir','out');

    axes('position',[0 0 1 1]); text(0.5,0.95,['mouse ',mouse{x},': licking'],'horizontalalignment','center','fontsize',16); axis off;



    % RUNNING
        %close all;
        figure('position',[100   100   400   400]); 
        subplot(4,1,[1 2 3])
    % around clockwise target
        val = 3000;
        for  i = 1:length(events.atCW)
            speedPreCW(i,:) = runSpeed(events.atCW(i)-val:events.atCW(i));
        end
        A = shadedErrorBar([-val:1:0],mean(speedPreCW),std(speedPreCW)./sqrt(size(speedPreCW,1)),{'color',clrs(1,:),'linestyle','--'},.5)
        hold on;
        for  i = 1:length(events.atACW)
            speedPreACW(i,:) = runSpeed(events.atACW(i)-val:events.atACW(i));
        end
        B = shadedErrorBar([-val:1:0],mean(speedPreACW),std(speedPreACW)./sqrt(size(speedPreACW,1)),{'color',clrs(2,:),'linestyle','--'},.5)

    % around anticlockwise target
        for  i = 1:length(events.atCW)
            speedPstCW(i,:) = runSpeed(events.atCW(i):events.atCW(i)+val);
        end
        shadedErrorBar([0:1:val],mean(speedPstCW),std(speedPreCW)./sqrt(size(speedPstCW,1)),{'color',clrs(1,:)},1)
        hold on;
        for  i = 1:length(events.atACW)
            speedPstACW(i,:) = runSpeed(events.atACW(i):events.atACW(i)+val);
        end
        shadedErrorBar([0:1:val],mean(speedPstACW),std(speedPstACW)./sqrt(size(speedPstACW,1)),{'color',clrs(2,:)},1)


    % add bits and bobs
    box off;
    yps = ylim;
    ylim([yps(1) yps(2)*1.2]);
    text(val/2,yps(2)*1.1,'at target','fontsize',16,'horizontalalignment','center');
    text(-val/2,yps(2)*1.1,'approaching target','fontsize',16,'horizontalalignment','center');

    plot([-val -100],[yps(2) yps(2)],'--k','linewidth',2);
    plot([100 val],[yps(2) yps(2)],'--k','linewidth',2);
    plot([0 0],[ylim],'k','linewidth',6);

    plot([-val+100 -val+300],[yps(2)*.85 yps(2)*.85],'color',clrs(1,:),'linewidth',8);
    text(-val+400,yps(2)*.85,'neutral side','fontsize',16);
    plot([-val+100 -val+300],[yps(2)*.9 yps(2)*.9],'color',clrs(2,:),'linewidth',8);
    text(-val+400,yps(2)*.9,'rewarded side','fontsize',16);
    set(gca,'tickdir','out');
    % around start position
    subplot(4,1,4);
    for  i = 1:length(events.atStart)
        speedAtStart(i,:) = runSpeed(events.atStart(i)-val:events.atStart(i)+val);
    end
    A = shadedErrorBar([-val:1:val],mean(speedAtStart),std(speedAtStart)./sqrt(size(speedAtStart,1)),{'color',clrs(3,:),'linestyle','--'})
    hold on;
    yps = ylim;
    plot([val-1300 val-1100],[yps(2)*.9 yps(2)*.9],'color',clrs(3,:),'linewidth',8);
    text(val-1000,yps(2)*.9,'center (no reward)','fontsize',16);
    box off;
    plot([0 0],[ylim],'k','linewidth',6);
    xlabel('time (ms)','fontsize',16)
    set(gca,'tickdir','out');

    axes('position',[0 0 1 1]); text(0.5,0.95,['mouse ',mouse{x},': run speed'],'horizontalalignment','center','fontsize',16); axis off;
end

%%
% figure; hold on; plot(carouselSpeed);
% 
% plot(events.atStart,ones(size(events.atStart)),'xb','MarkerSize',8);
% plot(events.toTarget,1.1.*ones(size(events.toTarget)),'sr','MarkerSize',8);
% plot(events.atCW,1.2.*ones(size(events.atCW)),'ok','MarkerSize',8);
% plot(events.atACW,1.3.*ones(size(events.atACW)),'dg','MarkerSize',8);
% legend('CarouselSpeed','atStart','toTarget','atCW','atACW');





