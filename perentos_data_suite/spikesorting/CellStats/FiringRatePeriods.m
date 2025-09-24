function fr = FiringRatePeriods(FileBase)
%function fr = FiringRatePeriods(FileBase, Period)
%
%OUTPUT:
% fr.clu    Number of the clusters
% fr.fr     Average firing Rate during Period
par = LoadXml([CurrentFileBase '.xml']);


Period = 'RUN';
Range = loadrangefiles([FileBase '.sts.' Period]);

[Res,Clu]=LoadCluRes(FileBase, [],[],1);

uClu = unique(Clu);
nClu = length(uClu);

for cnum=1:nClu
    
    myClu=find(Clu==uClu(cnum));
    myRes = Res(find(Clu==uClu(cnum)));
    
    [y, ind] = SelectPeriods(myRes,Range,'d',1, 0);
    
    SamplesRunning = sum(diff(Range'));
    SamplesFiringRate = length(y)/SamplesRunning;
    
    FireRate(cnum) = SamplesFiringRate*par.SampleRate;
    
end

fr.clu = uClu;
fr.fr = FireRate';
save([FileBase '.FiringRatePeriods.' Period '.mat'],'fr');

end