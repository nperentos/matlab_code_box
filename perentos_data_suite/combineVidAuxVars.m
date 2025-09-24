function combineVidAuxVars(fileBase,varargin)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% combineVidAuxVars(fileBase) puts together the outputs from generateAuxVars
% (behavior_interim.mat) and getVidVars (all_video_results.mat)
% into a big structure called session

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
disp('combining video and auxiliary variables into one matrix at lfp rate');

%% PRE

    options = {'ifPlot',1,'noVidFlag',0,'downsample_rate',10};
    options = inputparser(varargin,options); 

    processedPath = getfullpath(fileBase);
    cd(processedPath);
    pth = fullfile(getfullpath(fileBase),[fileBase,'.lfp']);
    par = LoadXml([pth(1:end-4),'.xml']);
    SR = par.lfpSampleRate;
    %[~,settings,tScale] = getLFP(fileBase);
    s = dir([processedPath,fileBase,'.lfp']);
    tMax = s.bytes/(SR * par.nChannels*2);% 2 b/c data is 16 bit ints => 2 bytes per datapoint
    tScale = [1/SR:1/SR:tMax]; 
    
    
    
%% IMPORT INTERIM DATA
    if exist(fullfile(processedPath,'all_video_results.mat')) == 2
        load(fullfile(processedPath,'all_video_results.mat'));
    else
        if exist(fullfile(getFullPath(fileBase),'video')) == 7
            error('there is a video folder but all video results.mat was not created. Please investigate');
        else
           noVidFlag = 1;
           % for now throw error till I decide what to do
           error('there is a video folder but all video results.mat was not created. Please investigate');
        end
    end                    
    load(fullfile(processedPath,'behavior_interim.mat'));
    load(fullfile(processedPath,'session.mat'));
    

    
