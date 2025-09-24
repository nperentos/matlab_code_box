function goodChannels = getGoodChannels(fileBase,varargin)

% out = getGlobalMean(fileBase,varargin) computes global mean across all
% non rejected and non auxiliary channels. Channels are rejected based on
% Euclidean distance between pairs of observations. with a threshold of 95%
% The options to find components baed on weiweis ICA method is there also
% but not fully implemented. 
% INPUTS: fileBase. A database spreadsheet is expected that holds the theta
% and respiration channel along with other variables. Alternatively, define
% a theta channel using varargin
% OUTPUTS: out is a structure with the .globalMean and some other self
% explanatory variables


%% PRE
    % hardcoded values for testing - to beremoved
    options = {'data',[],'artefactRemovalMethod','mu','resampleType',...
               'interpolate','saveMeanCorrectedData',0};
    options = inputparser(varargin,options);
    if strcmp(options,'error'); return; end;

%     % get the original lfp and xml    
    processedPath = getfullpath(fileBase);
    pth = fullfile(getfullpath(fileBase),[fileBase,'.lfp']);
    par = LoadXml([pth(1:end-4),'.xml']);
    if isempty(options.data)
        [data,settings,tScale] = getLFP(fileBase);
    end
        
% 
%     %     % encoder channel    
%     %     if isempty(options.encoderCh)
%     %         encoderCh = par.AnatGrps(end).Channels(1);
%     %     end
% 
%     % lfpCh - can we create a field in the xml for this??  
%     if isempty(options.thetaCh)
%         thetaCh= str2double(searchMasterSpreadsheet(fileBase,'thetaCh'));
%         disp(['found a theta channel listed as ',num2str(thetaCh)]);
%     end    
%         
%     % if using weiweis EMG removal
%     if strcmp(options.artefactRemovalMethod,'wei')
%         addpath(genpath('/storage/weiwei/matlab/EMG_removing'));
%         %EMG_rm_main(fileBase,[],shank,[],0);
%     end
%     
%     bns = 200; % number of bins for histograms
%     close; figure('units','normalized','outerposition',[0.1 0.1 0.7 0.6]);
    
%% FIND GOOD/BAD CANNELS
% find channels to keep based on skip field of xml
    % probes
    apc = [par.AnatGrps(1:end-2).Channels]+1; 
    kp = ~[par.AnatGrps(1:end-2).Skip]; 
    disp(['probe channels to be skipped (according to xml): ',num2str([find(~kp)])]);
    idx1 = [find(~kp)];
    apc = apc(kp);

    % EEG
    aec = [par.AnatGrps(end-1).Channels]+1; % all EEG channels
    kp = ~[par.AnatGrps(end-1).Skip];    
    disp(['EEG channels to be skipped (according to xml): ',num2str([find(~kp)])]);
    idx2 = [aec(~kp)];
    aec = aec(kp); 
    
    
% find channels to keep based on pdist
    disp('computed electrode interdistance (pdist)');
    
% just the probes first
    chTmp = setdiff([1:par.nChannels],[par.AnatGrps(end-1:end).Channels]+1);
    pd = pdist(zscore(data(chTmp,:)));
    pdsq = squareform(pd);
    pdsq = pdsq - min(pdsq(:));
    pdsq = pdsq./max(pdsq(:));    
    mn = mean(pdsq,1);
    cutoff = prctile(mn,95);   
    [~,idx3] = find(mn>cutoff);
    
    
% probe and EEG together
    chTmp = setdiff([1:par.nChannels],[par.AnatGrps(end).Channels]+1);
    pd = pdist(zscore(data(chTmp,:)));
    pdsq = squareform(pd);
    pdsq = pdsq - min(pdsq(:));
    pdsq = pdsq./max(pdsq(:));    
    mn = mean(pdsq,1);
    cutoff = prctile(mn,95);   
    [~,idx4] = find(mn>cutoff);
    
    
%% SUMMARY PLOT    
    close; figure('units','normalized','outerposition',[0.1 0.1 0.7 0.6]);
    subplot(121); imagesc(pdsq);axis square;
    xlabel('channel');ylabel('channel');title('skip');
    
    subplot(122);plot(mn,'ok','markersize',14,'linewidth',3);% title('bad channels');    
    hold on; 
    plot([idx1,idx2],mn([idx1,idx2]),'xb','markersize',10,'linewidth',2.5);    
    plot([idx3,idx4],mn([idx3,idx4]),'+r','markersize',10,'linewidth',2.5);
    legend('allCh','user-skip','pdist-skip','location','northwest');
    xlabel('channel number');
    ylabel('pdist');
    axis tight;           

    
    %% SAVE
    goodChannels.user.eeg = [aec];
    goodChannels.user.probe = [apc];
    goodChannels.pdist = [idx3, idx4];
    save(fullfile(processedPath,'goodChannels.mat'),'goodChannels');
    print(fullfile(processedPath,'goodChannels.jpg'),'-djpeg');
    
    
%%    