function sw = spike_width(waveforms)
if isvector(waveforms); waveforms = waveforms(:); end;
waveforms = double(waveforms);
sw = zeros(1,size(waveforms,2));
for c = 1:size(waveforms,2);
    w = waveforms(:,c);
    [maxval,maxidx]= max(w);
    [minval,minidx]= min(w);
    
    %[m,idx]= min(w);
    %w = w(idx:end);
    %[m,idx] = max(w);
    %sw(c)= (idx-1);
    
    sw(c) = abs(maxidx - minidx);
    
end