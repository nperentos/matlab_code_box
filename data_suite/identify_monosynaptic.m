%% x-corrs
out = [];
for k1 = 1:5%:length(unit_spikes);
    tic;
    for k2 = 1:length(unit_spikes);
        tmp=run_ccg(unit_spikes{k1},unit_spikes{k2},0.001, 0.01, sr, 'scale');
        out(:,k1,k2) = squeeze(tmp(:,1,2));
    end
    toc;
end
%fig; jplot(out(:,1,2));
%%
% tmp1 = mean(out,1); tmp2 = mean(out(12:15,:,:),1); tmp3 = squeeze(tmp2 - tmp1);
% for c=1:size(tmp3,1); tmp3(c,c) = NaN; end;
% [~,idx]=sort(tmp3(:));
% [ind1,ind2]=ind2sub(size(tmp3),idx(1:10));