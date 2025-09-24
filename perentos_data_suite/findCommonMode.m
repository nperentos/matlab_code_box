function commonMode = findCommonMode(fileBase,varargin)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% out = findCommonMode(fileBase,varargin) uses ICA to discover
% component(s) with flat loading across (good) electrode space.
% Intended to be used for example of the olfactory bulb
% where slow, movement-related artefacts can be removed before computing
% phase of respiration etc. This is a common artefact in my HF recordings
% and it can obscure respiration signal or theta phase/amplitude. 
% INPUTS: fileBase and other optional inputs such as the data itself
% OUTPUTS: a structure holding the W and A matrices of the ICA
% decomposition along with the component activation for the OB channel or
% other channel if this is not available.
% https://stackoverflow.com/questions/32212968/how-to-project-data-onto-independent-components-using-fastica-in-matlab
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%fileBase = NP46_2019-12-02_18-47-02;
% for i = 1:20
%     for j = 1:length(par.AnatGrps(1:end-1))
%         % get valid channels for eac anatomical group
%         [chch,IA] = intersect(ch,par.AnatGrps(j).Channels+1);
%         mdl{i,j} = fitlm([1:length(IA)],A(IA,i)./norm(A(IA,i),1)); %linear fits for each comp loadings
%     end
% end
% rmses = cellfun(@(x) x.RMSE,mdl,'UniformOutput',true)';
% slopes = cellfun(@(x) x.Coefficients.Estimate(2),mdl,'UniformOutput',true)';


%% PRE
    options = {'nEig',20,'data',[],'respCh',[],'artefactRemovalMethod','mu','resampleType','interpolate'};
    options = inputparser(varargin,options);
    if strcmp(options,'error'); return; end;
    
    
% get the respiration LFP time series    
    processedPath = getfullpath(fileBase);
    cd(processedPath);
    pth = fullfile(getfullpath(fileBase),[fileBase,'.lfp']);
    par = LoadXml([pth(1:end-4),'.xml']);
    
    
    if isempty(options.data) 
        [data,settings,tScale] = getLFP(fileBase);
        if isempty(options.respCh)
            respCh= str2double(searchMasterSpreadsheet(fileBase,'respCh'))+1;
            resp = data(respCh,:);
        end 
    else
        data = options.data;
        resp = data(respCh,:);
    end
    
    % load good channels
    if exist(fullfile(processedPath,'goodChannels.mat'))
        load(fullfile(processedPath,'goodChannels.mat'))
    end
  
    
% strategy. Find components that have 1. low standard deviation 2. high
% loading across electrode space and high loading on the olfactory bulb.
% Use a subset of top eigen components only to facilitate
% component selection. We only need to keep W and A as well as the indices
% of the selected components. Lets also keep a section of the cumulative
% component that is to be removed so that we can visualise it easily and
% decide if it was correcly identified.

