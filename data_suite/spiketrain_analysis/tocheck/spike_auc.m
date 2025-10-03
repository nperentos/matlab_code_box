function area = spike_auc(waveforms)
if isvector(waveforms); waveforms = waveforms(:); end;
waveforms = double(waveforms);
area = zeros(1,size(waveforms,2));
for c = 1:size(waveforms,2)
    w = waveforms(:,c); 
    [maxval,maxidx]= max(w);
    [minval,minidx]= min(w);
    w = resample(w,300,12);
    %if maxidx>minidx;   
        m = max(w);
        w=w./m;
        [m,idx]=min(w);
        w=w(idx:end);
        w=w(w>=0);
        area(c) = trapz(abs(w));
%     else
%         m = max(w);
%         w=w./m;
%         [m,idx]=max(w);
%         w=w(idx:end);
%         w=w(w<=0);
%         area(c) = trapz(abs(w));
%     end;
    
end;