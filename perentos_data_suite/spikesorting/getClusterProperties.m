function nq = getClusterProperties(fileBase, varargin)
% getClusterProperties.m generates a table that holds various cluster
% characterstics that can be used to filter which putative cells or MUAs
% are included in further analysis

    options = {'pth',[],'verbose',1,'SINAPS',1};
    options = inputparser(varargin,options);  
    
% lets move to the folder of interest (requires less mods of this script)

    goto(fileBase);    
    Par = LoadXml([fileBase '.xml']);
    [SpkSamples, Channels, Electrodes,Display,Batch,Overwrite] = DefaultArgs(varargin,{52, [1:64],1,1,0,0});
    clear Electrodes;
  
% load good clusters only
    params.excludeNoise = 1;
    sp = loadKSdir(pwd,params);

    
    % check if sp.cids is sorted
    if ~issorted([sp.cids])
        disp('the cluster IDs are not sorted!');
        % only two variables to sort, cids and cgs
        I = sort(sp.cids);
        sp.cids = sp.cids(I);
        sp.cids = sp.cgs(I);
    end
    
    Chm=double(readNPY('channel_map.npy')); % the channels KS chose to keep

    Clu = double(sp.clu); % Clu are the same as in phy
    Res = double(sp.st*Par.SampleRate);

    uClu = unique(Clu); % uClu are the same as in phy
    nClu = length(uClu); % MUA and SUA

% the features to collect
    avSpk =[]; stdSpk = [];SpatLocal=[];SpkWidthC=[];SpkWidthL=[];SpkWidthR=[];posSpk=[];FirRate = [];AvSpkAll=[];
    leftmax=[]; rightmax=[];troughamp=[];troughSD=[];

% cross and autocorelograms for all clusters
    display('computing all cross correlograms...');
    [ccg tbin ] = CCG(Res,Clu+1, round(0.5*Par.SampleRate/1000), 30, Par.SampleRate,uClu+1,'hz'); % Clu+1 to protect against Clu=0. Otherwise does not return a cluster number so its incosequential
    save([fileBase,'.CCG.mat'],'ccg','tbin');
    ACG= MatDiag(ccg);

% ACGs for burstiness calcuation as ratio of spikes in <10 vs asymptote
    % (200-300ms)
    tic
    [ccgB tbinB ] = CCG(Res,Clu+1, round(1.5*Par.SampleRate/1000), 200, Par.SampleRate,uClu+1,'hz');
    ACGB= MatDiag(ccgB);
    toc
    burstiness = mean(ACGB(202:210,:),1)./mean(ACGB(334:401,:),1); % 1.5-13.5ms and 200-300ms ranges

% get mapping file that was fed into KS - Extract anatomical groups from it
    pth_to_KS_maps = '/storage2/perentos/code/thirdParty/KS/myKSortSettings/configFiles';
    fle = fullfile(pth_to_KS_maps,[fileBase,'_KSMap.mat']);
    if exist(fle)
        tmp = load(fle);
    end

% extract cluster average waveforms and assign peak channel
    display('assigning dominant channel to each cluster...');
    [avSpk, sdSpk,cluCh] = GetChannelWaveform(getfullpath(fileBase), Chm);
    cluAnatGroup = tmp.kcoords(cluCh);
    %test = cell2mat(avSpk);
    %ntest = reshape(test,length(avSpk{1}),length(avSpk));figure; plot(ntest);
    
%% CYCLE THROUGH ALL CLUSTERS IRRESPECTIVE OF LABEL AND COMPUTE FEATURES
    for cnum=1:length(uClu)
        display([int2str(cnum),'/',int2str(length(uClu))]);
% NUMBER OF SPIKES IN CLUSTER
        nSpikes(cnum) = length(find(Clu == uClu(cnum)));
        
% CLUSTER'S WAVESHAPE AT CHANNEL WITH MAXIMUM AMPLITUDE
        myAvSpk = avSpk{cnum};%sq(avSpk(maxampch,:,cnum)); % channel with largest spike waveform for this cluster
        mysdSpk = sdSpk{cnum};
        %figure; shadedErrorBar([],myAvSpk,mysdSpk);

% REVERSE SPIKE WAVESHAPE IF IT IS POSITIVE
        minamp  = abs(min(myAvSpk));
        maxamp  = max(myAvSpk);
        %        if (minamp-maxamp)/minamp < 0.05 %(spike is more positive then negative)
        if maxamp>1.2*minamp %(spike is more positive then        negative)
            myAvSpk = -myAvSpk; %reverse the spike
            posSpk(cnum) = 1;
        else
            posSpk(cnum) = 0;
        end

