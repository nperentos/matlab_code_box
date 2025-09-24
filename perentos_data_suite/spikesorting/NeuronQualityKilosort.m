function nq = NeuronQualityKilosort(FileBase, varargin)
%function NeuronQuality(FileBase, Electrodes,Display,Batch,Overwrite)


% lets move to the folder of interest (requires less mods of thi script)
cd(getfullpath(FileBase));

Par = LoadXml([FileBase '.xml']);

[SpkSamples, Channels, Electrodes,Display,Batch,Overwrite] = DefaultArgs(varargin,{52, [1:64],1,0,0,0});

% to find the channels of interest go to the map file you fed into KS. It
% has anatomical groups as well as kcoords that define which channels
% are used for spike extraction/sorting
pth_to_KS_maps = '/storage2/perentos/code/thirdParty/KS/myKSortSettings/configFiles';
fle = fullfile(pth_to_KS_maps,[FileBase,'_KSMap.mat']);
if exist(fle)
    tmp = load(fle);
end
Channels = tmp.chanMap(tmp.connected); % the channels the user passed to KS as connected
% note that from temp you can also add anatomical groups if at the end up
% we need them
sp = loadKSdir(pwd);
Chm=double(readNPY('channel_map.npy')); % the channels KS chose to use



nq =struct([]);


% if FileExists([FileBase '.' mfilename '.mat']) & ~Overwrite
%     return;
% end

SampleRate = Par.SampleRate;

GoodElectrodes=[];

for el=Electrodes
    if ~FileExists([FileBase '.clu.' num2str(el)]) continue; end
    Clu = LoadClu([FileBase '.clu.' num2str(el)]);
    if max(Clu) > 1
        GoodElectrodes = [GoodElectrodes, el];
    end

end

