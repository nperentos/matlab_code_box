function quality = CellQualitySummary(FileBase)
% function burst = SplitClustersIntoBursts(pth)
%
% Note: it doesn't compute anything for the clusters that have been marked
%       as 'noise' in Kilosort
%
% Thresh is 180 samples (6ms at 30kHz)
%
% OUTPUT
% burst.cids        Cluster index
% burst.Burst       Returns the index within Res of the event
% burst.BurstLen    Number of spikes present in the burst
% burst.sFraction   Fraction of 'bursts' composed only by a single spike
% burst.dFraction   Fraction of bursts composed only by two spike
% burst.mFraction   Fraction of 'bursts' composed by three or more spikes
% burst.SpkPos      SpkPos returns a number for each spike, giving the
%                   position within the burst of the spike
% burst.OutOf       returns the length of the burst which a given spike
%                   belongs to
% burst.FromBurst   gives and index of a Burst from which a spike comes
%
% Elena Itzcovich 2019


%cd(pth)

cd(getfullpath(FileBase))
pth = pwd;
sp = loadKSdir(pth);

load([FileBase,'.NeuronQualityKilosort.mat'])
load([FileBase '.SplitClustersIntoBursts.mat'])
%load([CurrentFileBase '.FiringRatePeriods.RUN.mat'])
load([FileBase '.ComputeBurstiness.mat'])


% CA1pyrCH = LoadMyPar(CurrentFileBase, 'CA1pyrCH');



for i=1:length(burst.cids)
    
    Clu = burst.cids(i);
    
    nqIndex = find(nq.cids==Clu);
    if ~isempty(nq.Clus(nqIndex))
        quality(i).cids = nq.Clus(nqIndex);
        quality(i).FileBase = FileBase;
        quality(i).cluCh = nq.cluCh(nqIndex);
        quality(i).depth = nq.cluCh(nqIndex) ;%- CA1pyrCH;
        
        quality(i).eDist = nq.eDist(nqIndex);
        quality(i).Refrac = nq.Refrac(nqIndex);
        %     quality(i).SNR = nq.SNR(nqIndex);
        quality(i).SpkWidthC = nq.SpkWidthC(nqIndex);
        quality(i).SpkWidthR = nq.SpkWidthR(nqIndex);
        quality(i).SpkWidthL = nq.SpkWidthL(nqIndex);
        
        quality(i).TimeSym = nq.TimeSym(nqIndex);
        quality(i).ElNum = nq.ElNum(nqIndex);
        
        quality(i).IsPositive = nq.IsPositive(nqIndex);
        %     quality(i).SpatLocal = nq.SpatLocal(nqIndex);
        quality(i).FirRate = nq.FirRate(nqIndex);
        % quality(i).FirRateRUN = fr.fr(nqIndex);
        quality(i).AvSpk = nq.AvSpk(nqIndex,:);
        quality(i).RightMax = nq.RightMax(nqIndex);
        quality(i).LeftMax = nq.LeftMax(nqIndex);
        quality(i).CenterMax = nq.CenterMax(nqIndex);
        quality(i).sFraction = burst.sFraction(i);
        quality(i).mFraction = burst.mFraction(i);
        
        %fix for empty clusters
        quality(i).AmpSym = nq.AmpSym(nqIndex);
        quality(i).troughSD = nq.troughSD(nqIndex);
        quality(i).ACG = nq.ACG(nqIndex,:);
        quality(i).cgs = sp.cgs(i)
        quality(i).burstiness = burstiness.Burstiness(find(burstiness.cids==Clu));
    end
end

% quality.cids = sp.cids;




cd(pth)
save([FileBase '.' mfilename '.mat'],'quality');

end