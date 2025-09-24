function [out] = getCluChans(pth,varargin)

%%%%%%%%%%%%%%%%%%%%%%%%%%% getCluChans.m %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% getCluChans assigns a channel to each cluster coming out of kilosort 2
% after manual curation. It achieves this using two methods. The first and
% fast method uses the templates that are saved by the kilosort algorythm,
% while the second, slow method loads spikes directily from the dat file, 
% reconstructs the mean waveform in all channels and finds the max amp
% channel. The reason for using two methods is that the first may be error
% prone after manual curation. Its not clear whether new templates are
% saved for new cluster numbers. Finally waveforms on neighbouring channels
% are also extracted and the .clu and .res files are saved in the kilosort
% folder for back compatibility. Let me know if you run into trouble
%
% INPUTS:
% pth: full path to KS folder containing all the npy and mat variables AND
% the dat file or a link to the dat file
% plot: visualise the cluster waveforms in electrode space
% raw:  if 1, extracts raw waveforms from dat file (which can take long)
%
%OUTPUTS:
% out.CluChTempl: channel assignment based on templates
% out.CluChRaw:   channel assignment based on raw (mean corrected) waveforms
% out.wvsTmpl:        waveforms on surrounding channels  
% out.wvsRaw:        waveforms on surrounding channels  
% NPerentos - 18/10/2019
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


options = {'plot',0, 'raw', 1};% options = {'plot',0, 'raw', 1,'recompute',0};
options = inputparser(varargin,options);

% %load if pre computed? Checks one folder up from KS for cluChans.mat
% [a,b] = fileparts(pth);
% if isempty(b); [a,b] = fileparts(a);
% end
% if ~options.recompute & exist(fullfile(a,'cluChans.mat'))
%     load(fullfile(a,'cluChans.mat')); 
%     display('loaded precomputed data. If you want to recompute set recompute flag to high');
%     out=cluChans;
%     return;
% end


%% ASSIGN A CHANNEL TO EACH CLUSTER USING THE TEMPLATES VARIABLE (quick but may contain errors)
display('loading data');
sp = loadKSdir(pth);
chmap = readNPY(fullfile(pth,'channel_map.npy')); % this is useful for 
% identifying channels to ignore when forming the average spike waveforms. 
% Its possible for example that an analog IN channel sitting on negative rail 
% will make all clusters look like they are on that channel
display('extracting cluster channels from templates');
cluCh = zeros(1,length(sp.cids));
for i = 1:length(sp.cids)
    try
        tmp = squeeze(sp.temps(sp.cids(i)+1,:,:));
        [Y,cluCh(i)] =max(max(-tmp));
        % extract surrounding channels
        if cluCh(i) > 5 & cluCh(i) < length(chmap) - 5
            out.wvsTmpl{i} = tmp(:,cluCh(i)-5:cluCh(i)+5)';
        elseif cluCh(i) < 5
            out.wvsTmpl{i} = tmp(:,1:11)';        
        elseif cluCh{i} < length(chmap) - 5
            out.wvsTmpl{i} = tmp(:,end-10:end)';
        end
    catch
        display('cluster number exceeds available number of templates - please investigate');
    end
    
end


