function [properties,T] = neuron_characterization(unit_spikes,unit_templates)

if length(unit_spikes)~=length(unit_templates); error('Spikes and templates have different length.'); end;

%% Calculate properties
props = struct();
for c=1:length(unit_spikes);
    tmp = spike_properties(unit_spikes{c},unit_templates{c});
    if c==1;
        props = tmp;
    else
        props(c) = tmp;
    end
end

amp = [props.amp];
freq = [props.freq];
halfwidth = [props.halfwidth];
asymmetry = [props.asymmetry];
t2p = [props.t2p];

%% PCA of autocorr
%autocorr = {props.autocorr};
%autocorr = cell2mat(autocorr)';
%tmp = zscore(autocorr,[],2);
%[coeff1,score1,latent1,tsquared1,explained1] = pca(tmp);
%[~,idx]=min(abs(autocorr(:,501:end) - mean(autocorr(:,501:end),2)),[],2); % Mean of autocorr

%% PCA of second derivative of waveform
%wfs = cell2mat(unit_templates);
%tmp = diff(wfs,2,2);
%tmp1 = zscore(tmp,0,2);
%[coeff2,score2,latent2,tsquared2,explained2] = pca(tmp1);

%% Check properties
%properties = [freqs, aucs, widths,asymmetry, score(:,1:2)];
%properties = [freqs, aucs, widths,asymmetry, idx'];
% properties = [log(freq(:)), t2p(:), halfwidth(:), asymmetry(:), idx(:), score1(:,1:2) score2(:,1:2)];
% propnames = {'freq','t2p','halfwidth','asymmetry','idx','score1_1','score1_2','score2_1','score2_2'};
% cmb = combnk(1:size(properties,2),2);
% 
% for k = 1:size(cmb);
%     fig;
%     jplot(properties(:,cmb(k,1)),properties(:,cmb(k,2)),'.');
%     xlabel(propnames(:,cmb(k,1)));
%     ylabel(propnames(:,cmb(k,2)));
%     %waitforbuttonpress;
% end

%% Set properties
%properties = [asymmetry(:), t2p(:), halfwidth(:),log(freq(:)), idx(:), score1(:,1:2)];
properties = [asymmetry(:), t2p(:), halfwidth(:),log(freq(:))];

%% Dimensionality reduction
% addpath(genpath([codepath '/external/drtoolbox']))
%Y = compute_mapping(zscore(properties(:,[2 3 4 5 6])')', 'MDS',2);
%Y = tsne(properties,[],3);

%fig; scatter3(Y(:,1),Y(:,2),Y(:,3))
%fig; jplot(Y(:,1),Y(:,2),'.')

%% Clustering

% Hierearchical clustering
%Z  = pdist(Y,'euclidean');
%Z  = pdist(properties(:,[2 4]),'euclidean');
%Z = linkage(Z,'ward');
%T = cluster(Z,'maxclust',2);

% k-means clustering
%idx = find_outliers(properties(:,1));
%idx = setdiff(1:size(properties,1),idx);
%properties = properties(idx,:);
T = kmeans(properties(:,[1 2]),2,'Replicates',200,'start','cluster');
%T = kmeans(Y,2,'Replicates',100,'start','cluster','Distance','cosine','OnlinePhase','on');

% Fuzy logic clustering
%[~,U] = fcm(properties(:,2:3),2);
%index1 = find(U(1,:) == max(U));
%index2 = find(U(2,:) == max(U));
%T = []; T(index1) = 1; T(index2) = 2;

%
% Decides who is who based on the mean spike width
% Smaller spike width : Interneurons
% This part gives always the number 1 to Interneurons and number 2 to
% Pyramidals. If it is not the case, it inverts the numberings.
if median(properties(T==1,1))>median(properties(T==2,1))
    T(T==1)=10;
    T(T==2)=1;
    T(T==10)=2;
end

disp('T == 1 are the Interneurons')
disp('T == 2 are the Pyramidal Neurons')
disp(['There are ' num2str(length(properties(T==2))) ' Pyr (' num2str(length(properties(T==2))/length(properties)*100) '%)'] )
disp(['There are ' num2str(length(properties(T==1))) ' IN (' num2str(length(properties(T==1))/length(properties)*100) '%)'] )



%% Plotting
c1 = '.r';
c2 = '.b';
figure;
temp = properties(T==1,:);
jplot(temp(:,2),temp(:,1),c1)
hold on;
temp = properties(T==2,:);
jplot(temp(:,2),temp(:,1),c2)
xlabel('Trough-to-peak latency (ms)');
ylabel('Waveform asymmetry');
legend('IN', 'PN'); legend('boxoff');
fixfig;

% figure;
% subplot(3,1,1)
% temp = properties(T==1,:);
% plot(temp(:,1),temp(:,2),c1)
% hold on;
% temp = properties(T==2,:);
% plot(temp(:,1),temp(:,2),c2)
% box off; set(gca,'TickDir','out');
% xlabel('Frequency')
% ylabel('AUC')
% legend('IN', 'PN'); legend('boxoff');
% 
% 
% subplot(3,1,2)
% temp = properties(T==1,:);
% plot(temp(:,1),temp(:,3),c1)
% hold on;
% temp = properties(T==2,:);
% plot(temp(:,1),temp(:,3),c2)
% box off; set(gca,'TickDir','out');
% xlabel('Frequency')
% ylabel('SpikeWidth')
% legend('IN', 'PN'); legend('boxoff');
% 
% 
% subplot(3,1,3)
% temp = properties(T==1,:);
% plot(temp(:,2),temp(:,3),c1)
% hold on;
% temp = properties(T==2,:);
% plot(temp(:,2),temp(:,3),c2)
% box off; set(gca,'TickDir','out');
% xlabel('AUC')
% ylabel('SpikeWidth')
% legend('IN', 'PN'); legend('boxoff');
% 
% %%
% figure;
% temp = properties(T==1,:);
% scatter3(tempxl(:,3),temp(:,2),temp(:,1),c1)
% hold on;
% temp = properties(T==2,:);
% scatter3(temp(:,3),temp(:,2),temp(:,1),c2)
% zlabel('Frequency (Hz)')
% xlabel('Area under AHP (uV^2)')
% ylabel('Spike half-width (us)')
% legend('IN', 'PN'); legend('boxoff');
% fixfig;
