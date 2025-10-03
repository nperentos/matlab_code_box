function [Z,P,phases,zvalues]=phase_locking_mua(data,frequencyrange, periods)
if nargin<3; periods = []; end;

Z = zeros(size(data.mua,1),1);
P = zeros(size(data.mua,1),1);
phases = {};
zvalues = {};
for c=1:size(data.mua,1)
    try
        spiketrain = data.mua{c};
        lfp = data.lfp(c,:);

        if isempty(periods);
            [z, p, spike_phases,zval] = phase_locking(spiketrain,lfp,frequencyrange,data.sr,0,1);   
        else
            [z, p, spike_phases,zval] = phase_locking(spikes_in_periods(spiketrain,periods),lfp,frequencyrange,data.sr,0,1);
        end;
        
        
        Z(c) = z;
        P(c) = p;
        phases{c} = spike_phases;
        zvalues{c} = zval';
    catch
        disp(['Problem with : ', num2str(c)])
    end;
end

sig_level = log(-log(0.05));
idx = find(log(Z)>sig_level) % indexes of significantly locked units
figure; 
for c=1:16;     
    subplot(4,4,c); 
    h=hist(phases{c},36);
    if log(Z(c))>sig_level; 
        bar(linspace(-pi, 2*pi,2*length(h)),[h h],'r'); 
    else;
        bar(linspace(-pi, 2*pi,2*length(h)),[h h]);
    end;
    xlim([-pi;2*pi]); title(num2str(c)); box off; set(gca,'TickDir','out'); 
end;
figure;
for c=17:32;     
    subplot(4,4,c-16); 
    h=hist(phases{c},36);
    if log(Z(c))>sig_level; 
        bar(linspace(-pi, 2*pi,2*length(h)),[h h],'r'); 
    else;
        bar(linspace(-pi, 2*pi,2*length(h)),[h h]);
    end;
    xlim([-pi;2*pi]); title(num2str(c)); box off; set(gca,'TickDir','out'); 
end;
