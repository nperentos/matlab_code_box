function [csd,z] = trig_csd(lfp,pos,method,sr,stdmm);
varargin
for c=1:size(lfp,3);
    [tmp, z] = inverseCSD(squeeze(lfp(:,:,c)),pos,method,sr,stdmm);
    if c==1;
        csd=zeros([size(tmp) size(lfp,3)]);
    end
    csd(:,:,c) = tmp;
end