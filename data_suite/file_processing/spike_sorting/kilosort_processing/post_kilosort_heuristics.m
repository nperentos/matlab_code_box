%%
autoccgs = [];
for c=1:length(clusters.id)
    tmp1 = clusters.spikes{c};
    tmp = run_ccg(tmp1,tmp1,0.001,0.5,30000);
    autoccgs(c,:) = tmp(:,1,2);
end

%% Count spikes in refractory period
s = (size(autoccgs,2)-1)/2;
s = [s-2:s s+2:s+4];

cluster_qual = sum(autoccgs(:,s),2)./sum(autoccgs(:,[1:s s+2:end]),2);
%%