function burst = SplitClustersIntoBursts(FileBase)
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

pth = pwd;

[Res] = LoadRes([FileBase '.res.1']);

sp = loadKSdir(pth);
sp.res = Res;


for i=1:length(sp.cids)
    [Burst{i}, BurstLen{i}, SpkPos{i}, OutOf{i}, FromBurst{i}] = ...
        SplitIntoBursts(sp.res(find(sp.clu==sp.cids(i))), 180);
    
    singles = sum(BurstLen{i}(find(BurstLen{i}==1)),1);
    sFraction(i) = singles/length(Burst{i});
    
    doubles = sum(BurstLen{i}(find(BurstLen{i}==2)),1);
    dFraction(i) = doubles/length(Burst{i});
    
    many = length(BurstLen{i}(find(BurstLen{i}>2)));
    mFraction(i) = many/length(Burst{i});
     
    
end




burst.cids = sp.cids;
burst.Burst = Burst;
burst.BurstLen = BurstLen;
burst.sFraction = sFraction;
burst.dFraction = dFraction;
burst.mFraction = mFraction;
burst.SpkPos = SpkPos;
burst.OutOf = OutOf;
burst.FromBurst = FromBurst;



cd(pth)
save([FileBase '.' mfilename '.mat'],'burst');

end