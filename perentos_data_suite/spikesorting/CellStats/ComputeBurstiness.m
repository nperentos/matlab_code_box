function ComputeBurstiness(FileBase)
%Inspired by Senza & Buszaki 2018
%
%By Elena Itzcovich 01.01.2020

Par = LoadXml([FileBase '.xml']);
[Res Clu]=LoadCluRes(FileBase,[],[],1);

uClu = unique(Clu);
nClu = length(uClu);

[ccg tbin ] = CCG(Res,Clu+1, round(1*Par.SampleRate/1000), 300, Par.SampleRate,uClu+1,'hz');
acg= MatDiag(ccg);

% figure;
% bar(tbin,acg(:,2));

for i = 1:nClu
    N = mean(acg(3:5,i));
    D = mean(acg(200:300,i));
    burstiness.cids(i) = uClu(i);
    burstiness.Burstiness(i) = N/D;
end

save([FileBase '.' mfilename '.mat'],'burstiness');

end