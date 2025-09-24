%function OutArgs = UnitsThetaModulation(FileBase,fMode,States, RefCh)

function OutArgs = UnitsThetaModulationSpeed(FileBase,varargin)
%
[fMode, State, RefCh ] = DefaultArgs(varargin,{'compute','RUN', 'ThetaParams_Theta'});
% FileBase = cdir;
Par = LoadXml([FileBase '.xml']);

switch fMode
    case 'compute'
        
        FileIn = sprintf('%s.spd', FileBase);
        if exist(FileIn, 'file')
            fprintf('Loading animal speed from %s ...', FileIn)
            spd0 = load(FileIn);
            spd0 = spd0(:,1);
            fprintf('DONE\n')
        else
            fprintf('WARNING: File with animal speed %s not found! Speed-related analysis is SKIPPED. \n', FileIn)
        end
        
        MotorSamplingRate = LoadMyPar(FileBase, 'ProcessTheta_MotorSamplingRate');
        lfpSampleRate = Par.lfpSampleRate;
        

        
        if isstr(RefCh) % otherwise it's already channel numnber.
            RefCh = LoadMyPar(FileBase, RefCh);
        end
        
        % load spikes
        [Res,Clu] = LoadCluRes(FileBase,1,[],1);
        
        if ~FileExists([FileBase '.sts.' State])
            out = [];
            return;
        end
        Periods = load([FileBase '.sts.' State]);
        
        if isempty(Periods)
            out = [];
            return;
        end
        
        load([FileBase '.ThetaParams.mat']);
        load([FileBase '.CellQualitySummary.mat']);
        quality_cat = CatStruct(quality);
        
        % resample
        ResLfp = round(Res*Par.lfpSampleRate/Par.SampleRate);
        
        GoodCluInd = ismember(Clu, quality_cat.cids);
        In = logical(WithinRanges(ResLfp, Periods));
        
        GoodClu = Clu(GoodCluInd & In);
        
        uClu = unique(GoodClu);
        nClu = max(uClu);
        
        % compute acg
        % [ccg tbin ] = CCG(Res,Clu, round(0.5*Par.SampleRate/1000), 30, Par.SampleRate,quality.cids,'hz');
        % acg= MatDiag(ccg);
        
        Params.State = State;
        Params.FileBase = FileBase;
        Params.RefCh = RefCh;
        
        
        j = 1;
        
        for i = 1:length(uClu)
            
            
            
            %todo select the ones from the i-cluster
            
            myCluInd = ismember(Clu, quality_cat.cids(i));
            
            myClu = Clu(myCluInd & In);
            myResLfp = ResLfp(myCluInd & In);
            
            rt = RayleighTest(ThPh(myResLfp), ones(length(myResLfp),1));
            
            ppc = PPC(ThPh(myResLfp));
            
            
            if isstruct(rt)
                
                out(j).FileBase = quality(j).FileBase;
                out(j).cids = quality(j).cids;
                [out(j).hist.cnt out(j).hist.bins] = hist([ThPh(myResLfp); ThPh(myResLfp)+2*pi],36);
                out(j).quality = quality(find(quality_cat.cids==uClu(i)));
                out(j).rt = rt;
                out(j).ppc = ppc;
                
                j = j+1;
            end
            
            
        end
        %             [out(i).hist.cnt out(i).hist.bins] = hist2([ThPh(ResLfp(In)), Clu(In); ThPh(ResLfp(In))+2*pi, Clu(In)],36,nClu);
        

        %OutArgs = out;
        %out = CatStruct(out);
        save([FileBase '.' mfilename '.' State '.mat'],'out', 'Params');
        
    case 'display'
        %%todo.
        load([FileBase '.' mfilename '.' State '.mat']);
        
        
        figure(991);clf
        for s=1:length(out)
            
            scatter(out(s).rt.th0*180/pi, out(s).quality.depth, 20, out(s).rt.logZ,'filled');
            hold on;
            scatter(out(s).rt.th0*180/pi+360, out(s).quality.depth, 20, out(s).rt.logZ,'filled');
            hold on;
        end
        
        set(gca,'XTick',[-180:90:540]);
        axis ij
        ylabel('depth'); xlabel('phase');
        hcb = colorbar;
        title(['FileBase: ' out(1).quality.FileBase]);
        title(hcb, 'Strength of Modulation')
        
        figure(992);clf
        suptitle(out(1).quality.FileBase)
        for s=1:length(out)
            subplotfit(s, length(out));
            bar(out(s).hist.bins, out(s).hist.cnt); axis tight
            grid on;
            set(gca,'XTick',[-180:90:540]);
            title(['dpt: ' num2str(out(s).quality.depth) ' Clu: ' num2str(out(s).quality.cids)]);
        end
                
        
        
        
        
        
    case 'group'
        
        OutArgs = load([FileBase '.' mfilename '.' State '.mat'],'out');
        
        %         OutArgs.rt = lout.out.rt;
        %         if size(lout.out.quality.depth,2)==1
        %             OutArgs.rt.qt = lout.out.quality.depth;
        %         else
        %             OutArgs.rt.qt = lout.out.quality.depth(2,:)';
        %
        %         end
        %         OutArgs.rt.SpkWidthR = lout.out.quality.SpkWidthR;
        %         OutArgs.rt.eDist = lout.out.quality.eDist;
        %         OutArgs = OutArgs.rt;
end
