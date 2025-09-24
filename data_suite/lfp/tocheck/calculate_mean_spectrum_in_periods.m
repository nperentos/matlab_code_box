function [mean_spec,f]=calculate_mean_spectrum_in_periods(lfp,samplingrate,periods,normalize)
if nargin<4 || isempty(normalize); normalize = 'none'; end;

mean_spec=[];
for c=1:size(periods,1);
    [S,f]=calculate_spectrum(lfp(int32(periods(c,1)*samplingrate):int32(periods(c,2)*samplingrate)),samplingrate,'mode','welch','windowsize',1,'overlap',95,'log','off','fpass',[0 20],'plot','off');
    if strcmp(normalize,'delta'); % Suitable for comparison between conditions
        S=S./sum(S(f<2));
    elseif strcmp(normalize,'total'); % Suitable for comparison between animals
        S=S./sum(S);        
    end;
    
    if isempty(mean_spec); mean_spec = S; else mean_spec = mean_spec + S; end;    
end;

plot(f,10*log10(mean_spec./size(periods,1)),'b')