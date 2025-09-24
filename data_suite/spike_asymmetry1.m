function asymmetry = spike_asymmetry1(waveforms)
if isvector(waveforms); waveforms = waveforms(:); end;
waveforms = double(waveforms);
sw = zeros(1,size(waveforms,2));
for c = 1:size(waveforms,2);
    w = waveforms(:,c);
%%
    [m,idx]= min(w);
    w_pre = w(1:idx);
    w_post = w(idx:end);
    asymmetry(c)= sum(w_pre(w_pre>0)) - sum(w_post(w_post>0));
end