function [f_max1,f_max2] = find_main_frequency(lfp1,lfp2, freeze, samplingrate)
if nargin<4 || isempty(samplingrate); samplingrate = 500; end;
[m,idx]=max(freeze(:,2)-freeze(:,1));
if freeze(idx,2)*samplingrate>length(lfp1); freeze(idx,2)=length(lfp1)/samplingrate; end;
lfp1_part = lfp1(floor(freeze(idx,1)*samplingrate):ceil(freeze(idx,2)*samplingrate));
lfp2_part = lfp2(floor(freeze(idx,1)*samplingrate):ceil(freeze(idx,2)*samplingrate));

figure; 
subplot(3,2,1);
plot_lfp(lfp1_part,500);
subplot(3,2,3);
calculate_spectrogram(lfp1_part,samplingrate, 'windowsize',5,'overlap',99);
colorbar off;
subplot(3,2,5);
[S,f]=calculate_spectrum(lfp1_part,samplingrate, 'mode','welch','nw',9,'windowsize',3,'overlap',90,'fpass',[1 20],'log','off');
S1=S(f>=2 & f<=6);
f1 = f(f>=2 & f<=6);
[m,idx]=max(S1);
f_max1 = f1(idx);

subplot(3,2,2);
plot_lfp(lfp2_part,500);
subplot(3,2,4);
calculate_spectrogram(lfp2_part,samplingrate, 'windowsize',5,'overlap',99);
colorbar off;
subplot(3,2,6);
[S,f]=calculate_spectrum(lfp2_part,samplingrate, 'mode','welch','nw',9,'windowsize',3,'overlap',90,'fpass',[1 20],'log','off');
S1=S(f>=2 & f<=6);
f1 = f(f>=2 & f<=6);
[m,idx]=max(S1);
f_max2 = f1(idx);

if round(f_max1-1) == round(f_max2-1);
    disp(['f1 = ', num2str(f_max1)])
    disp(['f2 = ', num2str(f_max2)])
    disp(['Lag = ' num2str(find_lfp_lag(lfp1_part,lfp2_part,samplingrate,[round(f_max1-1) round(f_max1+1)],0.1))]);
else
    disp('Different frequencies.')
    disp(['f1 = ', num2str(f_max1)])
    disp(['f2 = ', num2str(f_max2)])
end;