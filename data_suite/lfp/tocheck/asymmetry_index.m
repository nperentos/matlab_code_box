function result = asymmetry_index(lfp)
lfp = lfp-mean(lfp);
lfp = lfp./std(lfp);

[maxidx,minidx]=minimamaxima(lfp);
zero_crossings = diff((lfp>0));

maxidx = maxidx(:,1);
minidx = minidx(:,1);

% Normalize so that signals start at maxidx
if minidx(1)<maxidx(1); 
    minidx=minidx(2:end);
end

if length(maxidx)~=length(minidx);
    tmp = min(length(maxidx),length(minidx));
    maxidx=maxidx(1:tmp);
    minidx=minidx(1:tmp);
end

result = (maxidx(2:end-1)-minidx(1:end-2))./(minidx(2:end-1)-maxidx(2:end-1));