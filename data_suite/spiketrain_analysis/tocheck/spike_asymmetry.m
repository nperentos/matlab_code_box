function asymmetry = spike_asymmetry(waveforms)
if isvector(waveforms); waveforms = waveforms(:); end;
waveforms = double(waveforms);
sw = zeros(1,size(waveforms,2));
for c = 1:size(waveforms,2);
    w = waveforms(:,c);    
    [maxval,maxidx]= max(w);
    [minval,minidx]= min(w);
    if maxidx>minidx;
        [m,idx]= min(w);
        w_pre = w(1:idx);
        w_post = w(idx:end);
        [b,idx] = max(w_post);
        [a,idx] = max(w_pre); 
        asymmetry(c)= (b-a)/(b+a);
    else
        [m,idx]= max(w);
        w_pre = w(1:idx);
        w_post = w(idx:end);
        [b,idx] = min(w_post);
        [a,idx] = min(w_pre);        
        asymmetry(c)= (b-a)/(b+a);
    end;
end