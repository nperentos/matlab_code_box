function generateAuxVars(fileBase)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% generateAuxVars(fileBase) collects relevant behavioral variables derived
% from ADC channels and some theta and respiration variables
% List of variables : 
% breathing (rate,phase and gamma)
% theta properties (amplitude, phase,center frequency)
% events (4 carousel positions: start, left and right cages and far point)
% speed of running from rotary encoder
% carousel position
% carousel speed from motor's rotary encoder
% licking rate and events from piezo sensor on water port
% NOTE: other variables may be added later
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% PRE 
    %     options = {'channel',[],'data',[],'freqRange',[4 12],'phaseMethod','hilbert','freqMethod','spect','filterMethod','adapt','dataType','raw'};
    %     options = inputparser(varargin,options);
    %     if strcmp(options,'error'); return; end;
    %     if isempty(options.channel);   
    %         error('You did not provivde a channel number \n%s','e.g. [ThPh, ThAmp, ThFr] = thetaProps(fileBase, {''channel'',55}')
    %     end

    % load the xml session data (e.g. get sampling rate) 
    close all;
    processedPath = getfullpath(fileBase);
    cd(processedPath);
    pth = fullfile(getfullpath(fileBase),[fileBase,'.lfp']);
    par = LoadXml([pth(1:end-4),'.xml']);
    SR = par.lfpSampleRate;       
    SR_LFP = par.lfpSampleRate;
    SR_WB = par.SampleRate;
    s = dir([processedPath,fileBase,'.lfp']);
    nSamples_LFP = s.bytes/(par.nChannels*2);% 2 b/c data is 16 bit ints => 2 bytes per datapoint
    s = dir([processedPath,fileBase,'.dat']);
    nSamples_WB  = s.bytes/(par.nChannels*2);% 2 b/c data is 16 bit ints => 2 bytes per datapoint    
    nn = 1; % row offset into the final matrix of variables. Also used for the names variable
    fprintf('generating auxiliary variables\n');
    
    
