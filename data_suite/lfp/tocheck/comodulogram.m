% 03 July 2016
% To correct and improve

function comodulogram(x)

phase_freqs = 0:2:12;
phase_freqs = [phase_freqs' phase_freqs'+4];

amp_freqs = 20:5:160;
amp_freqs = [amp_freqs' amp_freqs'+10];

phasebins = linspace(-pi,pi, 19);
phasebins = [phasebins(1:end-1)' phasebins(2:end)'];

out = [];
for p=1:size(phase_freqs,1)
    disp([num2str(p) '/' num2str(length(phase_freqs))])
    for a=1:size(amp_freqs,1)
        s1 = angle(hilbert(filter_lfp(x,1000,phase_freqs(p,:))));
        s2 = abs(hilbert(filter_lfp(x,1000,amp_freqs(a,:))));
        
        % Find phases that belong to each bin
        for ph=1:size(phasebins,1)
            [~,idx]=spikes_in_periods(s1,phasebins(ph,:));
            out(p,a,ph) = mean(s2(idx));
        end
    end
end
out1 = bsxfun(@rdivide, out,sum(out,3));

%% Calculate Modulation Index (Kullback-Leibler distance of distribution (of phases) from uniform distribution for each phase/amplitude pair
out2 = [];
for k=1:size(out1,1)
    for j = 1:size(out1,2)
        tmp = squeeze(out1(k,j,:))';
        out2(k,j) = KLDiv(tmp,ones(1,length(tmp)));
    end
end
out2 = out2./log(18); % Modulation Index

fig; imagesc(mean(phase_freqs,2),mean(amp_freqs,2),out2'); axis xy;
set(gca,'XTick',mean(phase_freqs,2));
ylabel('Phase Frequency (Hz)');
xlabel('Power Frequency (Hz)');
fixfig;