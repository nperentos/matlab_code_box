function [ThPh, ThAmp, ThFr] = thetaProps(fileBase, varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% [ThPh, ThAmp, ThFr] = ThetaProps(FileBase, varargin) computes theta
% parameters (phase, amplitude and center frequency for a single lfp
% channel. The channel number should be supplied
% At its core, it's the equivalent to ThetaParams from Sirota lab but 
% handles input and output variables differently.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% PRE
    options = {'channel',[],'data',[],'freqRange',[4 12],'phaseMethod','hilbert','freqMethod','spect','filterMethod','adapt','dataType','raw','channelName','thetaCh','nICAComps',4};
    options = inputparser(varargin,options);
    if strcmp(options,'error'); return; end;
    if isempty(options.channel);   
        error('You did not provivde a channel number \n%s','e.g. [ThPh, ThAmp, ThFr] = thetaProps(fileBase, {''channel'',55}')
    end
    if ~(strcmp(options.dataType,'raw') | strcmp(options.dataType,'ica') | strcmp(options.dataType,'ICA'))
        if strcmp(options.dataType,'ICA')
            options.dataType = 'ica';
        end        
    end
    processedPath = getfullpath(fileBase);
    cd(processedPath);

    
    
%% LOAD LFP (and ICs if requested)
    if isempty(options.data) 
        if strcmp(class(options.channel),'char') % in case we read from the spreadsheet as a string
            error('you supplied a character array as channel number. This implies that you pased directly the channel number spreadsheet entry without adding 1? please investigate');
            %options.channel = str2num(options.channel); 
        end
        %options.channel = options.channel;
        disp(['using channel ',int2str(options.channel),' to estimate theta parameters...']);
        if strcmp(options.dataType,'ica') % must load all channels unfortunately
            disp('correcting for common mode...');
            [data,settings,tScale] = getLFP(fileBase);
            load('commonMode.mat');            
        % reconstruct corrected data where data is the whole recording or new data            
            idx = find(commonMode.ch == options.channel);                        
        % lets try to do it without picking the one channel just to see
            newICs = commonMode.W * data(commonMode.ch,:);
            common = commonMode.A(:,commonMode.orderedComps(1:options.nICAComps))  *  newICs(commonMode.orderedComps(1:options.nICAComps),:);
            dataReconstructed = data(options.channel,:)-common(idx,:);
            clear data
            data = dataReconstructed; % now we have the IC-corrected theta channel
        else 
            [data,settings,tScale] = getLFP(fileBase,[],options.channel);
        end        
    else
        error('not implemented! You cannot pass data directly, only through LFP file')
        %data = options.data;        
    end
    
    pth = fullfile(getfullpath(fileBase),[fileBase,'.lfp']);
    par = LoadXml([pth(1:end-4),'.xml']);
    
    SR = par.lfpSampleRate;
    nT = length(data);

%% SIMPLE SPECTROGRAM - GENERAL THETA!
    spcmt = specmt(data,{'defaults','theta'});
    
%% COMPUTE THETA FREQUENCY
switch options.freqMethod
    case 'spect'
        wdata = WhitenSignal(data,SR*2000,1);
        %choose window: should be ~7 cycles to give good freq. resolution

        win = 2^floor(1+log2((SR/mean(options.freqRange)*25)));
        step = 2^nextpow2(SR*0.2);
        %compute spectrogram in the freq. range 1: fr(2)+5Hz
        [y,f,t] = mtchglong(wdata,win,SR,win,win-step,1,'linear',[],[1 options.freqRange(2)+5]);

        t =  t+ win/2/SR; %times of the centers of the windows
        tsmpl = [1; floor(t(:)*SR); nT]; %get t in samples
        if 0
            %computer maxima of power in each slice - not very reliable
            powstats = sq(PowerPeakStats(log(y), f, options.freqRange));
            pkfreq = powstats(:,1);
        else
            %instead, find the center of mass of the freq. range
            %keyboard
            fi = find(f>options.freqRange(1) & f<options.freqRange(2));
            pkfreq = dotdot(sum(dotdot(y(:,fi),'*',f(fi)'),2),'/',sum(y(:,fi),2));
        end
        ThFr = interp1(tsmpl,[pkfreq(1) ; pkfreq; pkfreq(end)], [1:nT],'pchip')';
        %ThAmpSpec = interp1(tsmpl,powstats(:,3),[1:nT],'cubic');

        %             if Verbose
        %                 %test spec
        %                 figure
        %                 clf
        %                 imagesc(t,f,log(y));axis xy
        %                 rem = load([FileBase '.sts.REM']);
        %                 hold on;plot([rem(1,1):rem(1,2)]/1250, ThFr([rem(1,1):rem(1,2)]),'k.');
        %                 xlim([rem(1,1) rem(1,2)]/1250)
        %                 pause
        %             end


    case 'analyt'

        k = 500;
        gaussker = normpdf(-k:k,0, k/4)';
        smoothThPh = Filter0(gaussker,unwrap(ThPh));
        ThFr= diff(smoothThPh)*SR/2/pi;

    otherwise
        error('unknow FreqMethod');
end
    
    
%% FILTER IN THE THETA BAND
switch options.filterMethod
    case 'butt'
        dataf = ButFilter(data,4,options.freqRange/SR*2,'bandpass');

    case 'cheb'
        [b a] = Scheby2(4,20, options.freqRange/SR*2);
        dataf = Sfiltfilt(b,a,data);

    case 'mt'
        dataf = MTFilter(data, options.freqRange, SR, 2^nextpow(0.5*SR));

    case 'adapt'
        if ~exist('ThFr','var')
            load(FileOut,'ThFr');
        end
        if size(data,1) < size(data,2) % just flip it ... dodgy stuff...
            data = data';
        end
        %dataf = AdaptiveFilter([data, ThFr], 'filter', round(SR*3), round(SR), 5, SR);
        dataf = AdaptiveFilter([data, ThFr], 'filter', round(SR*3), round(SR), 3, SR);
        dataf(:,2)=[];

    otherwise
        if isnumeric(Filter)
            dataf = filtfilt(Filter(:,2),Filter(:,1),data);
        else
            error('don''t know such Filter choice');
        end
end

    
%% COMPUTE THETA PHASE
switch options.phaseMethod
    %both min and max have problem due to bias to rational numers
    %2*pi*(1,1/2,0,1/4,1/8,1/16 ...) those are mostly in the
    %[0:pi/2] range and if smoothed will create a bias to [0:pi/2]
    %values
    case 'max'
        MinPeriod = 0.8*SR./options.freqRange(2);
        ThPk = LocalMinima(-dataf,MinPeriod,0);
        ThPk = [1; ThPk; nT];
        ThPh = PhaseFromCycles([1:nT]', ThPk(1:end-1), ThPk(2:end));
        ThAmp = interp1(ThPk, abs(dataf(ThPk)), [1:nT]','cubic');
        ThPh(1)=ThPh(2);
    case 'min'
        MinPeriod = 0.8*SR./options.freqRange(2);
        ThTr = LocalMinima(dataf,MinPeriod,0);
        ThTr = [1; ThTr; nT];
        ThPh = PhaseFromCycles([1:nT]', ThTr(1:end-1), ThTr(2:end));
        ThPh = ThPh + pi;    % shift such that 0 is theta peak
        ThAmp = interp1(ThTr, abs(dataf(ThTr)), [1:nT]','cubic');

    case 'hilbert'
        hilb = hilbert(dataf);
        ThPh = angle(hilb);
        ThAmp = abs(hilb);
    otherwise
        error('unknow PhaseMethod');
end 





%% SAVE 
    props.spcmt = spcmt;
    props.lfp = data;
    props.thPh = ThPh;
    props.thAmp = ThAmp;
    props.thFr = ThFr;
    props.fileBase = fileBase;
    props.channel = options.channel;
    props.methods = ['channel:',options.channelName,int2str(options.channel),...
        ', props.spcmt:general 0.1-10Hz specgram',...    
        ', phaseMethod:',options.phaseMethod,...
        ', freqMethod:',options.freqMethod,...
        ', filterMethod:',options.filterMethod,...
        ', band:[',num2str(options.freqRange),']'];
    disp('saving data...');
    
    save(fullfile(getfullpath(fileBase),[options.channelName,'_props_',options.dataType,'_ch',int2str(options.channel),'.mat']),'props');    
    
    disp(['saved: ',fullfile(getfullpath(fileBase),[options.channelName,'_props_',options.dataType,'_ch',int2str(options.channel),'.mat'])]);
    
    
    disp('DONE');
    %print(fullfile(processedPath,'commonMode.jpg'),'-djpeg'); 



