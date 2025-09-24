function GetCluResFromNPY(FileBase)
warning('for now I am putting all clusters independent of shank or anatomical origin into one clu/res file group')
pth = getfullpath(FileBase);

spktimes = readNPY(fullfile(pth,'spike_times.npy'));
clu = readNPY(fullfile(pth,'spike_clusters.npy'));
uclu = unique(clu);
nclu = max(uclu);

%clu
fid=fopen(fullfile(pth,[FileBase '.clu.1']),'w');
fprintf(fid,'%.0f\n',nclu);
fprintf(fid,'%.0f\n',clu);
fclose(fid);
clear fid

%res
fid=fopen(fullfile(pth,[FileBase '.res.1']),'w');
fprintf(fid,'%.0f\n',spktimes);
fclose(fid);
clear fid

end