%% (BEHAVIORAL VARIABLES) - THETA PARAMETERS
    % for normal lfp channel
    ch = str2num(searchMasterSpreadsheet(fileBase,'thetaCh')) + 1;
    
    oscillationProps(fileBase, {'channel',ch,'dataType','raw','channelName','thetaCh'});
    % for ICA reconstructed data
    oscillationProps(fileBase, {'channel',ch,'dataType','ica','channelName','thetaCh'});

    % collect the data   
    th_raw = load(['thetaCh_props_raw_ch',int2str(ch),'.mat']);        
    th_ica = load(['thetaCh_props_ica_ch',int2str(ch),'.mat']); 
    
    %ddd = [th_raw.props.lfp'; th_raw.props.thPh'; th_ica.props.thPh' ];
    %eegplot(ddd,'srate',1000,'color','on','winlength',3);

    % summary figure     
    figure('pos',[10 10 1978 1000]);
    clf;
    subplot(3,3,1);
        ddd = [th_raw.props.thFr'; th_ica.props.thFr'];
        XBins = linspace(min(ddd(:)),prctile(ddd(:),100),100); YBins = XBins;
        hist2(ddd',XBins,YBins); axis square; hold on;    
        plot([XBins(1) XBins(end)],[YBins(1) YBins(end)],'--w','linewidth',2);
        xlabel('raw theta frequency (Hz)');
        ylabel('ICA corrected theta frequency (Hz)');
        %[Out, XBins, YBins, Pos] = hist2(ddd');
    subplot(3,3,2);
        ddd = [ th_raw.props.thAmp'; th_ica.props.thAmp' ];
        XBins = linspace(0,prctile(ddd(:),99),100); YBins = XBins;
        hist2(ddd',XBins,YBins); axis square; hold on;
        plot([XBins(1) XBins(end)],[YBins(1) YBins(end)],'--w','linewidth',2);
        xlabel('raw theta amplitude (\muV)');
        ylabel('ICA corrected theta amplitude (\muV)');
    subplot(3,3,3);
        ddd = [ th_raw.props.thPh'; th_ica.props.thPh' ];
        hist2(ddd',100,100); axis square; hold on;
        plot([-pi pi],[-pi pi],'--w','linewidth',2);
        xlabel('raw theta phase (rad)');
        ylabel('ICA corrected theta phase (rad)');
    subplot(3,3,[4:6]);
        imagesc(th_raw.props.spcmt.t,th_raw.props.spcmt.f,abs(th_raw.props.spcmt.Sxy')); axis xy;
        caxis([0, 0.95*max(max(abs(th_raw.props.spcmt.Sxy)))]); colorbar;
    subplot(3,3,[7:9]);
        imagesc(th_ica.props.spcmt.t,th_ica.props.spcmt.f,abs(th_ica.props.spcmt.Sxy')); axis xy;
        caxis([0, 0.95*max(max(abs(th_ica.props.spcmt.Sxy)))]); colorbar;
    ForAllSubplots('set(gca,''fontsize'',10)'); 
    mtit('theta properties');
    
    % save a summary figure
    print(fullfile(getfullpath(fileBase),'thetaProperties.jpg'),'-djpeg');
    close;
    
    % collect variables into the output table
    behavior.data(nn,:) = th_raw.props.thPh;  behavior.name{nn} = 'theta_raw_phase';  nn=nn+1;
    behavior.data(nn,:) = th_raw.props.thAmp; behavior.name{nn} = 'theta_raw_amp';    nn=nn+1;
    behavior.data(nn,:) = th_raw.props.thFr;  behavior.name{nn} = 'theta_raw_fr';     nn=nn+1;
    behavior.data(nn,:) = th_ica.props.thPh;  behavior.name{nn} = 'theta_ica_phase';  nn=nn+1;
    behavior.data(nn,:) = th_ica.props.thAmp; behavior.name{nn} = 'theta_ica_amp';    nn=nn+1;
    behavior.data(nn,:) = th_ica.props.thFr;  behavior.name{nn} = 'theta_ica_fr';     nn=nn+1;  
    
    
    
%% (BEHAVIORAL VARIABLES) - RESPIRATION PARAMETERS
    ch = str2num(searchMasterSpreadsheet(fileBase,'respCh')) + 1;
    % for normal lfp channel
    oscillationProps(fileBase, {'channel', ch,'dataType','raw','freqRange',[1 12],'channelName','respCh'});
    % for ICA reconstructed data
    oscillationProps(fileBase, {'channel', ch,'dataType','ica','freqRange',[1 12],'channelName','respCh'});

    % gamma computations and figure generation    
    resp_raw = load(['respCh_props_raw_ch',int2str(ch),'.mat']);
    resp_ica = load(['respCh_props_ica_ch',int2str(ch),'.mat']);    
    
    hf = newA4Fig({'orientation','landscape'}); gp = 0.05;
    for j = 1:2  % raw and ica'ed
        
    % quantify gamma on the respiration signal       
        options.whiten = 1;%1
        options.pad=2;
        options.nw = 1;
        options.freqrange = [10 200];
        options.window = 0.5;%0.3
        options.overlap = 90;  
        if j == 1
            lfp = resp_raw.props.lfp';            
            Srg = specmt(lfp,options);
            phs = resp_raw.props.thPh';
            [a,b] = findpeaks(resp_raw.props.thPh);
            lowRespSpecRaw = specmt(lfp,{'defaults','4Hz'});            
        elseif j == 2
            lfp = resp_ica.props.lfp';
            Srg = specmt(lfp,options);            
            [a,b] = findpeaks(resp_ica.props.thPh);
            phs = resp_ica.props.thPh';
            lowRespSpecICA = specmt(lfp,{'defaults','4Hz'});
        end
        % what does this do????
        dim = 12;
        S_tmp = conv2(Srg.Sxy',1/dim^2*ones(dim,dim/2),'same');
        lims = prctile(S_tmp(:),[1 99]);

    % the mean of the spectra - look for gamma peaks to motivate bands
        % keep strongest peak only    
        % interpolate 50, 100 and 150 Hz to remove line noise
        % influence on peak detection
        mu = mean(Srg.Sxy,1);
        line_noise_band = false(size(Srg.f));
        for k = 1:floor(SR_LFP/50)
            line_noise_band(Srg.f<(k*50 + 3) & Srg.f>(k*50 - 3)) = true;
        end
        mu(line_noise_band) = nan;
        mu = fillmissing(mu,'linear');
        %figure; plot(Srg.f,mus,'g');%hold on; plot(Srg.f,mutest,'--r');
        mus = smooth(mu,10);
        ft = find(Srg.f>30 & Srg.f<140);
        [c,d,wdth,prom] = findpeaks(mus(ft),Srg.f(ft));
        [~,srt] = sort(prom,'descend');
        fpk{j} = d(srt(1:min([length(srt),2])));        
        
        % fixed gamma bands 
        tr1 = eegfilt(lfp,SR_LFP,30,48);%35,65
        ampL(j,:) = abs(hilbert(tr1));
        tr2 = eegfilt(lfp,SR_LFP,52,80);%65,100
        ampH(j,:) = abs(hilbert(tr2));
        tr3 = eegfilt(lfp,SR_LFP,40,140);%wideband
        ampW(j,:) = abs(hilbert(tr3));
        % eegplot([ampL;ampH;resp_raw.props.lfp'],'srate',1000,'color','on','winlength',3);


        % triggered spectrgram around the respiration troughs to get the high
        % frequency content. This is just a summary for now.
        

        b(find(b<=0.3*SR_LFP | b>=length(lfp')-0.3*SR_LFP)) = [];    
        Fs = 1000; %hz
        T=0.2; %sec
        WinLength = 2^floor(log2(T*Fs));
        nFFT= 2*WinLength;
        nOverlap = WinLength - WinLength/4; 
        NW =1; 
        Detrend='linear'; 
        nTapers = 1;
        FreqRange = [10 200]; 

        wd = WhitenSignal(lfp,SR_LFP*2000,1);
        %wd = WhitenSignal(resp_ica.props.lfp,SR_LFP*2000,1);
        %[TrigSpec,Trig_f,Trig_t] = TrigSpecgramNP(b(sort(randi(length(b),10,1))), 1*SR_LFP, wd,nFFT,Fs,WinLength,nOverlap,NW,Detrend,nTapers,FreqRange);   
        [TrigSpec,Trig_f,Trig_t] = TrigSpecgram(b(randsample(length(b),ceil(length(b)/3))), 0.5*SR_LFP, wd,nFFT,Fs,WinLength,nOverlap,NW,Detrend,nTapers,FreqRange);   

    % plot
        % spectrogram
            ofs = [0.5 0 0 0]*(j-1);
            ofs2 = [1.75*gp+0.2 0 0 0]*(j-1);
        axes('pos',ofs+[gp 0.7 0.3 0.25]);
            imagesc(Srg.t,Srg.f,S_tmp); axis xy; caxis([lims]);
            ylabel('frequency (Hz)'); xlabel('time (s)');
            yl=ylim;
            title(['win: ',num2str(Srg.options.window), 's, whiten: ', num2str(Srg.options.whiten), ', nw: ',num2str(Srg.options.nw)],'fontweight','normal');
        % mean spectrum
        axes('pos',ofs+[0.3+1.75*gp 0.7 0.1 0.25]);
            plot(log(mus),Srg.f,'k','linewidth',2);
            hold on;
            plot(xlim,[fpk{j} fpk{j}]','--r','linewidth',2);      
            ylim(yl); box off;      

            ylabel('frequency (Hz)'); xlabel('spectral power (a.u.)');

        % triggered respiration
            % lfp
            wn = 1*SR_LFP;
            [Segs Complete] = GetSegs(lfp, b-wn/2, wn);
            mu_resp = mean(Segs(:,Complete),2);
            sd_resp = std(Segs(:,Complete),[],2);
        axes('pos',ofs+ofs2+[gp 0.5 0.15 0.15]);    
            tt = ([1:wn]*1/SR_LFP) -max([1:wn]*1/SR_LFP)/2;
            shadedErrorBar(tt,mu_resp,1.96 .* sd_resp/sqrt(size(Segs,2)));
            xlabel('time (s)'); ylabel('amplitude (\muV)');
            % phase
        axes('pos',ofs+ofs2+[gp 0.3 0.15 0.15]);        
            [Segs Complete] = GetSegs(phs, b-wn/2, wn);
            mu_resp = mean(Segs(:,Complete),2);
            sd_resp = std(Segs(:,Complete),[],2);
            shadedErrorBar(tt,mu_resp,1.96.*sd_resp/sqrt(size(Segs,2)));    
            xlabel('time (s)'); ylabel('phase (rad)'); 
            % trig specgram
        axes('pos',ofs+ofs2+[gp 0.05 0.15 0.15]);    
            tsg(j) = imagesc(Trig_t,Trig_f,TrigSpec');axis xy;title(['T=',num2str(T),', NW=',num2str(NW),' ovrlp=75%',', nTprs=',num2str(nTapers)]);
            xlabel('time (s)'); ylabel('frequency (Hz)');  
            cax(j,:) = caxis;
            clear a b lfp camp cfs Srg phs;
    end    
    % theta spectrograms
        axes('pos',[0.25 0.05 0.1 0.6]); 
        imagesc(lowRespSpecRaw.f,[],abs(lowRespSpecRaw.Sxy)); xlim([0 10]); ytickangle(-90);
        ylabel('time (s)'); xlabel('freq. (Hz)'); caxis([0, 0.95*max(max(abs(lowRespSpecRaw.Sxy)))]); colorbar;
        axes('pos',[0.65 0.05 0.1 0.6]); 
        imagesc(lowRespSpecICA.f,[],abs(lowRespSpecICA.Sxy)); xlim([0 10]); ytickangle(-90);
        ylabel('time (s)'); xlabel('freq. (Hz)'); caxis([0, 0.95*max(max(abs(lowRespSpecICA.Sxy)))]); colorbar;
        % add the respiration rate parameters joint histograms for raw and ica
        axes('pos',[0.4 0.0125 0.2 0.6],'color',[.7 .7 .7]);
        set(gca,'xcolor','none','ycolor','none');

        axes('pos',[0.425 0.45 0.15 0.15]);
            ddd = [ resp_raw.props.thFr'; resp_ica.props.thFr' ];
            XBins = linspace(min(ddd(:)),prctile(ddd(:),100),100); YBins = XBins;
            hist2(ddd',XBins,YBins); axis square; hold on;    
            plot([XBins(1) XBins(end)],[YBins(1) YBins(end)],'--w','linewidth',2);
            xlabel('raw freq. (Hz)');
            ylabel('ICA freq. (Hz)');
            %[Out, XBins, YBins, Pos] = hist2(ddd');
        axes('pos',[0.425 0.25 0.15 0.15]);
            ddd = [ resp_raw.props.thAmp'; resp_ica.props.thAmp' ];
            XBins = linspace(0,prctile(ddd(:),99),100); YBins = XBins;
            hist2(ddd',XBins,YBins); axis square; hold on;
            plot([XBins(1) XBins(end)],[YBins(1) YBins(end)],'--w','linewidth',2);
            xlabel('raw ampl. (\muV)');
            ylabel('ICA ampl. (/muV)');
        axes('pos',[0.425 0.05 0.15 0.15]);
            ddd = [ resp_raw.props.thPh'; resp_ica.props.thPh' ];
            hist2(ddd',100,100); axis square; hold on;
            plot([-pi pi],[-pi pi],'--w','linewidth',2);
            xlabel('raw phase (rad)');
            ylabel('ICA phase (rad)');


    % overall labels
    axes('pos',[0 0 1 1]);
    text(0.2,0.99,'olfactory bulb screw - raw','fontsize',14,'color','b','fontweight','bold');
    text(0.7,0.99,'olfactory bulb screw - ICA-corrected','fontsize',14,'color','b','fontweight','bold');
    text(0.4,0.625,'raw vs ICA-corrected comparison','fontsize',14,'color','b','fontweight','bold');
    xlim([0 1]);ylim(xlim); axis off;

    ForAllSubplots('set(gca,''fontsize'',10,''box'',''off'')'); 

    % save a summary figure
    stampFig(fileBase);
    print(fullfile(getfullpath(fileBase),'respirationProperties.jpg'),'-djpeg');

    % collect variables into the output table
    behavior.data(nn,:) = resp_raw.props.thPh;  behavior.name{nn} = 'resp_raw_phase';           nn=nn+1;
    behavior.data(nn,:) = resp_raw.props.thAmp; behavior.name{nn} = 'resp_raw_amp';             nn=nn+1;
    behavior.data(nn,:) = resp_raw.props.thFr;  behavior.name{nn} = 'resp_raw_fr';              nn=nn+1;
    behavior.data(nn,:) = ampL(1,:);            behavior.name{nn} = 'resp_raw_gamma_low';       nn=nn+1;
    behavior.data(nn,:) = ampH(1,:);            behavior.name{nn} = 'resp_raw_gamma_high';      nn=nn+1;
    behavior.data(nn,:) = ampW(2,:);            behavior.name{nn} = 'resp_raw_gamma_wideband';  nn=nn+1;
    
    behavior.data(nn,:) = resp_ica.props.thPh;  behavior.name{nn} = 'resp_ica_phase';           nn=nn+1;
    behavior.data(nn,:) = resp_ica.props.thAmp; behavior.name{nn} = 'resp_ica_amp';             nn=nn+1;
    behavior.data(nn,:) = resp_ica.props.thFr;  behavior.name{nn} = 'resp_ica_fr';              nn=nn+1;       
    behavior.data(nn,:) = ampL(2,:);            behavior.name{nn} = 'resp_ica_gamma_low';       nn=nn+1;
    behavior.data(nn,:) = ampH(2,:);            behavior.name{nn} = 'resp_ica_gamma_high';      nn=nn+1;
    behavior.data(nn,:) = ampW(2,:);            behavior.name{nn} = 'resp_ica_gamma_wideband';  nn=nn+1;

    clear th_raw th_ica resp_raw resp_ica ampL ampH tr1 tr2 wd Trig* Complete ans ddd;

    
    
%% (BEHAVIORAL VARIABLES) - ADC CHANNELS
    [data,settings,tScale] = getLFP(fileBase);
    xml = LoadXml(fullfile(processedPath,fileBase));
    
    [chanTypes] = getChanTypes(settings);
    
    % in some cases where extra channels were recorded on the EEG screws
    % intan 32 headstage by mistake, these will mess up things unless we
    % trim the labels as per the lines below
    if any(isnan(chanTypes))
        disp('there are unacconted for channels in this dat file');
        disp('running further checks');
        if length(chanTypes) > xml.nChannels || length(chanTypes) > size(data,1)
            chanTypes(isnan(chanTypes)) = []; % but atm this is untested for normal sessions....
        end
    end
    
    chPeriph = find(chanTypes == 2); % ADC channels
    if numel(chPeriph) == 4
        runCh = chPeriph(1); lickCh = chPeriph(2); carouselCh = chPeriph(3); rewardCh = chPeriph(4); 
    elseif numel(chPeriph) == 5
        runCh = chPeriph(1); lickCh = chPeriph(2); carouselCh = chPeriph(3); rewardCh = chPeriph(4); vidPulsesCh = chPeriph(5);
    elseif numel(chPeriph) == 8 %(photometry on 6 and empty on 7&8)
        runCh = chPeriph(1); lickCh = chPeriph(2); carouselCh = chPeriph(3); rewardCh = chPeriph(4); vidPulsesCh = chPeriph(5); AChPulsesCh = chPeriph(6);
    else
        error('I was expecting 4 or 5 ADC channels - please check');
    end
    
    
    nDiscard = 0;
    if any(chPeriph > size(data,1))
        display('there is a problem with the number of channels');
        disp('possibly this is due to a setup file that recorded unwanted EEG channels');
        if exist(fullfile(getFullPath(fileBase),['raw_',fileBase],'discarded_channels')) == 7
            disp('found a discarded channels folder inside the raw folder - will try to fix ...');
            % how many channels are there here
            cd(fullfile(getFullPath(fileBase),['raw_',fileBase],'discarded_channels'));
            nDiscard = length(dir('*CH*')) +  length(dir('*AD*'));
            % remove n adc channels from the end, the ones  in discarded
            % folder
            chPeriph = chPeriph(1:end-length(dir('*AD*')));
            chPeriph = chPeriph - length(dir('*CH*'));% - length(dir('*AD*'));
            try
                [data30k,settings30k,tScale30k] = getDAT(fileBase,chPeriph);
            catch
                display('could not resolve issue with channel numbers please investigate');
                keyboard();
            end
        end
    else
        [data30k,settings30k,tScale30k] = getDAT(fileBase,chPeriph);
    end
    cd(processedPath);
    
% events (TTLs) from arduino digital port
    events_tmp = getRewards(data30k(4,:));
% run speed from running disk rotary encoder
    behavior.data(nn,:) = getRunSpeed(data30k(1,:));behavior.name{nn} = 'runSpeed'; nn=nn+1;
% carousel speed (motor's rotary encoder 
    behavior.data(nn,:) = getCarouselSpeed(data30k(3,:)); behavior.name{nn} = 'carouselSpeed'; nn=nn+1;
% position and rotation direction - this needs carousel paradigm type!
    tt = searchMasterSpreadsheet(fileBase,'taskType');
    if any(strcmp(tt,{'-','none','ripples','settle'}))
        [position, direction, position_context] = getCarouselPosition(data30k(3,:),events_tmp,  0  , fileBase); % no task
    elseif any(strcmp(tt,{'continuous'}))
        [position, direction, position_context] = getCarouselPosition(data30k(3,:),events_tmp,  1  , fileBase); % continuous aka closed loop
    elseif any(strcmp(tt,{'controlled'}))
        [position, direction, position_context] = getCarouselPosition(data30k(3,:),events_tmp,  2  , fileBase); % controlled aka open loop
    elseif any(strcmp(tt,{'cued','failed','merged'}))
        error('cannot compute carousel position for these types of tasks - check if you can change manually');
    else
        error('unrecognised task type - please investigate');
    end
    if ~all(isnan(position))
        pos = rad2deg(smooth(position,20)); % why not put this inside the function getCar...?
            % do we really needs this discretisation ? why ?
        bnsz = 1;
        posEdges = [-360:bnsz:360];
        posDiscr = discretize(pos, posEdges);
        binCenters = posEdges-(bnsz/2)*sign(posEdges);
    else
        pos = position;
        posDiscr = nan;
        binCenters = nan;
        disp('************************************************');
        disp('position is not computed properly - please check');
        disp('??pulses are missing??');
        disp('************************************************');
    end

    
    behavior.data(nn,:) = pos;  behavior.name{nn} = 'position'; nn=nn+1;   
    behavior.data(nn,:) = posDiscr;  behavior.name{nn} = 'posDiscr'; nn=nn+1;   
    
     
    % licking activity
    out = getLicks(data(chPeriph(2),:),{'fileBase',fileBase}); 
    behavior.data(nn,:) = out.activity; behavior.name{nn} = 'licking_activity'; nn=nn+1;
    behavior.data(nn,:) = out.events;   behavior.name{nn} = 'lick_events';      nn=nn+1;

    
    
%% EVENTS
    % events (TTLs) from arduino digital port
    events.TTL = events_tmp; clear events_tmp;
    % carousel direction of rotation - was extract above
    events.direction = direction;
    
    % TO ADD: messages from OE
    
    % TO ADD: events such as ripples or dentate spikes??

    
    
%% HELPERS
    helper.positionBinCenters = binCenters;
    helper.position_context = position_context;
    % the detected gamma center frequencies saved in helper
    helper.gammaOBPeaks.raw = fpk{1};
    helper.gammaOBPeaks.ica = fpk{2};
    % carousel movement index (binary, moving not moving)
    idxMov = zeros(size(tScale));
    tmp = behavior.data(find(strcmp(behavior.name,'carouselSpeed')),:);
    idxMov(tmp>1) = 1; % behavior.data(nn,:) = idxMov; behavior.name{nn} = 'idxMov'; nn=nn+1;    
    helper.idxMov = idxMov;
    clear tmp;
    
    % trian number index
    if ~isempty(find(idxMov == 1,1)) || ~strcmp(events.TTL,'no pulses available')
        idxTrialEpochs = [find(idxMov == 1,1); events.TTL.atStart];
        idxTrialEpochs = [idxTrialEpochs, circshift(idxTrialEpochs,-1)];
        idxTrialEpochs(end,:) = [];
        tmp = zeros(size(tScale));
        for i = 1:length(idxTrialEpochs)
            tmp(1,idxTrialEpochs(i,1):idxTrialEpochs(i,2)) = i;
        end
    else
        display('there are no trials on this session');
        tmp = zeros(size(tScale));
    end
    helper.idxTrials  = tmp;clear tmp;    
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     
    % what is this????.data(nn,:) = idxTrials; behavior.name{nn} = 'idxTrials'; nn=nn+1;
    
    
    % video times and photometry pulses, if available
    if numel(chPeriph) == 5
        helper.vidPulses = getVidTimes(data30k(5,:)); 
    end
    if numel(chPeriph) == 6 || numel(chPeriph) == 8
        helper.vidPulses = getVidTimes(data30k(5,:)); 
        helper.AchPulses = getVidTimes(data30k(6,:));
    end
        

   
%% INFO
    % get the master spreadsheet - should contain everything we need here
    T = getCarouselDataBase;
    o = find(strcmp(T.session,fileBase));
    if length(o) ~= 1
        error('there seem to be multiple files with the same session number?');
    end
    try
        info.nTrials = length(events.TTL.atStart);
    catch
        info.nTrials = 0;
    end
    info.taskType =  T.taskType{o};% continuous or controlled (closed or open loop)
    % find previous day condition
    try
        for i = 1:min([10 o]) % we go max 10 sessions back (no animal has 10 recordings within the same day)
            prev = days(datetime(fileBase(6:end),'InputFormat','yyyy-MM-dd_HH-mm-ss')-...
                datetime(T.session{o-i}(6:end),'InputFormat','yyyy-MM-dd_HH-mm-ss'));% fileBase of this mouse's previous session
            if prev > 0.9
                prev = o-i;
                % if its ripples or settle or approach go back one more
                cont = 1;
                while cont 
                    if strcmp(T.manipulation{prev},'ripples') ||...
                            strcmp(T.manipulation{prev},'settle') ||...
                            strcmp(T.manipulation{prev},'aborted') ||...
                            strcmp(T.manipulation{prev},'failed') ||...
                            strcmp(T.manipulation{prev},'approach')
                        prev = prev - 1;
                    else
                        cont = 0;
                    end
                end
                info.previousSession.fileBase = T.session{prev};
                info.previousSession.manipulation = T.manipulation{prev};
                break;
            end
        end
    catch
        info.previousSession.fileBase = [];
        info.previousSession.manipulation = [];
    end
    if strcmp(events.TTL,'no pulses available')
        info.breakDurations = [];
    else
        info.breakDurations = floor(max(diff(events.TTL.atStart)/(60*par.lfpSampleRate))); % this is susceptble to 
    end
    % get number of cells if possible
    try
        sp = loadKSdir(pwd);
        info.nClusters.SUA = length(find(sp.cgs == 1));
        info.nClusters.MUA = length(find(sp.cgs == 2));
    catch
        info.nClusters.SUA = NaN;
        info.nClusters.MUA = NaN;
    end
    info.fileBase = T.session{o};
    info.nBlocks = str2num(T.blocks{o});
    info.conditions = split(T.blockConditions{o},',');
    info.trialsPerBlock = str2num(T.trialsPerBlock{o});
    info.rejTrials = str2num(T.rejTrials{o}); % try to use this to skip trials that are problematic. For the mo, only employed for NP51....50-28 
    info.conditions = split(T.blockConditions{o},',');
    info.manipulationPosition = T.manipulationPosition{o};
    info.protocolComplete = T.protocolComplete{o};
    info.probes{1} = T.probe1{o};
    info.probes{2} = T.probe2{o};
    info.targets{1} = T.target1{o};
    info.targets{2} = T.target2{o};
    info.fluoMarkers{1} = T.fluoMarker1{o};
    info.fluoMarkers{2} = T.fluoMarker2{o};
    info.comments.notes = T.notes{o};
    info.SR_LFP = SR_LFP;
    info.SR_WB = SR_WB;    
    info.nSamples_WB = nSamples_WB;
    info.nSamples_LFP = nSamples_LFP; 
    
    info.goodVidVars.names = {'pupil','wSVD','sSVD','nose','whiskers'}';
    for i = 1:length(info.goodVidVars.names)
        try
            test = T.(info.goodVidVars.names{i}); %pupil{o}),str2num(T.wSVD{o}), str2num(T.sSVD{o}), str2num(T.nose{o}), str2num(T.whiskers{o})];
            if isempty(test{o})
                info.goodVidVars.val(i) = 0;
            else
                info.goodVidVars.val(i) =  str2num(test{o});
            end
            %session.info.goodVidVars.val =  [str2num(T.pupil{o}),str2num(T.wSVD{o}), str2num(T.sSVD{o}), str2num(T.nose{o}), str2num(T.whiskers{o})];
        catch
            disp('possibly incomplete session.info.goodVidVars .... please check')
            info.goodVidVars.val(i) = 0;
        end
    end  


    
%%    
%     % what goes into the session variable?
%     if 1 == 0
%         info        DONE % general information 
%         firingRates MISSING % a memory mapping to the firing rates at the lfp scale?
%         spikes      MISSING % the actual spike times and ids
%         lfp         MISSING % memory map the actual lfp?
%         behavior    PARTIAL MISSING THE VIDEO VARIABLES
%         helper      DONE%(vid times, carousel movementornot index idxtrial )
%         events      MISSING %(ttls, direction of travel of carousel, lfp events like dentate spikes ripples? bursts)
%     end


%% SAVE DATA AND SUMMARY PLOTS
%
    %stampFig(fileBase,[],{['taskType:',T.taskType{o}]});
    %print(fullfile(getfullpath(fileBase),'respirationProperties.jpg'),'-djpeg');
    
    session.info = info;
    session.info.ADC_assignments.runCh = chPeriph(1); 
    session.info.ADC_assignments.lickCh = chPeriph(2);
    session.info.ADC_assignments.carouselCh = chPeriph(3);
    session.info.ADC_assignments.rewardCh = chPeriph(4);
    session.info.ADC_assignments.vidPulsesCh = chPeriph(5);
    session.events = events;    
    session.helper = helper;
    behavior.name = behavior.name';
    fprintf('saving session info in session.mat and behavioral variables in behavior_interim.mat...');
    save(fullfile(processedPath,'session.mat'),'session','-v7.3');
    save(fullfile(processedPath,'behavior_interim.mat'),'behavior','-v7.3');
    fprintf('DONE\n');

    fprintf('generating some report figures...');
    figure('pos',get(0,'screensize').*[1 1 0.4 0.4]); 
    plot(tScale,behavior.data(find(strcmp(behavior.name,'position')),:));
    xlabel('time (s)'); ylabel('position (deg)'); title('carouselPosition');    
    stampFig(fileBase);
    print(fullfile(getfullpath(fileBase),'positionByTime.jpg'),'-djpeg');
    close;
%    
    figure('pos',[127 181 1558 1640]); 
    imagesc(zscore(behavior.data));
    set(gca,'YTick',[1:1:size(behavior.data,1)],'YTickLabel',behavior.name,'TickLabelInterpreter','none');    
%    
    stampFig(fileBase);
    print(fullfile(getfullpath(fileBase),'.jpg'),'-djpeg');
    fprintf('DONE\n')
    close;
end

% attempts to deal with line noise peaks in the psectrogram which were
% complicating the detection of gamma bands / peaks. At the end I decided
% to just interpolated around 50 Hz and harmonics instead.
% %% just do the spectrum as opposed to spectrogram
% %nfft = 251;
% %y = fft(lfp,nfft); % Fast Fourier Transform
% figure;
% y = fftshift(fft(fftshift(lfp)));
% Pyy = y.*conj(y)/length(lfp)/2;
% Pyy = Pyy((length(Pyy)-1)/2:end);
% fax = linspace(0,SR/2,length(Pyy));
% subplot(311); plot(fax,log(Pyy));
% 
% 
% [lfpf] = ButFilter(lfp, 2, [49 51]/(SR/2),'stop');
% y = fftshift(fft(fftshift(lfpf)));
% Pyy = y.*conj(y)/length(lfpf)/2;
% Pyy = Pyy((length(Pyy)-1)/2:end);
% fax = linspace(0,SR/2,length(Pyy));
% subplot(312); plot(fax,log(Pyy));
% 
% [lfpf] = ButFilter(lfp, 2, [48 52]/(SR/2),'stop');
% y = fftshift(fft(fftshift(lfpf)));
% Pyy = y.*conj(y)/length(lfpf)/2;
% Pyy = Pyy((length(Pyy)-1)/2:end);
% fax = linspace(0,SR/2,length(Pyy));
% subplot(313); plot(fax,log(Pyy));
% 
% [data,settings,tScale] = getLFP(fileBase);
% xml = LoadXml(fullfile(processedPath,fileBase));    
% [chanTypes] = getChanTypes(settings);
% addpath(genpath('/storage/weiwei/matlab/EMG_removing'))
% kpCh = [xml.AnatGrps(1:end-1).Skip]==0;
% [A_line,W_line,A,W,power_ratio,line_thrd] = getLineNoise(data(kpCh,1:SR*60),1.8,SR,1);
% 
% 
% 
% print(fullfile(processedPath,'test.jpg'),'-djpeg');print('test.jpg','-djpeg');