for el=GoodElectrodes

    [Res Clu]=LoadCluRes(FileBase,[],[],1);
    
    uClu = unique(Clu);
    nClu = length(uClu);
    
    SampleSize = 1000;
    
    avSpk =[]; stdSpk = [];SpatLocal=[];SpkWidthC=[];SpkWidthL=[];SpkWidthR=[];posSpk=[];FirRate = [];AvSpkAll=[];
    leftmax=[]; rightmax=[];troughamp=[];troughSD=[];

    
    [ccg tbin ] = CCG(Res,Clu+1, round(0.5*Par.SampleRate/1000), 30, Par.SampleRate,uClu+1,'hz');
    ACG= MatDiag(ccg);
    
    [avSpk cluCh] = GetChannelWaveformNoisy(FileBase, pwd, Channels);
    
    for cnum=1:length(uClu)
        % get spike waveshapes and compute SNR
        
        
        SampleSize = 1000;
        myClu=find(Clu==uClu(cnum));
        
        if 1 %length(myClu)>0
            SampleSize = min(length(myClu),SampleSize);
            RndSample = sort(myClu(randsample(length(myClu),SampleSize)));
            
            %find the channel of largest amp (positive or negative)
            [amps ampch] = max(abs(avSpk{cnum}),[],2);
            [dummy maxampch] = max(sq(amps));
            nch = length(Channels);
            nonmax = setdiff([1:nch],maxampch);
            
            myAvSpk = avSpk{cnum};%sq(avSpk(maxampch,:,cnum)); % largest channel spike wave for that cluster
            
            %now we need to take care of the positive spikes (we reverse them)
            minamp  = abs(min(myAvSpk));
            maxamp  = max(myAvSpk);
            %        if (minamp-maxamp)/minamp < 0.05 %(spike is more positive then negative)
            if maxamp>1.2*minamp %(spike is more positive then        negative)
                myAvSpk = -myAvSpk; %reverse the spike
                posSpk(cnum) = 1;
            else
                posSpk(cnum) = 0;
            end
            
            %now let's upsample the spike waveform
            ResCoef = 10; %                                                                 WAS CHANGED ON Aug.30 2005!!!!!!!!!!
            Sample2Msec = 1000./SampleRate/ResCoef; %to get fromnew samplerate to the msec
            myAvSpk = resample(myAvSpk,ResCoef,1);
            %keyboard
            %amphalf = mean(myAvSpk)-0.5*abs(min(myAvSpk-mean(myAvSpk)));
            
            [troughamp(cnum) troughTime] = min(myAvSpk);
            if troughTime<=5
                troughTime=6;
            end
            pts= myAvSpk(troughTime+[-5 0 5]);
            pts=pts(:);
            troughSD(cnum) = pts'*[1 -2 1]';
            amphalf = 0.5*min(myAvSpk);
            both=0;cnt=0;halfAmpTimes=[0 0];
            while both<2
                if cnt<troughTime
                    if myAvSpk(troughTime-cnt)>amphalf & halfAmpTimes(1)==0
                        halfAmpTimes(1)=troughTime-cnt;
                        both=both+1;
                    end
                else
                    halfAmpTimes(1)=1;
                    both=both+1;
                end
                
                if cnt+troughTime>520 && cnt+troughTime<=length(myAvSpk)
                    if myAvSpk(troughTime+cnt)>amphalf & halfAmpTimes(2)==0
                        halfAmpTimes(2)=troughTime+cnt;
                        both=both+1;
                    end
                else
                    halfAmpTimes(2)=520;
                    both=both+1;
                end
                cnt=cnt+1;
                
            end
            %width
            
            %  		halfAmpTimes = LocalMinima(abs(myAvSpk-amphalf));%,5,0.5*amphalf);
            %  		halfAmpTimes = halfAmpTimes(find(halfAmpTimes-troughTime)<0.
            %  		if length(halfAmpTimes>2)
            %  			val = myAvSpk(halfAmpTimes);
            %  			[dummy ind] = sort(val);
            %  			halfAmpTimes = halfAmpTimes(ind(1:2));
            %  		end
            %  		SpkWidthC(cnum) = abs(diff(halfAmpTimes))*Sample2Msec; % this is width on the hald amplitude
            %
            SpkWidthC(cnum) = diff(halfAmpTimes)*Sample2Msec;
            
            
            %dmyAvSpk = diff(myAvSpk);
            SpkPieceR = myAvSpk(troughTime:end);
            [rightmax(cnum) SpkWidthR(cnum)] = max(SpkPieceR); % this is the distance from the trough to the rise peak
            SpkWidthR(cnum)= SpkWidthR(cnum)*Sample2Msec;
            
            SpkPieceL = myAvSpk(1:troughTime);
            SpkPieceL = flipud(SpkPieceL(:)); % to look at the right time lag
            [leftmax(cnum) SpkWidthL(cnum)] = max(SpkPieceL); % this is the distance from the peak to the trough
            SpkWidthL(cnum)= SpkWidthL(cnum)*Sample2Msec;
            
            troughTime = troughTime*Sample2Msec;
            if posSpk(cnum);	myAvSpk = -myAvSpk; end
            AvSpkAll(cnum,:) = myAvSpk;
            
            if Display
                figure(765)
                if cnum==2
                    clf;
                end
                subplotfit(cnum-1,max(uClu));
                shift = troughTime;%SpkSamples/2*Sample2Msec;
                plot([1:SpkSamples*ResCoef]*Sample2Msec-shift,myAvSpk);
                axis tight
                hold on
                Lines(0,[],'g');%trough line
                Lines(halfAmpTimes*Sample2Msec-shift,amphalf,'r');
                Lines(SpkWidthR(cnum),[],'r');
                Lines(-SpkWidthL(cnum),[],'r');
                %Lines([-SpkWidthL SpkWidthR], troughamp,'r');
                mystr = sprintf('El=%d Clu=%d',el,cnum);
                title(mystr);
            end
            %keyboard
        end
        % firing rate
        myRes = Res(find(Clu==cnum-1));
        if length(myRes)<3
            FirRate(cnum)=0;
        else
            ISI = diff(myRes);
            MeanISI = mean(bootstrp(100,'mean',ISI));
            FirRate(cnum) = SampleRate./MeanISI;
        end
        
        
    end
    
    if Display
        if ~Batch
            pause
        else
            reportfig(gcf,'NeuronQuality',0,[FileBase ',El=' num2str(el)],70);
        end
        figure(765); clf
    end
    
    %     snr = sq(mean(mean(abs(avSpk),1),2))./mean(stdSpkNoise(:));
    %		Out = [CluNo, eDist, bRat,Refrac]
    
    clear mySpk SpkNoise Res Clu;
    try
        
        [IDs, nq(el).eDist, nq(el).contaminationRate] = maskedClusterQuality(pwd);
        nq(el).Refrac =  isiViolations(pwd)';
    catch
        warning('maskedClusterQuality or isiViolations crashed, check why');
        dbstop
        nq(el).eDist = zeros(max(uClu),1);
        nq(el).Refrac =  zeros(max(uClu),1);
        
    end
    
    nq(el).cids = uClu;
    %nq(el).SNR = snr;
    nq(el).cluCh = cluCh';
    nq(el).SpkWidthC = SpkWidthC';
    nq(el).SpkWidthR = SpkWidthR';
    nq(el).SpkWidthL = SpkWidthL';
    %fix for empty clusters
    SpkWidthL(SpkWidthL==0)=1000000;
    nq(el).TimeSym = SpkWidthR'./SpkWidthL';
    nq(el).ElNum = repmat(el,nClu,1);
    nq(el).Clus = uClu(:);
    nq(el).IsPositive = posSpk';
    %nq(el).SpatLocal=SpatLocal';
    nq(el).FirRate = FirRate';
    nq(el).AvSpk = cell2mat(avSpk');
    nq(el).ACG = ACG';
    
    
    nq(el).RightMax= rightmax';
    nq(el).LeftMax= leftmax';
    nq(el).CenterMax= troughamp';
    
    rightmax(rightmax==0)=1e6;
    leftmax(leftmax==0)=1e6;
    nq(el).AmpSym = (abs(rightmax)'-abs(leftmax)')./(abs(rightmax)'+abs(leftmax)');
    nq(el).troughSD = troughSD';
    
    
    nq =CatStruct(nq);
    display('saving...');
    save([FileBase '.' mfilename '.mat'],'nq');
    display(['saved ', FileBase '.' mfilename '.mat']);
end


%save([FileBase '.nq'],'nq');
