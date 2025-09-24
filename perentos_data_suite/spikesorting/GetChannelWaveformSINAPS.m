function [cluMeanWaveform,cluStdWaveform, cluCh, cluShank, cluSpatialProps] = GetChannelWaveform (pth) %, Chm

%     fID = fopen('debug.txt','w');

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
    % FileName = '/storage2/andreas/data/raw/iit/IIT_LMU/1950_2/1950_2.dat';
    nSamples = FileLength(FileName)/2/sp.n_channels_dat;
    nChannels = sp.n_channels_dat;
    mmap = memmapfile(FileName, 'format',{'int16' [nChannels nSamples] 'x'},'offset',0,'repeat',1);
    load('mapNP.mat');
    anat_group = mapNP.anat_group(:);
    tbl = readtable('cluster_info.tsv', 'FileType','text','Delimiter', '\t');
    str = {'MUA', 'SU'};
    good_chans_all = find(mapNP.channel_use_flag);
    tmp = ceil(size(sp.temps,2)/2);
    Lag = [-tmp+1:tmp];
    %figure; set(gcf,'pos',[2762 1336 980 702]);
    
%% for each cluster extract main channel, mean and std of cluster waveform

    for i = 1:length(sp.cids) % this was parfor but avoid for less memory usage
        
    % find corresponding shank so as to load only a subset of channels
        current_clu_id = sp.cids(i);
        idx = find(tbl.cluster_id == current_clu_id);
        current_clu_chan = tbl.ch(idx);
        current_clu_shank = anat_group(current_clu_chan+1);
        current_shank_chans = find(anat_group == current_clu_shank);

    % get spike waveform time indexes
        myT = Res(find(Clu == sp.cids(i)));% spikes of current cluster
        %Lag = [-40:42];% Lag = [-15:40];this was for my OE data at antons
        myT(myT<1-Lag(1) | myT>nSamples-Lag(end))=[]; % eliminate spikes to close to start/end of file
        nLag = length(Lag);
        nmyT = length(myT);
        myTLagged = reshape(bsxfun(@plus,myT, Lag),[],1); % idxs into dat file for each spike

        display(' ');
        tt = [num2str(i),'/',num2str(length(sp.cids)), ',  cluID=', num2str(current_clu_id),',  ',...
            str{sp.cgs(i)},',  shank=', num2str(current_clu_shank), ',  n_spikes=', ...
            num2str(length(myT)), ',  chan=', int2str(current_clu_chan)];
        display(char(tt));
        display(' ');
                
    % bring in all individual spikes
        %Amp = mmap.Data.x(:,myTLagged); % takes too much memory?
        %Amp = reshape(Amp, nChannels, nmyT, nLag); % takes too much memory?
        Amp = mmap.Data.x(current_shank_chans,myTLagged);
        Amp = reshape(Amp, length(current_shank_chans), nmyT, nLag);


    % from the current shank, consider only good channels
        good_chans_shank = intersect(good_chans_all,current_shank_chans); % abs chan. values
        good_chans_idx = good_chans_shank - current_shank_chans(1)+1;
        
        Amp = Amp(good_chans_idx,:,:); % remove irrelevant channels
        mn = repmat(mean(Amp,3),[1, 1, size(Amp,3)]); % all the waveforms across whole electrode space
        mAmp = double(Amp)-mn; % mean corected spike waveforms
        mW = squeeze(mean(mAmp,2)); %
        sdW = squeeze(std(mAmp,[],2)); %


    % find max amp waveform/channel
        % looks for non inverted waveforms too
        %[~,cluCh(i)] =max(max(-mW'));
        [tmp1Amp,tmp_idx_1] =max(max(-mW'));
        [tmp2Amp,tmp_idx_2] =max(max(mW'));

        [a,b] = max([tmp1Amp tmp2Amp]);
        if b == 1
            cluCh(i) = good_chans_shank(tmp_idx_1);% ch num. referenced at 1 not at 0!            
            tmpCh = tmp_idx_1;%index of chosen channel in the current matrix
            tmpAmp = tmp1Amp;
            invFlg = 1;
            %disp([num2str(cluCh(i))]);
        else
            cluCh(i) = good_chans_shank(tmp_idx_2);% ch num. referenced at 1 not at 0!
            tmpCh = tmp_idx_2;%good_chans_idx(tmp_idx_2);
            tmpAmp = tmp2Amp;
            invFlg = -1;
            %disp([num2str(cluCh(i))]);
        end

    % get main channel waveform
        cluMeanWaveform{i} = mW(tmpCh,:); % cluCh(i)
        cluStdWaveform{i} = sdW(tmpCh,:); % cluCh(i)
        cluShank(i) = current_clu_shank;
        
    % extract slope of AP forward and back propagation
        SR = sp.sample_rate;
        ResCoef = 10; % upsample factor WAS CHANGED ON Aug.30 2005!!!!!!!!!!
        Sample2Msec = 1000/SR/ResCoef; %to get fromnew samplerate to the msec


        test = mean(Amp,2);
        test = sq(mean(Amp,2))';
        test = resample(test,ResCoef,1);
        

        % for visualisation - offset channels for plotting, offset minima, too
        % to offset correctly take into account missing channels
        ofs = max(test(:))*1;
        %wv_vis = test + repmat([0:ofs:ofs*(size(test,2)-1)],[size(test,1),1]); % without gaps!
        wv_vis = test + repmat(ofs.*(good_chans_idx-1)',[size(test,1), 1]);
        [mnAmp mnLoc] = min(wv_vis);


        % get central channel as tmpCh or refind as min(min)
        %[mn ch] = min(min(test));
        % use tmpAmp and tmpCh instead of recalculating
        
        % find 7 channels above/below the max 7*28 = 196um above and 196 below 
        % the dominant channel. For now we will do by n of channels rather than micrometers
        
        %ch_subset_idx = [ch-15:2:ch+15]+1;
        ch_subset = [cluCh(i)-15:2:cluCh(i)+15]+1;
        ch_subset(ch_subset < 1 | ch_subset > length(anat_group)) = []; 
        current_anat_group = anat_group(cluCh(i));
        % remove out-of-shank channels
        ch_subset_groups = anat_group(ch_subset);       
        % remove electrodes from other shanks
        ch_subset(ch_subset_groups ~= current_anat_group) = [];
        % remove not good channels
        [C,IA] = setdiff(ch_subset,good_chans_shank);
        ch_subset(IA) = []; % nearby channels, actual channel number
        [C,IA,ch_subset_idx] = intersect(ch_subset,good_chans_shank);
        
        if length(ch_subset) < 16 % we are close to the end of the shank or chs missing
            flg = 1;
            disp ' cluster close to end of shank, incomplete channel subset';
        else 
            flg = 0;
        end
        
    % select channels with enough of a trough
        % out of these channels, get the ones with amplitude > 12% of max
        chs_with_waveform = find(abs(min(invFlg.*test(:,ch_subset_idx))) > abs(0.12*tmpAmp));
        chs_with_waveform = ch_subset_idx(chs_with_waveform);
        
        % could do z-scores instead
        zdata = test(:,ch_subset_idx);zdata = zscore(zdata(:));zdata = reshape(zdata,[820, length(ch_subset_idx)]);
        loc = find(min(zdata)< -1);
        chs_with_waveform_z = ch_subset_idx(loc);
        

    % plot for vis
        close;
        figure('pos',[1927 233 613 395]); 

        subplot(121); 
            plot(wv_vis(:,ch_subset_idx),'k'); hold on; axis tight;set(gca, 'visible', 'off'); 
            plot(wv_vis(:,tmpCh),'r','Linewidth',1.5); % find(good_chans_shank == cluCh(i))

            plot(mnLoc(chs_with_waveform),mnAmp(chs_with_waveform),'or');
            % plot(mnLoc(chs_with_waveform),mnAmp(chs_with_waveform),'.r');
            plot(mnLoc(chs_with_waveform_z),mnAmp(chs_with_waveform_z),'xb');

        subplot(122); 
            imagesc(test(:,ch_subset_idx)');  axis tight;set(gca, 'visible', 'off'); axis xy; colormap autumn; clb = colorbar; ylabel(clb,'amp. (\muV)');

        clm = get(gca,'clim');
        clm = clm.*1.2;
        set(gca,'clim',clm);
        mtit(tt);%['cluID: ',num2str(current_clu_id)]);
        drawnow;
        export_fig(fullfile(pwd,'clu_figs',num2str(current_clu_id)),'-jpg','-nocrop');

    % get the spatial delay um/ms in 1D
        [Vx tx] = min(test(:,chs_with_waveform));
        ii = find(chs_with_waveform == tmpCh);

        chs_x = sp.xcoords(chs_with_waveform);
        chs_y = sp.ycoords(chs_with_waveform);

        if ii ~= 1 
            pfit_1 = polyfit(tx(1:ii)',chs_y(1:ii),1); % degrees but irrelevant: atand(pfit(1))
            disp(['below soma speed: ', num2str(pfit_1(1)), ' um/ms']);
        else 
            pfit_1 = nan;
        end
        if ii ~= length(tx)
            pfit_2 = polyfit(tx(ii:end)',chs_y(ii:end),1);
            disp(['above soma speed: ', num2str(pfit_2(1)), ' um/ms']);
        else 
            pfit_2 = nan;
        end    
        
        cluSpatialProps(i).cluID = current_clu_id;
        cluSpatialProps(i).slope_below_soma = pfit_1(1);
        cluSpatialProps(i).extent_below_soma = abs(chs_y(1)-chs_y(ii));
        cluSpatialProps(i).slope_above_soma = pfit_2(1);
        cluSpatialProps(i).extent_above_soma = abs(chs_y(ii)-chs_y(end));
        cluSpatialProps(i).chs_with_waveform = chs_with_waveform;% local channel number not probe
        cluSpatialProps(i).chs_with_waveform_z = chs_with_waveform_z;% local channel number not probe
        cluSpatialProps(i).chs_x = chs_x;
        cluSpatialProps(i).chs_y = chs_y;
        cluSpatialProps(i).main_ch = cluCh(i);
        cluSpatialProps(i).chs_around_idx = ch_subset_idx;
        cluSpatialProps(i).chs_around = good_chans_shank;
        cluSpatialProps(i).all_shank_waves= test;
        cluSpatialProps(i).troughTimes = tx;
        cluSpatialProps(i).troughAmps = Vx;
        cluSpatialProps(i).incompleteElectrodeSet = flg;
        
        %fprintf(fID, '%6.2f\n', i); % for debugging
        %pause(2);
        
    end
    
    save('cluSpatialProps.mat','cluSpatialProps');
    save('cluMeanWaveform.mat', 'cluMeanWaveform');
    save('cluStdWaveform.mat', 'cluStdWaveform');
    save('cluChannel.mat', 'cluCh');
    save('cluShank.mat', 'cluShank');

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