function scores = extract_features(waveforms, mode, normalize)
if nargin<3
    normalize = 0;
end;

if normalize<2
    timestamps = [];
end;

if strcmp(mode,'pca')
    if normalize == 1
        [coeffs,scores,variances,t2] = princomp(zscore(waveforms));
    else
        [coeffs,scores,variances,t2] = princomp(waveforms);
    end
    percent_explained = 100*variances/sum(variances);

    figure;
    subplot(2,2,1);
    plot(scores(:,1),scores(:,2),'k.')
    xlabel('1st Principal Component')
    ylabel('2nd Principal Component')

    subplot(2,2,2);
    plot(scores(:,1),scores(:,3),'k.')
    xlabel('1st Principal Component')
    ylabel('3rd Principal Component')

    subplot(2,2,3);
    plot(scores(:,2),scores(:,3),'k.')
    xlabel('2nd Principal Component')
    ylabel('3rd Principal Component')

    subplot(2,2,4);
    pareto(percent_explained)
    xlabel('Principal Component')
    ylabel('Variance Explained (%)');

    figure;
    scatter3(scores(:,1),scores(:,2),scores(:,3),'k.');
    
    figure;
    plot(coeffs(:,1),'r')
    hold on;
    plot(coeffs(:,2),'m')
    plot(coeffs(:,3),'b')
    hold off;
    
elseif strcmp(mode,'classic')
    [maxima,maximaidx] = max(waveforms,[],2);
    [minima,minimaidx] = min(waveforms,[],2);
    amplitude = maxima-minima;
    width = maximaidx - minimaidx;
    energy = sum(waveforms.^2,2);
    
elseif strcmp(mode,'wavelet')
    s1 = size(waveforms,1);
    s2 = size(waveforms,2);
    cc=zeros(s1,s2);
    for c=1:s1
        [coeff,l]=fix_wavedec_local(waveforms(c,:),4);
        cc(c,1:s2)=coeff(1:s2);
    end;
    
    for i=1:s2 % KS test for coefficient selection   
        thr_dist = std(cc(:,i)) * 3;
        thr_dist_min = mean(cc(:,i)) - thr_dist;
        thr_dist_max = mean(cc(:,i)) + thr_dist;
        aux = cc(find(cc(:,i)>thr_dist_min & cc(:,i)<thr_dist_max),i);

        if length(aux) > 10;
            [ksstat]=test_ks(aux);
            sd(i)=ksstat;
        else
            sd(i)=0;
        end
    end;
    [m ind]=sort(sd);
    
    % Extract 10 coefficients that are most different from normal    
    scores = cc(:,ind(s2:-1:s2-10+1));
    
    figure;
    combinations = combnk(1:size(scores,2),2);
    for c=1:length(combinations)
        plot(scores(:,combinations(c,1)),scores(:,combinations(c,2)),'+');
        pause(1);
        xlabel('1st coeff')
        ylabel('2nd coeff')
    end;
    
elseif strcmp(mode,'template')  
    %plot some spikes
    l=length(waveforms);
    for c=1:ceil(l/20);
        plot(w1(randi(l),:)); 
        hold on;  
    end;
    %ylim([min(min(waveforms)) max(max(waveforms))]);
    % to write part for drawing template
    
    % to write part for applying template to all spikes
    
end;
    