%% UPSAMPLE THE VIDEO VARIABLES
    if ~isempty(videoFeatures)
        disp('upsampling video features to LFP rate... CANT WE AVOID THIS??');
        n1 = sum(session.helper.vidPulses); n2 = length(videoFeatures.data);
        % its possible that there are stray pulses in the ADC channel (due
        % to drift at onset or offset of pulse trains so we should eliminate them
        % we eliminate by finding pulses that are not 1/30s apart
        if n1 > n2
            tmp1 = find(session.helper.vidPulses ~= 0); % pulse positions
            tmp2 = diff(tmp1);
            tmp3 = find(tmp2 > 31 & tmp2 < 35); % fixed to 30 Hz unfortunately
            %special case for the last pulse
            if tmp3(1) == 1 & tmp1(tmp3(end)) ~= tmp1(end)% first pulse is good so add another pulse at the end to account for the diffing? This is untested however
                tmp3 = [1, tmp3+1];
            end
            tmp1 = tmp1(tmp3);
            mockPulses = session.helper.vidPulses; mockPulses(mockPulses ~= 0) = 0;
            mockPulses(tmp1) = 1;
            session.helper.vidPulses = mockPulses;
            clear tmp1 tmp2 tmp3
        end
            
        n1 = sum(session.helper.vidPulses); n2 = length(videoFeatures.data);
        n = abs(n1-n2);
        if n > 2; warning('the number of pulses and video-derived behavior data differ by more than two frames. Please investigate'); end
        % still, it is possible that carousel protocol was terminated
        % abnormaly. We will need special cases hardcoded if this was the
        % case
        % NP43_2019-12-08_18-33-23: OE recordng was terminated by accident
        % so there are more frames (~900 extra) than vid pulses
        clear tmp ztmp
        if      strcmp(fileBase,'NP43_2019-12-08_18-33-23')
            % extra frames at the END to dropped
            rmv = sum(session.helper.vidPulses) + 1:length(videoFeatures.data);
            videoFeatures.data = videoFeatures.data(1:sum(session.helper.vidPulses),:);            
            tmp = interp1(tScale(session.helper.vidPulses==1),videoFeatures.data,tScale,'linear','extrap');
            shft = 0;
        elseif  strcmp(fileBase,'NP53_2020-06-11_14-09-15')
            rmv = [1:n];shft = n;
            % extra frames at the START to drop (OE was not setup o accept
            % network event so did not start through matlab on time and was
            % started manualy instead?)
            videoFeatures.data = videoFeatures.data(n+1:end,:);% end-sum(session.helper.vidPulses)+1:end,:
            tmp = interp1(tScale(session.helper.vidPulses==1),videoFeatures.data,tScale,'linear','extrap');
        elseif  strcmp(fileBase,'NP43_2019-12-11_16-08-24')            
            % first we assume that n frames were collected before the
            % start of OE rec and so no vid pulses are available. This is evident
            % because unlike the usual case where videopulses begin with a
            % delay of several seconds from neural data start, in this recording
            % there are pulses straight from the begining, then they stop
            % and then appear again which indicates some malfunction
            % So we trim by n the videoFeatures from the start side.
            videoFeatures.data(1:n,:) = []; % 148 more vid frames than pulses
            % but there are loose pulses for the first 2.3 seconds (arduino
            % error?) for which we do have pulses but we do not want to
            % keep so we will trim those from both vidPulses as well as
            % videoFeatures
            % when rerunning this session/function IDX below comes up as
            % empty => not needed?
            pls = find(session.helper.vidPulses);
                        IDX = find(diff(pls) > mode(diff(pls))+10);
                        session.helper.vidPulses(1:pls(IDX)) = 0;
                        videoFeatures.data(1:IDX,:) = []; 
                        rmv = [1:n+IDX];
                        shft = max(rmv); % b/c at start saccades need to be shifted accordingly
            tmp = interp1(tScale(session.helper.vidPulses==1),videoFeatures.data,tScale,'linear','extrap');
        else
            rmv = [];shft = 0;
            tmp = interp1(tScale(session.helper.vidPulses==1),[zeros(n,size(videoFeatures.data,2)); videoFeatures.data],tScale,'linear','extrap');
        end
        % saccades are a point process so lets restore it to 0s and 1s
        load saccades.mat;
        pls = find(session.helper.vidPulses); %video pulse positions within the lfp-rate array
        
    % saccades X
        iii = find(strcmp('saccadesX',videoFeatures.name));
        jj = saccades.X.keepI-shft; % saccade positions in the above (pls) indices
        minrmv = min(rmv);maxrmv = max(rmv);
        jjtmp = jj;
        if ~isempty(rmv)
            jjtmp((jjtmp > minrmv & jjtmp < maxrmv) | (jjtmp < maxrmv & jjtmp > minrmv)) = [];
        end
        jj = jjtmp; clear jjtmp;
        tmp(:,iii) = 0; %keep lfp array size but zero everything
        tmp(pls(jj),iii) = 1; % place 1s at saccade indices
        %figure; plot(zscore(tmp(:,2))); hold on; plot(tmp(:,iii));
        
    % saccades Y
        iii = find(strcmp('saccadesY',videoFeatures.name));
        jj = saccades.Y.keepI-shft; % saccade positions in the above (pls) indices
        minrmv = min(rmv);maxrmv = max(rmv);
        jjtmp = jj;
        if ~isempty(rmv)
            jjtmp((jjtmp > minrmv & jjtmp < maxrmv) | (jjtmp < maxrmv & jjtmp > minrmv)) = [];
        end
        jj = jjtmp; clear jjtmp;        
        tmp(:,iii) = 0; % keep lfp array size but zero everything
        tmp(pls(jj),iii) = 1; % place 1s at saccade indices
        %figure; plot(zscore(tmp(:,3))); hold on; plot(tmp(:,iii));        
        
        ztmp = zscore(tmp);
        figure; imagesc(tScale,[],ztmp');caxis([prctile(ztmp(:),[1 99])]);        
        xlabel('time (s)'); ylabel('feature (#)'); title('z-scored behavioral feature activities');
        stampFig(fileBase);
        
    else
        display('no video features available!');
    end

    
    
%% MERGE BEHAVIORAL VARIABLES
    %     if ~isempty(videoFeatures)
    %         behavior.data = [behavior.data',tmp];
    %         behavior.name = [behavior.name;videoFeatures.name];
    %         behavior.info = videoFeatures.info;
    %     else
    %         behavior.data = [behavior.data'];
    %         behavior.name = [behavior.name];           
    %     end
    if ~isempty(videoFeatures)
        data = [behavior.data',tmp];
        name = [behavior.name;videoFeatures.name];
        info = videoFeatures.info;
    else
        data = [behavior.data'];
        name = [behavior.name];   
        info = 'no info here';
    end    
% tScale = 1/SR:1/SR:length(tmp)/SR;
% figure; subplot(211); plot(zscore(data(:,26))); hold on; plot(data(:,end-1));
% subplot(212); plot(zscore(data(:,27))); hold on; plot(data(:,end));          
% linkaxes(get(gcf,'children'),'x');

%% GENERATE A DOWNSAMPLED VERSION OF THE BEHAVIORAL DATA -default is at 10ms
    behavior_downsampled.data = resample(data,SR/options.downsample_rate,SR);
    behavior_downsampled.info = info;
    behavior_downsampled.info.SR = options.downsample_rate;   
    tic;save(fullfile(processedPath,'behavior_downsampled.mat'),'behavior_downsampled');toc

%% SAVE 
    fprintf(['saving auxiliary and video variables into behavior.mat at lfp rate...']);
    % save(fullfile(processedPath,'behavior.mat'),'behavior','-v7.3');
    save(fullfile(processedPath,'behavior.mat'),'data','name','info','-v7.3');
    % update session variable
    save(fullfile(processedPath,'session.mat'),'session','-v7.3');
    print(fullfile(getfullpath(fileBase),'all_behavioral_variables.jpg'),'-djpeg');
    fprintf(['Also resaving the video frame rate video features table in case it was trimmed...']);
    save(fullfile(processedPath,'all_video_results.mat'),'videoFeatures','-v7.3');
    fprintf('DONE\n');
    
    
    
% %% GENERATE POSITION RESOLVED FIGURES FOR EACH BEHAVIORAL VARIABLE
%     disp('generating position resolved plots for behavioral variables...');
%     for i = [2 3 6 7 8 9 10 11 12 13 14 15]
%         carouselPlotVar(fileBase,pppNames{i},1);
%         pause(1); close;
%     end    