%% reduced ICA via number of eigen components to keep 
    ch = [goodChannels.user.probe goodChannels.user.eeg];
    % reduce nEig if default 20 exceeds available (e.g. when recording has no
    % probes inserted
    if length(ch) < options.nEig
       options.nEig = length(ch)
    end
    
    % lets work with first 10 minutes of the recording
    xt = 10*60*par.lfpSampleRate;
    if size(data,2)<xt
        xt = size(data,2);
    end    
    d = data(ch,1:xt);
    
    [icareduced,A,W] = fastica(d,'firstEig',1,'lastEig',options.nEig,'maxNumIterations',2000);
    
    if size(A,2) ~= options.nEig
        options.nEig = size(A,2);
    end

    sd = 1./std(A);
    [~,Isd] = sort(sd);
    mu = abs(mean(A));
    [~,Imu] = sort(mu);
    % scores on OB channels sorted by using Icv
    %OBloadings = abs(A(find(ch == respCh),:) ./ mean(A(setxor([1:size(d,1)],find(ch == respCh)),:),1));
    %[~,Iob] = sort(OBloadings);

    cvinv = 1./(abs(std(A)./mean(A)));%cv' figure; plot(A')
    [~,Icvinv] = sort(cvinv);
    
    % feat = [mu./max(mu);sd./max(sd);OBloadings./max(OBloadings);cvinv./max(cvinv)]';
    % feat = [mu./max(mu);sd./max(sd);OBloadings./max(OBloadings);]'; 
    feat = [mu./max(mu);sd./max(sd);cvinv./max(cvinv)]';
    
    % sort components by their cumulative rankings
    [~,srt]=sort(feat);
    % find unique components in top 4 ranks
    srt = srt(end-3:end,:);
    u = unique(srt);
    % compute the sum of ranks for each of these components
    for i = 1:length(u)
        [rnk1,~] = find(srt == u(i));
        rnk(i,:) = [u(i),sum(rnk1)/size(feat,2)];
        clear rnk1;
    end
    % now we pick the 4 highest score components
    [~,I] = sort(rnk(:,2),'descend');
    fI = rnk(I,1);
    
    % lets add lines for the top 3 components onto the report plot

           
         
    % compute residuals to linear fits for each component and each
    % anatomical group
    for i = 1:options.nEig
        for j = 1:length(par.AnatGrps(1:end-1))
            % get valid channels for eac anatomical group
            [chch,IA] = intersect(ch,par.AnatGrps(j).Channels+1);
            mdl{i,j} = fitlm([1:length(IA)],A(IA,i)./norm(A(IA,i),1)); %linear fits for each comp loadings
        end
    end
    rmses = cellfun(@(x) x.RMSE,mdl,'UniformOutput',true)';
    slopes = cellfun(@(x) x.Coefficients.Estimate(2),mdl,'UniformOutput',true)';
    
    
    % top x components according to the per shank flatness criterion using
    % root mean square error calculation
    % [~,by]=sort(mean(rmses));      
    [~,by]=sort(rmses);

    
    % lets say now we select the top  components although this would need to
    % be automated somehow....
    cmps = fI(1:4);
    clrs = {}; clrs(1:options.nEig) = deal({'k'});clrs(cmps) = deal({'r'});
    % what we then need to do is to reconstuct the undesirable component using
    % cmps and substract that from the real data
    %removedcomponent = A(:,cmps) * icareduced(cmps,:);
    %removedcomponent2 = A(:,fI(1:3)) * icareduced(fI(1:3),:);
    %eegplot(icareduced,'srate',1000,'spacing',[5],'dispchans',30,'color',clrs);
    %eegplot([d(124,:);d(124,:)-removedcomponent(124,:);d(124,:)-removedcomponent2(124,:)],'srate',1000,'spacing',[500],'dispchans',30,'color','on');
    
    commonMode.orderedComps = fI;
    commonMode.ch = ch;
    commonMode.featVsRmses = [fI(1:4),by(1:4)'];
    commonMode.A= A;
    commonMode.W= W;
    commonMode.ICs = icareduced;%(fI,:);
    commonMode.nEig = options.nEig;
    commonMode.features = feat;
    commonMode.clrs = clrs;
    commonMode.fileBase = fileBase;
    commonMode.note = {'components reordered according to their rejectability using the criteria found in features',...
        'to reconstruct new data or components to reject do this: yn = W * dn;, xnreconstructed = A(:,cmps)*yn(cmps,:) where cmps are the components to use;'};

    
%% A SECOND, FULL ICA DECOMPOSITION TO IDENTIFY 50 Hz LINE NOSE
% this is skipped for now
% [A_lineNoiseComponents,W_lineNoiseComponents,ALineNoise,WLineNoise,power_ratio,line_thrd] = getLineNoise(d(:,1:round(end/2)),1.8,par.lfpSampleRate,1);
    
    
    
%% PLOT A REPORT FIGURE
figure('pos',[100 100 1426 1067]);
    subplot(411); imagesc((A)); title('A (ICA loadings)'); ylabel('electrode'); colorbar;% xlabel('component');
    subplot(412); imagesc(feat'); ylabel('features'); title('component features (sd, mu  & cv)'); set(gca,'ytick',[1 2 3]); colorbar; % xlabel('component');
    subplot(414); plot(A'); hold on; axis tight; title('component spread in electrode space');%colorbar;% xlabel('component');
    xlim([0.5 20.5]); colorbar; pause(1);
    axPos = get(gca,'position'); colorbar off;
    pause(1);
    set(gca,'position',axPos);hold on;
    pause(1);
    plot([fI(1) fI(1)],[ylim],'--k','linewidth',2);
    plot([fI(2) fI(2)],[ylim],'--k','linewidth',2);
    plot([fI(3) fI(3)],[ylim],'--k','linewidth',2);
    
    plot([by(1) by(1)]+0.1,[ylim],'--r','linewidth',2);
    plot([by(2) by(2)]+0.1,[ylim],'--r','linewidth',2);
    plot([by(3) by(3)]+0.1,[ylim],'--r','linewidth',2);  
    
    subplot(413); imagesc(rmses); ylabel('anat. grp.'); title('per anat. grp. linfit rmses');colorbar;%xlabel('component');
    
    axes('position',[0 0 1 1]);
    text(0.45, 0.05,'ICA components','fontsize',16); axis off;
    
%% SAVE 
    save(fullfile(getfullpath(fileBase),'commonMode.mat'),'commonMode');
    print(fullfile(processedPath,'commonMode.jpg'),'-djpeg');    
    
% %% reconstruct corrected data where data is the whole recording or new data
%     newICs = commonMode.W * data(ch,:);
%     common = commonMode.A(:,commonMode.orderedComps(1:4))*newICs(commonMode.orderedComps(1:4),:);
%     dataReconstructed = data(commonMode.ch,:)-common;
%     eegplot(data(ch,:),'srate',1000);
%     eegplot(dataReconstructed,'srate',1000);
%     eegplot([Data(1,:);dataReconstructed(1,:)],'srate',1000,'color','on');
%     
  












%%    
% %     % generalisable removed component can be got by unmixing new data using W
% %     % and remixing with the relevant component subset using A.
% %     % for example
% %     dn = data([131 132 ch(1:end-2)],[2841000:+2841000+20000]);
% %     yn = W * dn; % these are the new components
% %     xnreconstructed = A(:,cmps)*yn(cmps,:);
% %     eegplot(dn(1:4,:)-xnreconstructed(1:4,:),'srate',1000,'spacing',800);
% %     eegplot(dn(1:4,:),'srate',1000,'spacing',800);
% % 
% % 
% % 
% %     eegplot(icareduced,'srate',1000,'spacing',[5],'dispchans',30);
% %     eegplot(d,'srate',1000,'spacing',[400],'dispchans',30);
% %     eegplot(removedcomponent,'srate',1000,'spacing',[400],'dispchans',30);
% %     eegplot(d-removedcomponent,'srate',1000,'spacing',[400],'dispchans',30);
% %     eegplot( [d(1,:); d(1,:)-removedcomponent(1,:); d(1,:)-d(2,:);],'srate',1000,'spacing',400,'winlength',5,'dispchans',30,'color','on');

% rank the components according to the magnitude of their featur


% for i = 1:20
%     [mean(A)]
% end

%     figure;
%     subplot(211); plot(A');
%     subplot(212); plot(W);
% 
%     % reconstruct the data without that component
%     %rd2 = A(:,[setdiff([1:20],ex)]) * icasig([setdiff([1:20],ex)],:);
%     rd = A(:,[1:6,8:10]) * icareduced([1:6,8:10],:);
%     rd = A(:,:) * icareduced(:,:);
%     removedcomponent = A(:,7) * icareduced(7,:);
%     removedcomponent = W(:,7) * d(7,:);
% 
% 
% 
% 
% 
%     %rd = W([1:6,8:10],:)' * icasig([1:6,8:10],:);
%     eegplot( icareduced,'srate',1000,'spacing',4);
%     eegplot( [d(1,:); removedcomponent(1,:); ],'srate',1000,'spacing',400,'winlength',5,'dispchans',30);
%     eegplot( [d(1,:); removedcomponent(1,:); d(1,:)-removedcomponent(1,:)],'srate',1000,'spacing',400,'winlength',5,'dispchans',30);
%     eegplot( [d(1,:); d(1,:)-removedcomponent(1,:)],'srate',1000,'spacing',400,'winlength',5,'dispchans',30,'color','on');
% 
%     figure;
%     for i = 1:20 
%         subplot(4,5,i);
%         hist(abs(icareduced(i,:)),100);
%     end    
    








%% OLD ICA DECOMPOSITION
% ch = goodChannels.user;
% d = data(ch,1:round(end/10));
% tic;[icasig, A, W] = fastica(d,'verbose','off', 'numOfIC',40);toc;
% 
% figure;
% subplot(211);imagesc(A);title('A');axis square;
% subplot(212);imagesc(W);title('W');axis square;
% eegplot(d,'srate',1000);
% eegplot(icasig,'srate',1000);   
% 
% % 'flatness' across all electrodes
% clear mdl
% for i = 1:20
%     mdl{i}=fitlm([1:size(A,1)],A(:,i)./norm(A(:,i))); %linear fits for each comp loadings
% end
% rmses = cellfun(@(x) x.RMSE,mdl,'UniformOutput',true)';
% per shank flatness
% clear mdl
% for i = 1:20
%     for j = 1:length(par.AnatGrps(1:end-1))
%         % get valid channels for eac anatomical group
%         [chch,IA] = intersect(ch,par.AnatGrps(j).Channels+1);
%         mdl{i,j} = fitlm([1:length(IA)],A(IA,i)./norm(A(IA,i),1)); %linear fits for each comp loadings
%     end
% end
% rmses = cellfun(@(x) x.RMSE,mdl,'UniformOutput',true)';
% slopes = cellfun(@(x) x.Coefficients.Estimate(2),mdl,'UniformOutput',true)';
% % slopes = cellfun(@(x) x.Coefficients.Estimate(2),mdl,'UniformOutput',false)';
% figure; plot((std(A,0,1)./mean(A,1))','xk');
% figure; plot((sum(A,1)),'xk');
% 
% figure;
% plot(rmses);
% figure;
% plot(slopes);
% 
% % for i = 1:20
% %     coefficients = polyfit([1:20],A(i,:), 1);
% %     slope(i) = coefficients(1);
% % end
% 
% % reconstruct all channelswithout the flat
% % components
% 
% 
% rd = (icasig([setdiff([1:17],ex)],:)'*W([setdiff([1:17],ex)]))';
% 
% % mixing back selected components only A * ICs
% % but below compares n of comp and how much can be reconstructed. The
% % answer is that to reconstruct the orihginal signals complete;y one needs
% % to ask for the full number of components. There is no adjustment of the
% % components so as to capture more variability in less components!
% % Therefore the solution could be to select less channels
% 
% ex = [];tic;
% nIC = 20;
% [icasig, A, W] = fastica(d,'verbose','off', 'numOfIC',nIC);toc;
% remixed = A(:,[setdiff([1:nIC],ex)]) * icasig([setdiff([1:nIC],ex)],:);
% figure;
% subplot(211);
% plot(d(124,[1+[5*1e3:10*1e3]]),'color',[0.6 0.6 0.6]); hold on;
% plot(remixed(124,[1+[5*1e3:10*1e3]])); 
% axis tight; legend('real data','reconstructed');
% title('reconstructed OB with 20 comps');
% nIC = 80;
% [icasig, A, W] = fastica(d,'verbose','off', 'numOfIC',nIC);toc;
% remixed = A(:,[setdiff([1:nIC],ex)]) * icasig([setdiff([1:nIC],ex)],:);
% subplot(212);
% plot(d(124,[1+[5*1e3:10*1e3]]),'color',[0.6 0.6 0.6]); hold on;
% plot(remixed(124,[1+[5*1e3:10*1e3]])); 
% axis tight; legend('real data','reconstructed');
% title('reconstructed OB with 20 comps');
% 
% toc
% 
% 
% figure; kp = [];
% subplot(212);plot((sum(A,1)),'xk'); hold on;
% for i = 1:nIC
%     subplot(211);cla
%     plot(icasig(i,[1+[5*1e3:10*1e3]]));axis tight; ylim([-5 5]); title(['comp: ',num2str(i)]);
%     subplot(212);plot(i,sum(A(:,i)),'or','markersize',15,'linewidth',2);
%     g=input('k for keep, any other key for next','s');
%     g
%     if strcmp(g, 'k')
%         kp = [kp, i];
%     else
%         children = get(gca, 'children');
%         delete(children(1));
%     end
% end
% 
% % unmixing W*ICs or W*new data
% ex = [1:10];
% rd2 = A(:,[setdiff([1:20],ex)]) * icasig([setdiff([1:20],ex)],:);
% 
% 
% eegplot([rd(16,:);d(16,:)],'srate',1000);
% eegplot([rd2(end-1,:);d(end-1,:);d(end-1,:)-d(end,:)],'srate',1000,'color','on');
% 
% 
% % lets use par to select less channels. For example since we know that we
% % should expect a max of 128 probe channels we should force a max of e.g.
% % 32 or even 16 components plus the EEGs. This might allow finding a single
% % or not too many flat components 
% nG = (par.nElecGps -2); % number of prob groups
% 
% tmp = 16; % number of 
% skip = length(chP)/tmp;
% 
% %% lets pick a subset of channels on which to do ICA for common mode discovery
% nComp = 16; % we want to keep a subset of channels to make ICA computation easier
% chP = [par.AnatGrps(1:end-2).Channels]+1; % probe channels
% chch = intersect(chP,goodChannels.user.probe);
% % nComp, equally spaced channels across probe space to use + good EEGs
% chch = [chch(round(linspace(1,length(chch),nComp))), goodChannels.user.eeg];
% % or all the good channels (expensive but more likely to find a 
% %ICA
% d = data(chch,1:round(end/5));
% 
% %visualise
% figure;
% subplot(211);imagesc(A);colorbar;title('A');axis square;
% subplot(212);imagesc(W);colorbar;title('W');axis square;
% eegplot(d,'srate',1000);
% eegplot(icasig,'srate',1000);
% 
% %% select components based on ???
% % we check only on the probe since the EEGs will have different
% % loadings because they have very differen impedances and locations
% I = 1:(length(chch)-length(goodChannels.user.eeg));
% I = 1:(length(chch));
% figure;
% %
% subplot(231);
% plot((std(A(I,:),0,1)./mean(A(I,:),1))','xk');title('A coefficient of variations');
% subplot(232);
% plot((sum(abs(A(I,:)),1)),'xk');title('A sums');
% subplot(233);
% % plot((std(A(I,:),0,1)./abs(sum(A(I,:),1)),'xk');title('A std');
% plot(std(A(I,:),0,1),'xk');title('A std');
% %
% subplot(234);
% plot((std(W,0,1)./mean(W,1))','xk');hold on;
% plot((std(W,0,2)./mean(W,2))','xr');title('Ws coefficient of variations');
% subplot(235);
% plot((sum(W,2)),'xk');hold on;title('W sums');
% plot((sum(W,2)),'xr');
% subplot(236);
% plot((std(W,0,2)),'xk');
% plot((std(W,0,2)),'xr');hold on;title('W std');
% 
% 
% 
% 
% %perhaps if we use all the channels we will have a better chance at finding
% %the 'flat' component because we do not add bias by selecting subsets of
% %channels whose depth is not equivalent. This is the case here were we have
% %many shanks that are spanning a layer an hence they all experience some
% %change in their lfps that is both local but acutally spans shanks too! If
% %through our subset selection we happened to select more above than below
% %the layer then the flatness would affected?
% % alternatively we can calculate the ica for all channels and look for
% % degree linearness on a per anatomical group basis (shank basis), How
% % would this transate to since long shank i dont know.
% chch = [goodChannels.user.eeg,goodChannels.user.probe];
% d = data(chch,1:round(end/12));
% tic
% [icasig, A, W] = fastica(d,'verbose','off');
% toc
% 
% 
% %visualise
% figure('color','k');
% subplot(211);imagesc(A);colorbar;title('A');axis square;
% subplot(212);imagesc(W);colorbar;title('W');axis square;
% eegplot(d,'srate',1000);
% eegplot(icasig,'srate',1000);
% 
% % sort by the std
% [~,I]=sort(std(A(3:end,:)));
% I(1:10)
% eegplot(icasig(I(1:10),:),'srate',1000);
% 
% 
% % flatness...
% tic
% for i = 1:length(chch)
%     mdl{i}=fitlm([1:length(chch)],A(1:end,i)'); %linear fits for each comp loadings    
% end
% mus = mean(A(1:125,:),1);
% toc
% 
% rmses = cellfun(@(x) x.RMSE,mdl,'UniformOutput',true)';
% slopes = cellfun(@(x) x.Coefficients.Estimate(2),mdl,'UniformOutput',true)';
% 
% 
%  for i = 1:125;nrm(i)=norm(A(3:end,i));end;
%  for i = 1:125;nrm(i)=norm(mdl{i}.Residuals.Raw,2);end;
% 
%  for i = 1:10:125;eegplot(icasig(i:i+9,:),'srate',1000,'spacing',7);i,pause;close;end;
%   [COEFF, SCORE, LATENT] = pca(d,'economy','on');
%   
% % per shank flatness component flatness 
% % manually for the moment
% figure;
% for i = 7:10
%     plot(zscore(A(:,i)));ylim([-2 2]);hold on;title(num2str(i));pause(2);
% end


    % linear fits and their residuals?
    % for i = 1:size(A,2)
    %     mdl{i}=fitlm([1:length(chch)],A(1:end,i)'); %linear fits for each comp loadings    
    % end
    % % best linear fit - lowest standard error of mean wins
    % rmses = cellfun(@(x) x.RMSE,mdl,'UniformOutput',true)';
    % [~,rmse_min] = min(rmses);
    %slopes = cellfun(@(x) x.Coefficients.Estimate(2),mdl,'UniformOutput',true)';

    % coefficient of variation - lowest wins
    % cv = std(A)./abs(mean(A));
    % [~,cv_min] = min(cv);

    % sd * mean