% UPSAMPLE THE SPIKE WAVEFORM
        ResCoef = 10; % upsample factor WAS CHANGED ON Aug.30 2005!!!!!!!!!!
        Sample2Msec = 1000./Par.SampleRate/ResCoef; %to get fromnew samplerate to the msec
        myAvSpk = resample(myAvSpk,ResCoef,1);
        mysdSpk = resample(mysdSpk ,ResCoef,1); %amphalf = mean(myAvSpk)-0.5*abs(min(myAvSpk-mean(myAvSpk)));
        
        %SEM = mysdSpk/sqrt(nSpikes(cnum));               % Standard Error
        % %ts = tinv([0.025  0.975],nSpikes-1);      % T-Score
        %ts = tinv([0.025],nSpikes-1);      % T-Score
        %CI = myAvSpk+SEM*ts;  
        

        [troughamp(cnum) troughTime(cnum)] = min(myAvSpk);
        if troughTime(cnum)<=5
            troughTime(cnum)=6;
        end
        pts= myAvSpk(troughTime(cnum)+[-5 0 5]); % voltage drop around 0.036ms of the peak?
        pts=pts(:);
        troughSD(cnum) = pts'*[1 -2 1]'; %SD of voltage around the peak
        amphalf = 0.5*min(myAvSpk);
        both=0;cnt=0;halfAmpTimes(cnum,:)=[0 0];
        % NP changed 14/02/2020 - recalculate the FWHM 
        [~,b1] = find(myAvSpk(1:troughTime(cnum))-amphalf<0,1,'first'); % width to the left of the negative peak at half max
        [~,b2] = find(myAvSpk(troughTime(cnum):end)-amphalf>0,1,'first'); % width to the left of the negative peak at half max
        b2 = b2 + troughTime(cnum);
        halfAmpTimes(cnum,:)=[b1 b2];
        clear b1 b2;        
        % NP - done (above)       
        
% SPIKE WIDTH AT HALF AMPLITUDE
        SpkWidthC(cnum) = diff(halfAmpTimes(cnum,:))*Sample2Msec;


        %dmyAvSpk = diff(myAvSpk);
        SpkPieceR = myAvSpk(troughTime(cnum):end);
        [rightmax(cnum) SpkWidthR(cnum)] = max(SpkPieceR); % this is the distance from the trough to the rise peak
        SpkWidthR(cnum)= SpkWidthR(cnum)*Sample2Msec;

        SpkPieceL = myAvSpk(1:troughTime(cnum));
        SpkPieceL = flipud(SpkPieceL(:)); % to look at the right time lag
        [leftmax(cnum) SpkWidthL(cnum)] = max(SpkPieceL); % this is the distance from the peak to the trough
        SpkWidthL(cnum)= SpkWidthL(cnum)*Sample2Msec;

        % troughTime = troughTime*Sample2Msec;
        if posSpk(cnum);	myAvSpk = -myAvSpk; end
        AvSpkAll(cnum,:) = myAvSpk;



% FIRING RATE
        myRes = Res(find(Clu==uClu(cnum)));        
        if length(myRes)<3
            FirRate(cnum)=0;
        else
            ISI = diff(myRes);
            MeanISI = mean(bootstrp(100,'mean',ISI));
            FirRate(cnum) = Par.SampleRate./MeanISI;
        end 

% BURSTINESS
        % computed outside the loop using the ACGs

% SPIKE BURST MEMBERSHIP
        [Burst{cnum}, BurstLen{cnum}, SpkPos{cnum}, OutOf{cnum}, FromBurst{cnum}] = ...
            SplitIntoBursts(Res(find(sp.clu==sp.cids(cnum))), 180);

        singles = sum(BurstLen{cnum}(find(BurstLen{cnum}==1)),1);
        sFraction(cnum) = singles/length(Burst{cnum});

        doubles = sum(BurstLen{cnum}(find(BurstLen{cnum}==2)),1);
        dFraction(cnum) = doubles/length(Burst{cnum});

        many = length(BurstLen{cnum}(find(BurstLen{cnum}>2)));
        mFraction(cnum) = many/length(Burst{cnum});

    end

