function out = detect_spikes(sig, varargin)

% Input parsing
options = {'sr',30000,'upratio',5,'samples_pre',15,'samples_post',32,'waveformlength',1.6 * 0.001,'nonlinearsamples',7,'plot',1,'threshold',20};
options = inputparser(varargin,options);
if strcmp(options,'error'); return; end;

%%
sig1 = filter_lfp(sig,options.sr,[800 8000]);
sig1 = nonlinear_energy_operator(sig1,options.nonlinearsamples).*medfilt1(sig1,options.nonlinearsamples); 

thr = median(abs(sig1))/0.6745 * options.threshold;

spiketimes = LocalMinima(sig1, options.waveformlength*options.sr, -thr); % 1ms distance of peaks

idxes = cell2mat(arrayfun(@(x)x-options.samples_pre:x+options.samples_post,spiketimes,'un',0));
waveforms = sig(idxes);

%% Upsample
% w1 = spline(linspace(1,size(waveforms,2),size(waveforms,2)),waveforms,linspace(1,size(waveforms,2),size(waveforms,2)*options.upratio));
% [~,idx]=min(w1,[],2);
% 
% spiketimes = spiketimes + round(idx/options.upratio) - (options.samples_pre+1); % (options.samples_pre+1) is the actual peak point
% 
% idxes = cell2mat(arrayfun(@(x)x-options.samples_pre:x+options.samples_post,spiketimes,'un',0));
% waveforms = sig(idxes);

%% Throw out spurious waveforms
[~,idx]=min(waveforms,[],2);
tmp = idx - (options.samples_pre+1);
tmp = tmp>5 | tmp<-5;
spiketimes(tmp) = [];
waveforms(tmp,:) = [];

%% Remove mean
wmean = median(waveforms,2); % mean or median is best?
waveforms_norm = bsxfun(@minus,waveforms, wmean);
%wstd = std(waveforms,[],2);
%waveforms_norm  = bsxfun(@rdivide,waveforms_norm ,wstd);

%% Perform PCA
[coeff,pcafeatures,latent] = pca(waveforms_norm,'Centered','off'); % which part of the waveform is best to keep? some part or all?
explained=latent/sum(latent)*100;

%% Manual features
[maxval,maxidx]=max(waveforms_norm,[],2);
[minval,minidx]=min(waveforms_norm,[],2);

clear manualfeatures
% Spike Height
manualfeatures(:,1) = maxval-minval;

% Spike Width
manualfeatures(:,2) = maxidx-minidx;

% Spike ratio
manualfeatures(:,3) = abs(maxval./minval);

% Spike AHP
for c=1:size(waveforms_norm);
    tmp = waveforms_norm(c,options.samples_pre+1:end);
    manualfeatures(c,4) = sum(tmp(tmp>0));
end

%% Plot
if options.plot
    % Plot raw signal
    fig; 
    jplot(sig); %hold on; line([0 length(sig1)],[-thr -thr]);
    hold on;
    sigtmp = sig;
    tmp1=cell2mat(arrayfun(@(x)x-10:x+10,spiketimes,'un',0));
    tmp1 = tmp1(:);
    sigtmp(setdiff(1:length(sigtmp),tmp1))=NaN;
    hold on; jplot(sigtmp,'r');
    
    % Plot waveforms
    fig; jplot(waveforms_norm','k')

    % Plot 3D PCA
    fig; scatter3(pcafeatures(:,1),pcafeatures(:,2),pcafeatures(:,3));
    
    % Plot pairwise plots
    fig; ndplot([manualfeatures pcafeatures(:,1:4)])
end

%% Ouput
out.features = [manualfeatures pcafeatures(:,1:4)];
out.waveforms = waveforms_norm;
out.spiketimes = spiketimes;
out.info = options;
out.info.latent = latent;
out.info.PC = coeff;
out.info.explained = explained;

