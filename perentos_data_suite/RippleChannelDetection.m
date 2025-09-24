function out =  RippleChannelDetection(FileBase,varargin)
% written by Anton for Natalias Masters thesis using Nikolas data.
% detects peak ripple band power across electrode space (for each
% anatomical group) and also gives the relative position of each electrode
% from the purported pyramidal layer
% NP added reference channel discovery by moving above CA1 channel till
% reach zero slope of ripple power drop from CA1 channel

[fMode] =DefaultArgs(varargin, {'compute'});
goto(FileBase);
%FileBase =  'NP42_2019-12-12_14-34-31';
switch fMode
    case 'compute'
        
        Par = LoadXml([FileBase '.xml']);
        
        T = getCarouselDataBase;
        SessId = find(strcmp(T.session, FileBase));
        KS_Config = load(['/storage2/perentos/code/thirdParty/KS/myKSortSettings/configFiles/' FileBase '_KSMap.mat']);
        
        ShankGroups = [];
        MyChannels =[];
        for s=1:length(Par.AnatGrps)
            if length(Par.AnatGrps(s).Channels)>10
                ShankGroups(end+1,1) = s;
                gch = ~Par.AnatGrps(s).Skip(:);
                MyChannels = [MyChannels ; Par.AnatGrps(s).Channels(gch)'+1];
                MyChannelsByShank{s} = Par.AnatGrps(s).Channels(gch)'+1;
            end
        end
        
        Map = SiliconMap(Par,ShankGroups);
        %$FileLength([FileBase '.lfp'])
        load('behavior.mat');
        MyVarNames = {'resp_raw_fr', 'pupil_area','runSpeed','theta_raw_amp'};
        for s=1:length(MyVarNames)
            sVar(s) = find(strcmp(name, MyVarNames{s}));
        end
        %sVar = find(ismember(name,MyVarNames));
        
        % %%
        % figure(33);clf
        % for k=1:3
        %     for l=k+1:4
        %         subplot2(3,3,k,l-1);
        %         cmat =RemoveOutliers(data(:,sVar([k l])),[1 99]');
        %        %%%%%%  cmat(:,2) = randsample(cmat(:,2),size(cmat,1));
        %       %%% randomization
        %         hist2(cmat,30,30,[],'log','mud');
        %         xlabel(MyVarNames{k});
        %         ylabel(MyVarNames{l});
        %
        %        % title([MyVarNames{k} ' - ' MyVarNames{l}]);
        %     end
        % end
        ImmSamples = ((data(:,sVar(3))<5))+1;
        ImmPeriods = ThreshCross(ImmSamples, 1.5, 1250);
        
        ImmId = WithinRanges([1:size(data,1)],ImmPeriods);
        
        Lfp = LoadBinary([FileBase '.lfp'], MyChannels, Par.nChannels,[],[],[],ImmPeriods)';
        wLfp = WhitenSignal(Lfp);
        for c=1:length(MyChannels)
            [out.y(:,c), out.f] = mtchd(wLfp(:,c), 2^9, Par.lfpSampleRate,2^8,[],1,'linear',[],[30 240]); % reverts to spectrum for single time series
        end
        
        %%
        
        %%
        ZScPow = zscore(log10(out.y));
        RipFreq = out.f>120 & out.f<180;
        OutsideRipFreq  = out.f>80 & out.f<120 | out.f>180;
        RipPow = mean(ZScPow(RipFreq,:));%./mean(ZScPow(OutsideRipFreq,:));
        out.RipPow = [];
        
        for s=1:length(ShankGroups)
            myRipPow =RipPow(ismember(MyChannels, MyChannelsByShank{s}));
            [maxpow, maxch] = max(myRipPow);
            out.CA1_Chan(s) = MyChannelsByShank{s}(maxch);
            out.CA1_Chan
            out.ShankStep(s) = min(diff(KS_Config.ycoords(MyChannelsByShank{s})));
            out.RipPow = [out.RipPow, myRipPow];
        end
        out.Map = Map; 
        out.MyChannelsByShank = MyChannelsByShank;
        
        allCh = [];
        for i = 1:length(out.CA1_Chan)
            allCh = [allCh; out.MyChannelsByShank{i}];
        end
        % find channel above CA1 where ripple band drops below 0.2 of CA1
        % chan. If CA1 is too close to top of probe, then this could fail
        for i = 1:length(out.CA1_Chan)
            %refsig(i) = find(diff(out.RipPow(MyChannelsByShank{i}(1):out.CA1_Chan(i)))<0,1,'last');
            % tst = abs(min(0,min(out.RipPow(MyChannelsByShank{i}(1):MyChannelsByShank{i}(find(MyChannelsByShank{i}==out.CA1_Chan(i))) )))) ...
            % + out.RipPow(MyChannelsByShank{i}(1):MyChannelsByShank{i}(find(MyChannelsByShank{i}==out.CA1_Chan(i))));
            ia = find(allCh == MyChannelsByShank{i}(1));
            ib = find(allCh == out.CA1_Chan(i));
            tst = abs(min(0,min(out.RipPow(ia:ib)))) ...
                + out.RipPow(ia:ib);
            
            refsig(i) = MyChannelsByShank{i}(find(tst<0.2*tst(end),1,'last'));
            %refsig(i) = allCh(refsig(i));
        end
        out.refsig = refsig;
        
        save([FileBase '.' mfilename '.mat'],'out');
    case 'display'
        load([FileBase '.' mfilename '.mat']);
        figure;
        Chs =[];
        for s=1:length(out.MyChannelsByShank)
            Chs= [Chs; out.MyChannelsByShank{s}];
        end
        pcolor(out.f,Chs, zscore(log10(out.y))'); shading flat; axis ij
        hold on
        Lines([],out.CA1_Chan,'k');
        
    case 'cells_depth'
         load([FileBase '.' mfilename '.mat']);
         KS_Config = load(['/storage2/perentos/code/thirdParty/KS/myKSortSettings/configFiles/' FileBase '_KSMap.mat']);
         load([FileBase '.tun1.mat']);
         if max(KS_Config.kcoords(1:size(out.Map.Coord,1)))> length(out.CA1_Chan)
            tun1.cluDist2CA1 = (tun1.cluCh(:) - out.CA1_Chan).*abs(out.ShankStep);
         else   
             Ca1ch = out.CA1_Chan(tun1.shank);
             Step = abs(out.ShankStep(tun1.shank(:)));
            tun1.cluDist2CA1 = (tun1.cluCh(:) - Ca1ch(:)).*Step(:);
         end
         save([FileBase '.tun1.mat'],'tun1');
end