%% CLUSTER METRICS FOR EACH CLUSTER WRT TO OTHER CLUSTERS NEAR THE ASSIGNED CHANNEL
% maskedClusterQuality and associated functions come from Steinmetz
    clear mySpk SpkNoise;
    try
        tic;
        [IDs, nq.eDist, nq.contaminationRate] = maskedClusterQuality(pwd);
        nq.refrac =  isiViolations(pwd)';
        %exclude noise, keep MUA and SUA
        IDs = IDs -1;
        [a,b]=intersect(IDs,uClu); % b is the indices into IDs we need to keep
        % now lets trim these metrics so that we only have MUA and SU, not Noise
        % b are the indices into IDs we need to keep
        IDs = IDs(b);
        nq.eDist = nq.eDist(b);
        nq.contaminationRate = nq.contaminationRate(b);
        nq.refrac = nq.refrac(b);
    catch
        warning('maskedClusterQuality or isiViolations crashed, check why');
        dbstop
        nq.eDist = zeros(max(uClu),1);
        nq.Refrac =  zeros(max(uClu),1);

    end


%% COLLATE ALL CLUSTER FEATURES INTO A SINGLE STRUCTURE
    nq.cids = uClu;
    %nq(el).SNR = snr;
    nq.burstiness = burstiness';
    nq.cluCh = cluCh';
    nq.spkWidthC = SpkWidthC';
    nq.spkWidthR = SpkWidthR';
    nq.spkWidthL = SpkWidthL';
    %fix for empty clusters
    SpkWidthL(SpkWidthL==0)=1000000;
    nq.troughTime = troughTime';
    nq.timeSym = SpkWidthR'./SpkWidthL';
    %nq.ElNum = repmat(el,nClu,1);
    %nq.Clus = uClu(:);
    nq.isPositive = posSpk';
    %nq(el).SpatLocal=SpatLocal';
    nq.fr = FirRate';
    nq.avSpk = cell2mat(avSpk');
    nq.sdSpk = cell2mat(sdSpk');
    nq.acg = ACG';
    nq.nSpikes = nSpikes;


    nq.rightMax= rightmax';
    nq.leftMax= leftmax';
    nq.centerMax= troughamp';

    rightmax(rightmax==0)=1e6;
    leftmax(leftmax==0)=1e6;
    nq.ampSym = (abs(rightmax)'-abs(leftmax)')./(abs(rightmax)'+abs(leftmax)');
    nq.troughSD = troughSD';
    % a couple of extra stuff for convenience
    nq.cluAnatGroup = cluAnatGroup';
    nq.cgs = sp.cgs'; % 0 is noise, 1 is MUA and 2 is SU
    %nq =CatStruct(nq);

    % nq.burst.cids = sp.cids;
    nq.burst_Idx = Burst';
    nq.burst_Len = BurstLen';
    nq.burst_sFraction = sFraction';
    nq.burst_dFraction = dFraction';
    nq.burst_mFraction = mFraction';
    nq.burst_SpkPos = SpkPos';
    nq.burst_OutOf = OutOf';
    nq.burst_FromBurst = FromBurst';
    nq = orderfields(nq);
    nq.SpkSamples = SpkSamples;
    nq.Sample2Msec = Sample2Msec;
    nq.ResCoef = ResCoef;
    nq.halfAmpTimes = halfAmpTimes; 
    % use this if you want a table (structure seems easier for now)
        %nq = struct2table(nq);
        % sort the variables in the table alphabetically
        %sortedNames = sort (nq.Properties.VariableNames(2:end));
        %nq = [nq(:,1), nq(:,sortedNames)];
        % sort structure
    nqLegend = {...
        'cids               : cluster ID (same as in phy)';...
        'refrac             : reftactory violations';...
        'burstiness         : mean spikes in 1.5-13.5ms vs 200-300 ms';...
        'cluCh              : channel with max spike amplitude';...
        'spkWidthC          : FWHM';...
        'spkWidthR          : time from trough to peak of spike';...
        'spkWidthL          : time from peak of spike to trough';...
        'troughTime         : for rescaling the X-axis so that trough is at 0';...
        'timeSym            : spike symmetry SpkWidthR/SpkWidthL';...
        'isPositive         : spike polarity (negative is standard)';...
        'fr                 : firing rate';...
        'avSpk              : average spike waveform';...
        'sdSpk              : stdev of spike waveform';...
        'acg                : cluster autocorrelogram';...
        'leftMax            : max amp on left of peak';...
        'rightMax           : max amp on right of peak';...
        'centerMax          : max amp on ????';...
        'ampSym             : similarity of max before and after spike peak';...
        'troughSD           : ???';...
        'cluAnatGroup       : shank index of cluster';...
        'cgs                : cluster group (0:noise, 1:MUA and 2:SUA)';...
        'burst_Idx          : index of burst event in Res';...
        'burst_Len          : n of spikes in burst';...
        'burst_sFraction    : fraction of bursts with ONE spike in them'
        'burst_dFraction    : fraction of bursts with TWO spike in them';...
        'burst_mFraction    : fraction of bursts with T|HREE OR MORE spikes in them';...
        'burst_SpkPos       : spike''s position in burst';...
        'burst_OutOf        : the burst''s length that this spike came from';...
        'nSpikes            : number of spikes in cluster';...
        'burst_FromBurst    : the index of the burst this spike came from';};
    nqLegend = [nqLegend(1);sort(nqLegend(2:end))];

%% SAVE IT ALLFOR LATER
    save([fileBase '.nq.mat'],'nq','nqLegend','ResCoef');
    
    
%% IFPLOT
    if Display
        
        str = {'MUA','SUA'};
        for i = 1:2 % MUA and SUA
            figure;
            cells = find(nq.cgs == i);
            for j = 1:length(cells)
                subplotfit(j,length(cells));
                shift = nq.troughTime(cells(j));%*SpkSamples/2*Sample2Msec;
                wv_tmp   = resample(nq.avSpk(cells(j),:),nq.ResCoef,1);
                wv_tmpSD = resample(nq.sdSpk(cells(j),:),nq.ResCoef,1);
                if nq.isPositive(cells(j)); 
                    cl = 'b'; 
                    ml = -1; % display('ha!!');
                else
                    ml = 1;
                    cl = 'k'; 
                end
                shadedErrorBar(([1:nq.SpkSamples*nq.ResCoef]-shift)*nq.Sample2Msec,ml*wv_tmp(1:520),wv_tmpSD(1:520),cl);
                axis tight
                hold on
                Lines(0,[],'g');%trough line
                %Lines(halfAmpTimes*Sample2Msec-shift,amphalf,'r');
                plot((nq.halfAmpTimes(cells(j),:)-shift)*nq.Sample2Msec,repmat([0.5*nq.centerMax(cells(j))],1,2),'or');
                Lines(nq.spkWidthR(cells(j)),[],'r');
                Lines(-nq.spkWidthL(cells(j)),[],'r');
                %Lines([-SpkWidthL SpkWidthR], troughamp,'r');
                mystr1 = sprintf(['clu%d, sh%d'],nq.cids(cells(j)),nq.cluAnatGroup(cells(j)));
                mystr2 = sprintf(['%0.1fHz, w%0.2fms'], nq.fr(cells(j)), nq.spkWidthC(cells(j)));
                %title(mystr);
                text(max(xlim),.6*min(ylim),mystr1,'HorizontalAlignment','right');
                text(max(xlim),.9*min(ylim),mystr2,'HorizontalAlignment','right');
                set(gcf,'units','normalized','outerposition',[0 0 1 1]);                
            end
            mtit(str{i});
            print(gcf,[str{i},'_waveforms_all.jpg'],'-djpeg','-r300');            
        end
    end    
    
    
display(['Done. MUA and SUA cluster properties were computed and saved in ',fileBase '.nq.mat']);
display(['MUA figure saved: ',str{1},'_waveforms_all.jpg']);
display(['SUA figure saved: ',str{2},'_waveforms_all.jpg']);
close all;

%% SOME REJECTED CODE
%         %width
% 
%          		halfAmpTimes = LocalMinima(abs(myAvSpk-amphalf));%,5,0.5*amphalf);
%          		halfAmpTimes = halfAmpTimes(find(halfAmpTimes-troughTime)<0;
%          		if length(halfAmpTimes>2)
%          			val = myAvSpk(halfAmpTimes);
%          			[dummy ind] = sort(val);
%          			halfAmpTimes = halfAmpTimes(ind(1:2));
%          		end
%          		SpkWidthC(cnum) = abs(diff(halfAmpTimes))*Sample2Msec; % this is width on the hald amplitude

        % REMOVED AS IT LOOKS TO ALWAYS DEFAULT TO 520
        %         while both<2
        %             if cnt<troughTime
        %                 if myAvSpk(troughTime-cnt)>amphalf & halfAmpTimes(1)==0
        %                     halfAmpTimes(1)=troughTime-cnt;
        %                     both=both+1;
        %                 end
        %             else
        %                 halfAmpTimes(1)=1;
        %                 both=both+1;
        %             end
        % 
        %             if cnt+troughTime>520 && cnt+troughTime<=length(myAvSpk)
        %                 if myAvSpk(troughTime+cnt)>amphalf & halfAmpTimes(2)==0
        %                     halfAmpTimes(2)=troughTime+cnt;
        %                     both=both+1;
        %                 end
        %             else
        %                 halfAmpTimes(2)=520;
        %                 both=both+1;
        %             end
        %             cnt=cnt+1;
        % 
        %         end