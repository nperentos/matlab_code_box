% data
% to analyse data
% first we log in to the server.  ssh -Y perentos@gamma3
% Thne we access matlab     /storage/share/bin/R2016b/bin/matlab
% navigate inside matlab to the folder you want to analyse

% first you need to convert the data from open ephys format to dat and lfp
% formats. You do this using the convertData function
% e.g. convertData(fle,mapToday');
% mapToday is the mapping of the cdatahannels in the order you want them to
% appear. We will sort this out after our first sleep freely moving recording

% for audio stim. Lets generate triggered LFPs around each stimulus. There
% are 500

fle = 'NP28_2019-07-09_18-31-05';
fle = 'NP35_2019-07-23_14-59-16';
processedPath = getfullpath(fle); 
cd(processedPath);
if exist([processedPath,'peripherals.mat'],'file') == 2
    disp '>loading preprocessed peripherals<';
    load([processedPath,'peripherals.mat']);
else
    % bring in the lfp data 
    [data,settings,tScale] = getLFP(fle);
    [chanTypes] = getChanTypes(settings);
    chPeriph = find(chanTypes == 2); % this type is the ADC channel which is the pressure sensor
    resp = data(chPeriph(8),:); % to be confirmed
    %microphone = data(chPeriph(7),:); % to be confirmed
     [data30k,settings30k,tScale30k] = getDAT(fle,7);
    
    % if you want to trim the data variable so that only a few channels
    % remain in there then do it like so 
    data=data([5 7 12 10 35 37 39 42 44 46 65:70 77 78],:);
    % here we need to extract the events from the events file to be done by
    % nP something like this prob: 
    dataPath = getFullPath(fle);
    [ev, timestamps, info] = load_open_ephys_data([fullfile(dataPath,'all_channels.events')]);
    save([processedPath,'peripherals.mat'],'data','rewards','runSpeed','carouselSpeed','location','direction','licks','tScale','vidPulses','settings', '-v7.3');% ,'AchPulses'
end
    
   

%convert time stamps to 1000Hz samples offsets

ev = round(ev/30);
data = zscore(data')';

%% lets get the phase of the respiratory cycle
resp=data(1,:);
figure;plot(resp);
% resp = data(1,:);
respF = filter_lfp(resp, 1000, [0.1 5]);
respF = zscore(respF);
data(1,:) = respF;
clear resp respF;
[lfp_phases lfp_power] = extract_lfp_phase(data(1,:));
figure;
% h(1)=subplot(211);
plot(data(1,:)'); hold on;
% plot(lfp_filtered); 
% h(2)=subplot(212);
plot(lfp_phases);
% linkaxes(h,'x');
xlim([10000,20000]);

% generate random events for 'control'
rev = randi([10000,length(tScale)-10000],length(ev)*2,1);
ch = [13,56]; ar = {'resp','CTX','CA1'}; specType = {'ripples','4Hz'}; l = [2000, 6000];nme={'shortWin','longWin'};
for k = 2:2 %winlen
    pos = [208   454   964   715];
    figure('position',pos);
    c=2;r=4;
    sind = reshape(1:8,c,r)';%sind=sind(:);
    for j = 1:2 %brain area
        % Now use these time stamps to generate windows triggered LFPs
        [out_ev,excluded] = trig_lfp(data(ch(j),:),ev, l(k));
        [out_rev,excluded] = trig_lfp(data(ch(j),:),rev, l(k));
        out_ev  = detrend( out_ev' )';
        out_rev = detrend( out_rev')';
%         figure;plot(out_ev(1,:));
%         figure; plot(out_ev(1:2,:)');
%         figure; imagesc(out_ev);
        % lets instead generate triggered spectrograms. They will be more
        % informative
        options.defaults = specType{k};
        for i = 1:500
            Sev = specmt(out_ev(i,:),options);
            Sev_all(:,:,i) = Sev.Sxy;    
        end

        for i = 1:1000
            Srev = specmt(out_rev(i,:),options);
            Srev_all(:,:,i) = Srev.Sxy;      
        end

        %%
        ofs = max(Sev.t)/2;
        
        subplot(4,3,sind(1,j));
        imagesc(Sev.t-ofs,Sev.f,mean(Sev_all(:,:,1:200),3)'); axis xy;
        title([ar{j},', ISI 1s and loud(ish), n = 200']);
        subplot(r,c,sind(2,j));
        imagesc(Sev.t-ofs,Sev.f,mean(Sev_all(:,:,200:300),3)'); axis xy;
        title([ar{j},', ISI N(3,2) and low volume, n = 100']);
        subplot(r,c,sind(3,j));
        imagesc(Sev.t-ofs,Sev.f,mean(Sev_all(:,:,300:500),3)'); axis xy;
        title([ar{j},', ISI 2s and low volume, n = 200']);
        subplot(r,c,sind(4,j));
        imagesc(Sev.t-ofs,Sev.f,mean(Srev_all(:,:,:),3)'); axis xy;
        title([ar{j},', rand trigger, n = 1000']);        
    end
    print([processedPath,'trigSpecgram_',nme{k}],'-djpeg','-r300');
end



%% lets trigger the respiration phase with the auditory stimuli


% Now use these time stamps to generate windows triggered LFPs
[out_ev,excluded] = trig_lfp(lfp_phases,ev, 3000);
[out_rev,excluded] = trig_lfp(lfp_phases,rev, 3000);


out_ev  = detrend( out_ev' )';
out_rev = detrend( out_rev')';

figure; 
subplot(211); shadedErrorBar([],mean(out_ev,1),std(out_ev,1)./sqrt(200));axis tight;
subplot(212); shadedErrorBar([],mean(out_rev,1),std(out_rev,1)./sqrt(200)); axis tight;
% nothing comes out of this

%% now lets work with all the stimuli but divide into two 0-180 degrees respiratory phase vs 180-360
[val,idx] = sort(out_ev(:,3000));
catResp = zeros(size(val));
catResp(val>0) = 1;
catResp(val<0) = 0;

inEv = idx(catRes==0);% assume for now that 0s correspond to inhilation just as an example
options.defaults = specType{k};
for i = inEv
    Sev = specmt(out_ev(i,:),options);
    Sev_all(:,:,i) = Sev.Sxy;    
end













%%
1. import the data and the events (need to generate the code for import of the messages.events)
2. detect the audio signal in thre ADC channel (high pass filter, rectify, and threshold detect the events - they should match closely the events in messages.events
3. then generate triggered windows around the sound stimulation for slow wave filtered waveforms and for 




























%% THIS IS VARIOUS CODE SNIPPETS THAT ARE NOT NECESSARILY USEFUL ATM
figure;
for i = 1:length(ev)
    imagesc(S.t,S.f,squeeze(S.Sxy(:,:,i,i))'); axis xy
    pause
end

figure; clear Smu;
Smu = real(squeeze(S.Sxy(:,:,401,401))');
for i = 402:500%length(ev)
    Smu = Smu + real(squeeze(S.Sxy(:,:,i,i))'); 
end
%Smu=Smu./length(ev);
imagesc(S.t,S.f,Smu); axis xy;

figure; clear Smu;
Smu = real(squeeze(S.Sxy(:,:,301,301))');
for i = 302:400%length(ev)
    Smu = Smu + real(squeeze(S.Sxy(:,:,i,i))'); 
end
%Smu=Smu./length(ev);
imagesc(S.t,S.f,Smu); axis xy;

%% WeiWeis artefact correction:
ifRun = 0;
if ifRun
    addpath(genpath('/storage/weiwei/matlab/EMG_removing/'));
    D = data(5:68,:);
    [x, Ws, As, EMG_au] = EMG_rm(D, 1000,false);

    figure;plot(1:length(D), [zscore(runSpeed(:))+10, EMG_au(:)/10])

    [out,excluded] = trig_lfp(EMG_au,ev, 500);
    figure;imagesc(out);

    eegplot([EMG_au x(9:10,:)' D(9:10,:)']','srate',1000,'color','on');

    tmp_t = 404*1e3 : 407*1e3;
    figure;
    tmp_ch = 1:62;
    plot(tmp_t/1000, bsxfun(@plus, x(tmp_ch,tmp_t), std(x(60,:)')*[1:length(tmp_ch)]'),'r')
    hold on
    plot(tmp_t/1000, bsxfun(@plus, D(tmp_ch,tmp_t), std(x(60,:)')*[1:length(tmp_ch)]'),'k')
    plot(tmp_t/1000,  std(x(60,:)')*(EMG_au(tmp_t)+63))
end