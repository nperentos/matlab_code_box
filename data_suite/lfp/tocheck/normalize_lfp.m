% Updated : 24/12/2013 (NK) : to work with matrices of lfps

function lfp=normalize_lfp(lfp)
lfp = (lfp-repmat(mean(lfp,2),1,size(lfp,2)))./repmat(std(lfp,0,2),1,size(lfp,2));