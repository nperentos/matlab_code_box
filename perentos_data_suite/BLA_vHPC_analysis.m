% a pipeline for vHPC-BLA relationships at the MUA level, ripples,
% oscillations and any other network events I can detect as well as all
% crosscorrelagrams between all units
fle = 'NP34_2019-09-25_14-24-11';
[data,settings,tScale] = getLFP(fle);
SR = 1/tScale(1);
%SR = str2num(settings.parameters.fieldPotentials.lfpSamplingRate.Text);

tic;
chOB = 129+1;
chRpl = 7+1;
chDG = 60+1;
chNoise = 31+1;
chBLA = [112]+1;
allCh = [chOB chRpl chDG chNoise chBLA];
lbls = {'OB','CA1', 'dentate', 'NoRpl','putative BLA'};
uLbls = {'MUA','SU'};
% get ripples
[ripples] = getRipples(fle,data,chRpl,chNoise,SR,0);

% spectra abd crorss spectra
S4Hz = specmt(data([allCh],:),'defaults','4Hz'); % get the spectrogram
Sgamma = specmt(data([allCh],:),'defaults','gamma'); % get the spectrogram


%% AUTOSPECTRA
%autospectra respiration rangef
figure; 
for i = 1:length(allCh)
    subplot(length(allCh),1,i);
    imagesc(S4Hz.t',S4Hz.f',(squeeze(S4Hz.Sxy(:,:,i,i)))');
    title(['respiration:' ,lbls{i}]);
end

%autospectra gamma range
figure; 
for i = 1:length(allCh)
    subplot(length(allCh),1,i);
    imagesc(Sgamma.t',Sgamma.f',(squeeze(Sgamma.Sxy(:,:,i,i)))');
    title(['gamma: ' ,lbls{i}]);
end
linkaxes(get(gcf,'children'),'x');
toc;


% subplot numbers for diagonal and bottom triangle
sb = reshape([1:1:numel(allCh)^2],numel(allCh),numel(allCh))';


%% PLOTS - GAMMA CROSS-SPECTRA
figure; 
for i = 1:numel(allCh)
    for j = i:numel(allCh)
        subplot(numel(allCh),numel(allCh),sb(j,i));
        imagesc(Sgamma.t',Sgamma.f',real(squeeze(Sgamma.Sxy(:,:,i,j)))');
        title(['real: ',lbls{i},'-',lbls{j}]);
    end
end
mtit('gamma cross-spectra (real)');

figure; 
for i = 1:numel(allCh)
    for j = i:numel(allCh)
        subplot(numel(allCh),numel(allCh),sb(j,i));
        imagesc(Sgamma.t',Sgamma.f',angle(squeeze(Sgamma.Sxy(:,:,i,j)))');
        title(['imag: ',lbls{i},'-',lbls{j}]);
    end
end
mtit('gamma cross-spectra (imag)');

figure; 
for i = 1:numel(allCh)
    for j = i:numel(allCh)
        subplot(numel(allCh),numel(allCh),sb(j,i));
        plot(Sgamma.f',mean(real(squeeze(Sgamma.Sxy(:,:,i,j)))',2));
        title(['real: ',lbls{i},'-',lbls{j}]);
    end
end
mtit('gamma cross-spectra (real)');

figure; 
for i = 1:numel(allCh)
    for j = i:numel(allCh)
        subplot(numel(allCh),numel(allCh),sb(j,i));
        plot(Sgamma.f',angle(mean(squeeze(Sgamma.Sxy(:,:,i,j))',2)));
        title(['imag: ',lbls{i},'-',lbls{j}]);
    end
end
mtit('gamma cross-spectra (imag)');


%% PLOTS - 4Hz CROSS-SPECTRA
figure; 
for i = 1:numel(allCh)
    for j = i:numel(allCh)
        subplot(numel(allCh),numel(allCh),sb(j,i));
        imagesc(S4Hz.t',S4Hz.f',real(squeeze(S4Hz.Sxy(:,:,i,j)))');
        title(['real: ',lbls{i},'-',lbls{j}]);
    end
end
mtit('resp. cross-spectra (real)');

figure; 
for i = 1:numel(allCh)
    for j = i:numel(allCh)
        subplot(numel(allCh),numel(allCh),sb(j,i));
        imagesc(S4Hz.t',S4Hz.f',angle(squeeze(S4Hz.Sxy(:,:,i,j)))');
        title(['imag: ',lbls{i},'-',lbls{j}]);
    end
end
mtit('resp. cross-spectra (imag)');

figure; 
for i = 1:numel(allCh)
    for j = i:numel(allCh)
        subplot(numel(allCh),numel(allCh),sb(j,i));
        plot(S4Hz.f',mean(real(squeeze(S4Hz.Sxy(:,:,i,j)))',2));
        title(['real: ',lbls{i},'-',lbls{j}]);
    end
end
mtit('resp. cross-spectra (real)');

figure; 
for i = 1:numel(allCh)
    for j = i:numel(allCh)
        subplot(numel(allCh),numel(allCh),sb(j,i));
        plot(S4Hz.f',angle(mean(squeeze(S4Hz.Sxy(:,:,i,j))',2)));
        title(['imag: ',lbls{i},'-',lbls{j}]);
    end
