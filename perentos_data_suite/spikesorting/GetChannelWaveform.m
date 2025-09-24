function [SpkMeanWaveform,SpkStdWaveform, cluCh] = GetChannelWaveform (pth) %, Chm

fID = fopen('debug.txt','w');

params.excludeNoise = 1;
sp = loadKSdir(pwd,params);
Res = round(sp.st * sp.sample_rate);
Clu = sp.clu;
chmap = readNPY(fullfile(pth,'channel_map.npy')); % this is useful for
% identifying channels to ignore when forming the average spike waveforms.
% Its possible for example that an analog IN channel sitting on negative rail
% will make all clusters look like they are on that channel
FileName = dir(fullfile(pth,'*.dat'));
FileName = fullfile(FileName.folder,FileName.name);
nSamples = FileLength(FileName)/2/sp.n_channels_dat;
nChannels = sp.n_channels_dat;
mmap = memmapfile(FileName, 'format',{'int16' [nChannels nSamples] 'x'},'offset',0,'repeat',1);
load('mapNP.mat');
str = {'SU','MUA'};
good_chans = find(mapNP.channel_use_flag);
tmp = ceil(size(sp.temps,2)/2);
Lag = [-tmp+1:tmp];
%figure; set(gcf,'pos',[2762 1336 980 702]);
for i = 175:177%length(sp.cids) % this was parfor but avoid for less memory usage
    tic; display(['unit ',num2str(i),'/',num2str(length(sp.cids)), ' is ',str{sp.cgs(4)}])
    myT = Res(find(Clu == sp.cids(i)));% spikes of current cluster
    %Lag = [-40:42];% Lag = [-15:40];this was for my OE data at antons
    myT(myT<1-Lag(1) | myT>nSamples-Lag(end))=[]; % eliminate spikes to close to start/end of file
    nLag = length(Lag);
    nmyT = length(myT);
    myTLagged = reshape(bsxfun(@plus,myT, Lag),[],1); % idxs into dat file for each spike
    Amp = mmap.Data.x(:,myTLagged);
    Amp = reshape(Amp, nChannels, nmyT, nLag);   
    Amp = Amp(good_chans,:,:); % remove irrelevant channels
    mn = repmat(mean(Amp,3),[1, 1, size(Amp,3)]); % all the waveforms across whole electrode space
    mAmp = double(Amp)-mn; % mean corected spike waveforms
    mW = squeeze(mean(mAmp,2)); %
    sdW = squeeze(std(mAmp,[],2)); %
  
    
    
    % find max amp waveform/channel
    % looks for non inverted waveforms too
    %[~,cluCh(i)] =max(max(-mW'));
    [tmp1Amp,tmp1Ch] =max(max(-mW'));
    [tmp2Amp,tmp2Ch] =max(max(mW'));
    
    [a,b] = max([tmp1Amp tmp2Amp]);
    if b == 1
        cluCh(i) = tmp1Ch;%good_chans(tmp1Ch); no! b/c we only loaded the subset of channels
        disp([num2str(good_chans(tmp1Ch)),', ', num2str(tmp1Ch)]);
    else
        cluCh(i) = tmp2Ch;%good_chans(tmp2Ch); no! b/c we only loaded the subset of channels
        disp([num2str(good_chans(tmp2Ch)),', ', num2str(tmp2Ch)]);
    end
    
    % extract main channel
    SpkMeanWaveform{i} = mW(cluCh(i),:);
    SpkStdWaveform{i} = sdW(cluCh(i),:);
    fprintf(fID, '%6.2f\n', i);
end

save('SpkMeanWaveform.mat', 'SpkMeanWaveform');
save('SpkStdWaveform.mat', 'SpkStdWaveform');
save('SpkMainCh.mat', 'cluCh');

end


%{
function [SpkMedianWaveform cluCh] = GetChannelWaveformNoisy (FileBase, pth, chmap)


sp = loadKSdirNoisy(pth);

[Res Clu]=LoadCluRes(FileBase, [], [], 1);

%chmap = readNPY(fullfile(pth,'channel_map.npy')); % this is useful for
% identifying channels to ignore when forming the average spike waveforms.
% Its possible for example that an analog IN channel sitting on negative rail
% will make all clusters look like they are on that channel
FileName = dir(fullfile(pth,'*.dat'));
FileName = fullfile(FileName.folder,FileName.name);
nSamples = FileLength(FileName)/2/sp.n_channels_dat;
nChannels = sp.n_channels_dat;
mmap = memmapfile(FileName, 'format',{'int16' [nChannels nSamples] 'x'},'offset',0,'repeat',1);


uClu = unique(Clu);
nClu = length(uClu);


% figure; set(gcf,'pos',[2762 1336 980 702]);

for i = 1:length(uClu)
    display(['unit',num2str(uClu(i)),'/',num2str(max(nClu))])
    myT = Res(find(Clu == uClu(i)));% spikes of current cluster
    Lag = [-15:40];
    myT(myT<1-Lag(1) | myT>nSamples-Lag(end))=[]; % eliminate spikes too close to start/end of file
    nLag = length(Lag);
    nmyT = length(myT);
    myTLagged = reshape(bsxfun(@plus,myT, Lag),[],1); % idxs into dat file for each spike
    Amp = mmap.Data.x(:,myTLagged);
    Amp = reshape(Amp, nChannels, nmyT, nLag);
    Amp = Amp(chmap+1,:,:); % remove irrelevant channels

    % Exclude outliers. Adapt:
    % thr = prctile(Amp,[0.5 99.5]);
    % noi  = all(mat>repmat(thr(1,:),size(mat,1),1) & mat<repmat(thr(2,:),size(mat,1),1),2);
    % mn(noi)

     mn = repmat(mean(Amp,3),[1, 1, size(Amp,3)]); % all the waveforms across whole electrode space
     mAmp = double(Amp)-double(mn); % mean corected spike waveforms
     mW = squeeze(mean(mAmp,2)); %
    
    % stdSpkNoise  = sq(std(mySpk,0,3));% 
    % snr = sq(mean(mean(abs(avSpk),1),2))./mean(stdSpkNoise(:));
    % find max amp waveform/channel
    [~,cluCh(i)] =max(max(-mW'));
    
    
    
    % extract main channel
    SpkMedianWaveform{i} = mW(cluCh(i),:);
end

save('SpkMedianWaveform.mat', 'SpkMedianWaveform');
save('SpkMainCh.mat', 'cluCh');

end
%}