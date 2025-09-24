function pairwise_coherence(data)

options = {'whiten',0,'pad',1','nw',1.5,'freqrange',[20 100],'windowsize',0.5,'overlap',60,'normalize',0,'smooth',0}; 
    
siz = size(data,1);
coh = [];
for k1=1:siz;
    for k2=k1+1:siz;
        s = specmt(data(k1:k2,:),options);
        s = plot_spectra(s,[1 2],'mode','coherogram');
        coh(k1,k2) = sum(s.Smean);        
    end
end

fig; imagesc(coh);