if options.plot
    figure; set(gcf,'pos',[2762 1336 980 702]);
    for i = 1:length(sp.cids)
        clf;
        % assign channel to each cluster (irrespective of cluster quality)
        try
            tmp = squeeze(sp.temps(sp.cids(i)+1,:,:));
        catch
            display('cluster number exceeds available number of templates - please investigate');
            continue;
        end            
        %[Y,cluCh(i)] =max(max(-tmp));
        imagesc([],[],tmp'); axis xy; 
        caxis([-1 1].*max(abs(tmp(:)))) 
        mycl = colormap;
        mycl(32:33,:) = [1 1 1; 1 1 1]; 
        colormap(mycl);
        xlabel('spike time (samples)'); ylabel('channel');
        hold on;

        % mark the location on the plot
        [~,I] = max(-tmp(:,cluCh(i)));
        plot(I,cluCh(i),'ok','markersize',8,'linewidth',3,'markerfacecolor','w');

        % plot normalised waveform 
        wv = tmp(:,cluCh(i));
        wv = wv-min(wv);
        wv = wv./max(wv).*size(tmp,2);
        plot(wv,'k','linewidth',3);    

        % add label
        if sp.cgs(i) == 1
            text(2,10,['MUA',num2str(sp.cids(i)),' (ch:',num2str(cluCh(i)),')'],'color',[.6 .6 .6],'fontsize',20);
        elseif sp.cgs(i) == 2
            text(2,10,[' SU',num2str(sp.cids(i)),' (ch:',num2str(cluCh(i)),')'],'color','b','fontsize',20);
        else
            text(2,10,['---'])
        end
            
        drawnow;       
        %waitforbuttonpress;
    end
end

out.CluChTmpl = cluCh; % cluster channel assignment from template


%% SAVE CLUSTERS IN OLD FORMAT
FileBase = dir(fullfile(pth,'*.dat'));
FileBase = FileBase.name(1:end-4);
Res = round(sp.st * sp.sample_rate);
Clu = sp.clu;
msave(  fullfile(pth,[FileBase, '.res.1']),Res);
SaveClu(fullfile(pth,[FileBase, '.clu.1']),Clu);


%% ASSIGN A CHANNEL TO EACH CLUSTER USING THE RAW DATA (slow - but atm necessary due to some bugs that arise after manual curation IN phy)
if options.raw
    % map dat file
    clear cluCh;
    FileName = dir(fullfile(pth,'*.dat'));
    FileName = fullfile(FileName.folder,FileName.name);
    nSamples = FileLength(FileName)/2/sp.n_channels_dat;
    nChannels = sp.n_channels_dat;
    mmap = memmapfile(FileName, 'format',{'int16' [nChannels nSamples] 'x'},'offset',0,'repeat',1);

    % assign channel to cluster
    figure; set(gcf,'pos',[2762 1336 980 702]);
    for i = 1:length(sp.cids)
        display(['unit',num2str(i),'/',num2str(length(sp.cids))])
        myT = Res(find(Clu == sp.cids(i)));% spikes of current cluster    
        Lag = [-15:40];
        myT(myT<1-Lag(1) | myT>nSamples-Lag(end))=[]; % eliminate spikes to close to start/end of file
        nLag = length(Lag);
        nmyT = length(myT);
        myTLagged = reshape(bsxfun(@plus,myT, Lag),[],1); % idxs into dat file for each spike   
        Amp = mmap.Data.x(:,myTLagged);
        Amp = reshape(Amp, nChannels, nmyT, nLag);  
        Amp = Amp(chmap+1,:,:); % remove irrelevant channels 
        mn = repmat(mean(Amp,3),[1, 1, size(Amp,3)]); % all the waveforms across whole electrode space
        mAmp = double(Amp)-mn; % mean corected spike waveforms
        mW = squeeze(mean(mAmp,2)); % 


        % find max amp waveform/channel
        [~,cluCh(i)] =max(max(-mW')); 
        % extract surrounding channels
        if cluCh(i) > 5 & cluCh(i) < length(chmap) - 5
            out.wvsRaw{i} = mW(cluCh(i)-5:cluCh(i)+5,:);
        elseif cluCh(i) < 5
            out.wvsRaw{i} = mW(1:11,:);        
        elseif cluCh{i} < length(chmap) - 5
            out.wvsRaw{i} = mW(end-10:end,:);
        end


        % visualise
        if options.plot
            imagesc([],[],mW); axis xy; 
            caxis([-1 1].*max(abs(mW(:)))) 
            mycl = colormap;
            mycl(32:33,:) = [1 1 1; 1 1 1]; 
            colormap(mycl);
            xlabel('spike time (samples)'); ylabel('channel');
            hold on;        
            [~,I] = max(-mW(cluCh(i),:));
            plot(I,cluCh(i),'ok','markersize',8,'linewidth',3,'markerfacecolor','w');       
            % plot normalised waveform 
            wv = mW(cluCh(i),:);
            wv = wv-min(wv);
            wv = wv./max(wv).*size(tmp,2);
            plot(wv,'k','linewidth',3); 

            % add label
            if sp.cgs(i) == 1
                text(2,10,['MUA',num2str(sp.cids(i)),' (ch:',num2str(cluCh(i)),')'],'color',[.6 .6 .6],'fontsize',20);
            elseif sp.cgs(i) == 2
                text(2,10,[' SU',num2str(sp.cids(i)),' (ch:',num2str(cluCh(i)),')'],'color','b','fontsize',20);
            else
                text(2,10,['---'])
            end    
            drawnow;
            %waitforbuttonpress;
        end

    end

    out.CluChRaw = cluCh; % cluster channel assignment from template
end

































