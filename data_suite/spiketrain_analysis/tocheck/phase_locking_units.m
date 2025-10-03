function [Z,P,phases,zvalues]=phase_locking_units(data,frequencyrange, periods)
if nargin<3; periods = []; end;

Z = zeros(size(data.units,1),1);
P = zeros(size(data.units,1),1);
phases = {};
zvalues = {};
for c=1:size(data.units,1)
    try
        spiketrain = data.units{c,2};
        lfp = data.lfp(find_corresponding_channel(data.units{c,1}),:);

        if isempty(periods);
            [z, p, spike_phases,zval] = phase_locking(spiketrain,lfp,frequencyrange,data.sr,0,1);   
        else
            [z, p, spike_phases,zval] = phase_locking(spikes_in_periods(spiketrain,periods),lfp,frequencyrange,data.sr,0,1);
        end;
        
        if length(spike_phases)<50; z=-10; p=1; end;
        
        
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
subplot(5,1,2:5);
zvalues = cell2mat(zvalues);
[maxz,maxidx]=max(zvalues);
[s,idx]=sort(maxz,'descend');
norm_zvalues = normalize_array(zvalues');
norm_zvalues = norm_zvalues(idx,:);
zvalues_sorted = zvalues(:,idx);
[maxz,maxidx]=max(zvalues_sorted);
imagesc(norm_zvalues);
hold on;
sig_level = -log(0.05/141);
idx = find(maxz<=sig_level);
plot(maxidx(idx),idx,'*w')
idx = find(maxz>sig_level);
plot(maxidx(idx),idx,'*k')
set(gca,'XTick',[1,71,141],'XTickLabel',[-700,0,700])
set(gca,'TickDir','out')
xlabel('Temporal offset \tau');
ylabel('Cell #');
box off;
subplot(5,1,1);
h=histc(maxidx(idx),1:10:141);
bar(linspace(-700,700,length(h)),h)
ylabel('Count');
box off;
xlim([-700, 700])
set(gca,'XTick',[]);

sig_level = log(-log(0.05));
for k=1:floor(size(data.units,1)/16)+1
    figure;
    for c=1:16;
        n=(c+(k-1)*16);
        if n<=size(data.units,1)
            subplot(4,4,c);
            h=hist(phases{n},36);
            if log(Z(n))>sig_level; 
                bar(linspace(-pi, 2*pi,2*length(h)),[h h],'r'); 
            else
                bar(linspace(-pi, 2*pi,2*length(h)),[h h]);
            end;
            xlim([-pi;2*pi]);set(gca,'XTick',[-pi, 0, pi, 2*pi],'XTickLabel',{'-pi','0','+pi','+2pi'}); title(num2str(n)); box off; set(gca,'TickDir','out'); 
        else
            break;
        end;
    end;
end;