end
mtit('resp. cross-spectra (imag)');


%% TRIGGERED SPECTROGRAMS AROUND RIPPLES
%Parameters for spectrogram calculation optimized for gamma range (as in GammaSpecAcrossChannels)
WinLength_sec = 0.1;  % 100 ms  ~4 gamma cycles
WinLength  = 2^nextpow2(round(WinLength_sec*SR)); 
nOverlap   = WinLength - WinLength/8;                          
nFFT       = 2*WinLength;
HalfSpan = 0.5*SR;
NW = []; nTapers = []; FreqRange = [];
Detrend = 'linear'; %its the default anyhow

[y, A] = WhitenSignal(data([chRpl,chBLA],:)');% whitened signal

% check how whitened vs raw looks like
eegplot([y(:,1)';data(chRpl,:)],'srate',1e3);

[TrigSpec, f,t] = TrigSpecgram(ripples.ripple_t,HalfSpan, y, nFFT,SR,WinLength,nOverlap,NW,Detrend,nTapers,FreqRange);
display 'done'
figure; subplot(211); imagesc(t,f,squeeze(TrigSpec(:,:,1))'); title('ripple triggered CA1');
        subplot(212); imagesc(t,f,squeeze(TrigSpec(:,:,2))'); title('ripple triggered BLA');caxis([0 20]);

%% LOAD SPIKES AND GET CHANNEL ASSIGNMENTS
sp = loadKSdir([getfullpath(fle),'KS/']);
if exist(fullfile(getfullpath(fle),'cluChans.mat'))
    load(fullfile(getfullpath(fle),'cluChans.mat'))
else
    [cluChans] = getCluChans([getfullpath(fle),'KS/'],'plot',1,'raw',1);
    save([getfullpath(fle),'cluChans.mat'],'cluChans');
end

% lets plot all the mean waveforms just for fun
if 0
    figure;
    for i = 1:length(cluChans.wvsRaw)
        subplot(121);imagesc(cluChans.wvsRaw{i}); title(['chan: ',num2str(cluChans.CluChRaw(i))]);
        subplot(122);plot(cluChans.wvsRaw{i}'+repmat([0:50:500]',1,size(cluChans.wvsRaw{i},2))','k'); title(['chan: ',num2str(cluChans.CluChRaw(i))]);
        waitforbuttonpress
    end
end


%% PSTHs AROUND RIPPLES
rc = numSubplots(length(sp.cids)); figure; 
for i = 1:length(sp.cids)
    [out,bins] = trig_spikes(sp.st(sp.clu == sp.cids(i))',ripples.ripple_t(:)./SR, 0.4, 0.02);
    subplot(rc(2),rc(1),i);
    if cluChans.CluChRaw(i) > 65
        bar(bins,mean(out,1),'b'); title(['ch: ', num2str(cluChans.CluChRaw(i)), ', ', uLbls(sp.cgs(i))]);
    else
        bar(bins,mean(out,1),'r'); title(['ch: ', num2str(cluChans.CluChRaw(i)), ', ', uLbls{sp.cgs(i)}]);
    end
end
mtit('all units triggered on ripples');

%% PSTHs AROUND RIPPLES SUBSET
xxx =1;clf;
for i = [1 2 3 10 60 44 56 49]
    [out,bins] = trig_spikes(sp.st(sp.clu == sp.cids(i))',ripples.ripple_t(:)./SR, 0.4, 0.02);
    subplot(2,4,xxx);
    if cluChans.CluChRaw(i) > 65
        bar(bins,mean(out,1),'b'); %title(['ch: ', num2str(cluChans.CluChRaw(i)), ', ', uLbls(sp.cgs(i))]);
    else
        bar(bins,mean(out,1),'r'); %title(['ch: ', num2str(cluChans.CluChRaw(i)), ', ', uLbls{sp.cgs(i)}]);
    end
    xxx=xxx+1;axis tight;
end

%% detect MUA surges in DG and/or CA1
    binSize = 30/1000; %s
    
    chDG = 52:64;
    % find spike clusters on these channels
    cluDG = find(ismember(cluChans.CluChRaw,chDG)==1);
    % find all spikes in these clusters
    tmp = [sp.cids';cluChans.CluChRaw'];
    tmp = tmp(cluDG,:); %[cids chan]
    % DG spikes
    spDG = find(ismember(sp.clu,tmp)==1); % all indices of spikes in DG
    sptDG = sp.st(spDG);
    % compute spike counts in bins of 20ms (use tScale)

    edges = 0:binSize:max(tScale);
    cntDG = histc(sptDG,edges);
    cntDG = resample(cntDG,edges,SR)';
    L = length(data);
    if length(cntDG) > L
        cntDG(L+1:end) = [];
    elseif length(cntDG) < L
        cntDG = padarray(cntDG,L-length(cntDG));
    end
    
%
    chCA = 1:13;
    % find spike clusters on these channels
    cluCA = find(ismember(cluChans.CluChRaw,chCA)==1);
    % find all spikes in these clusters
    tmp = [sp.cids';cluChans.CluChRaw'];
    tmp = tmp(cluCA,:); %[cids chan]
    % DG spikes
    spCA = find(ismember(sp.clu,tmp)==1); % all indices of spikes in DG
    sptCA = sp.st(spCA);
    % compute spike counts in bins of 20ms (use tScale)
    edges = 0:binSize:max(tScale);
    cntCA = histc(sptCA,edges);
    cntCA = resample(cntCA,edges,SR)';
    z_cntCA = zscore(cntCA);
    L = length(data);
    if length(cntCA) > L
        cntCA(L+1:end) = [];
    elseif length(cntCA) < L
        cntDG = padarray(cntCA,L-length(cntCA));
    end
    % zscore
    z_cntDG = zscore(cntDG);
% vis
% eegplot(zscore([data(63,:); cntDG]')','srate',SR,'color','on'); 
eegplot([cntCA; cntDG],'srate',SR,'color','on'); % need to check the orientation of this!

% distributions of zscores 
binEdges = linspace(-6,6,200);
figure; 
h(1) = histogram(z_cntCA,binEdges);
hold on;
h(2) = histogram(z_cntDG,binEdges);
xlabel('zscore');ylabel(['counts (',num2str(binSize),'ms blocks']); legend('iCA1','iDG');title('MUA bursts');

% thrshold crossings in each structure
[idx_MUA_CA,loc_MUA_CA] = findpeaks(z_cntCA,'minpeakprominence',1,'minpeakheight',3);
[idx_MUA_DG,loc_MUA_DG] = findpeaks(z_cntDG,'minpeakprominence',1,'minpeakheight',3);
figure; 
jplot(z_cntCA); hold on; jplot(loc_MUA_CA,idx_MUA_CA,'rx');
jplot(z_cntDG); hold on; jplot(loc_MUA_DG,idx_MUA_DG,'rx');

% lets trigger the BLA activity onto the MUA bursts in CA and DG
rc = numSubplots(length(sp.cids)); figure; 
for i = 1:length(sp.cids)
    [out,bins] = trig_spikes(sp.st(sp.clu == sp.cids(i))',tScale(loc_MUA_CA), 0.4, 0.02);
    subplot(rc(2),rc(1),i);
    if cluChans.CluChRaw(i) > 65
        bar(bins,mean(out,1),'b');title(['ch: ', num2str(cluChans.CluChRaw(i)), ', ', uLbls(sp.cgs(i))]);
    else
        bar(bins,mean(out,1),'r'); title(['ch: ', num2str(cluChans.CluChRaw(i)), ', ', uLbls{sp.cgs(i)}]);
    end
end
mtit('all units triggered on CA population surges (z>3)');
% lets trigger the BLA activity onto the MUA bursts in CA and DG
rc = numSubplots(length(sp.cids)); figure; 
for i = 1:length(sp.cids)
    [out,bins] = trig_spikes(sp.st(sp.clu == sp.cids(i))',tScale(loc_MUA_DG), 0.4, 0.02);
    subplot(rc(2),rc(1),i);
    if cluChans.CluChRaw(i) > 65
        bar(bins,mean(out,1),'b');title(['ch: ', num2str(cluChans.CluChRaw(i)), ', ', uLbls(sp.cgs(i))]);
    else
        bar(bins,mean(out,1),'r'); title(['ch: ', num2str(cluChans.CluChRaw(i)), ', ', uLbls{sp.cgs(i)}]);
    end
end
mtit('all units triggered on DG population surges (z>3)');


%% SU crosscorelograms
SUids = sp.cids(sp.cgs == 2);
SUch  = cluChans.CluChRaw((sp.cgs == 2));
tic;[ccg, t, pairs] = CCG(double(sp.st*sp.sample_rate), double(sp.clu+1), 10, 50, sp.sample_rate,SUids+1);toc;
figure;
for k=1:size(ccg,3)
    for j = k+1:size(ccg,3)
        bar(t, ccg(:,k,j));
        title([num2str(SUids(k)),'(',num2str(SUch(k)), ') - ' num2str(SUids(j)),'(',num2str(SUch(j)), ')']);
        title([num2str(SUids(k)) ' - ' num2str(SUids(j))]);
        waitforbuttonpress
    end
end



