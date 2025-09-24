
FileBase = CurrentFileBase;

[Res Clu]=LoadCluRes(FileBase,[],[],1);
Par = LoadXml([FileBase '.xml']);

uClu = unique(Clu);
nClu = length(uClu);

[ccg tbin ] = CCG(Res,Clu+1, round(0.5*Par.SampleRate/1000), 30, Par.SampleRate,uClu+1,'scale');


%%

A = sq(ccg(31,:,:));

figure;
imagesc(A);
colorbar
caxis([0 100])

%%
[ccgCount tbin ] = CCG(Res,Clu+1, round(0.5*Par.SampleRate/1000), 30, Par.SampleRate,uClu+1,'count');

ccgSum = sum(ccgCount,1);
%%
figure;
imagesc(sq(ccgSum));
colorbar


