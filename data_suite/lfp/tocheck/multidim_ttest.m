% Running a ttest on a 3d matrix, along the 1st dimension.
% Initially made to be used for the 3d coherogram
function result = multidim_ttest(a,b)
result = [];
for c=1:size(a,1)
    result(c,:) = ttest2(squeeze(a(c,:,:))',squeeze(b(c,:,:))');
end;