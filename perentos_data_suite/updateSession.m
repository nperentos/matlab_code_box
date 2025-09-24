function updateSession(fileBase)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function updateSession(fileBase) is a function that quickly checks the
% carouselDatabase spreadsheet for any potentially new information that
% could have been added to a particular session and it updates
% the session.mat variable. It essentially avoids the time consuming
% recomputations of lfp derived and auxiliary channel derived variables. 
% probably the easiest would be to always call it e.g. inside
% combineVidAuxVars which itself runs fast also. 
% A more clean solution would be to move this session generation into the
% combineVidAuxVars but I am too lazy for this.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% PRE 
    % load the xml session data (e.g. get sampling rate)  
    processedPath = getfullpath(fileBase);
    cd(processedPath);
    pth = fullfile(getfullpath(fileBase),[fileBase,'.lfp']);
    par = LoadXml([pth(1:end-4),'.xml']);
    SR_LFP = par.lfpSampleRate;
    SR_WB = par.SampleRate;
    s = dir([processedPath,fileBase,'.lfp']);
    nSamples_LFP = s.bytes/(par.nChannels*2);% 2 b/c data is 16 bit ints => 2 bytes per datapoint
    s = dir([processedPath,fileBase,'.dat']);
    nSamples_WB  = s.bytes/(par.nChannels*2);% 2 b/c data is 16 bit ints => 2 bytes per datapoint
    nn = 1; % row offset into the final matrix of variables. Also used for the names variable
    fprintf('loading session data...\n');
    [session, behavior] = loadSession(fileBase);
    
    if strcmp(session.info.taskType,'continuous')
        session.helper.position_context = ['none'];
    elseif strcmp(session.info.taskType,'controlled') || strcmp(session.info.taskType,'controled')
        if ~isfield(session.helper,'position_context')
            error('position_contexts are missing. You must rerun generateAuxVars function');
        else
            %if strcmp('1:toR2:fromR3:toL4:fromL5:atO6:atL7:atR',session.helper.position_context.labels)
            session.helper.position_context.labels = '1:toR2:fromR3:toL4:fromL5:atO6:atR7:atL'; % there was an error in the text for this labels
            %end
        end
    else
        error('cannot plot for task types other than continuous and controlled...');
    end 
    

    
%% INFO
    % get the master spreadsheet - should contain everything we need here
    T = getCarouselDataBase;
    o = find(strcmp(T.session,fileBase));
    if length(o) ~= 1
        error('there seem to be multiple files with the same session number?');
    end
    session.info.fileBase = T.session{o};
    %session.info.rejTrials = eval(T.rejTrials{109}); % try to use this to skip trials that are problematic. For the mo, only employed for NP51....50-28 
    session.info.nBlocks = str2num(T.blocks{o});
    session.info.trialsPerBlock = str2num(T.trialsPerBlock{o});
    session.info.conditions = split(T.blockConditions{o},',');
    session.info.manipulationPosition = T.manipulationPosition{o};
    session.info.protocolComplete = T.protocolComplete{o};
    session.info.SR_LFP = SR_LFP;
    session.info.SR_WB = SR_WB;
    session.info.nSamples_LFP = nSamples_LFP;
    session.info.nSamples_WB = nSamples_WB;
    session.info.probes{1} = T.probe1{o};
    session.info.probes{2} = T.probe2{o};
    session.info.targets{1} = T.target1{o};
    session.info.targets{2} = T.target2{o};
    session.info.fluoMarkers{1} = T.fluoMarker1{o};
    session.info.fluoMarkers{2} = T.fluoMarker2{o};
    session.info = rmfield(session.info,'comments')
    session.info.comments.notes = T.notes{o};
    session.info.goodVidVars.names = {'pupil','wSVD','sSVD','nose','whiskers'}';
    session.info.breakEpochs = findProtocolBreaks(fileBase);
    for i = 1:length(session.info.goodVidVars.names)
        try
            test = T.(session.info.goodVidVars.names{i}); %pupil{o}),str2num(T.wSVD{o}), str2num(T.sSVD{o}), str2num(T.nose{o}), str2num(T.whiskers{o})];
            if isempty(test{o})
                session.info.goodVidVars.val(i) = 0;
            else
                session.info.goodVidVars.val(i) =  str2num(test{o});
            end
            %session.info.goodVidVars.val =  [str2num(T.pupil{o}),str2num(T.wSVD{o}), str2num(T.sSVD{o}), str2num(T.nose{o}), str2num(T.whiskers{o})];
        catch
            disp('possibly incomplete session.info.goodVidVars .... please check')
            session.info.goodVidVars.val(i) = 0;
        end
    end    
    %     try
    %         info.nTrials = length(events.TTL.atStart);
    %     catch
    %         info.nTrials = 0;
    %     end
    session.info.taskType =  T.taskType{o};% continuous or controlled (closed or open loop)
    % find previous day condition
    try
        for i = 1:min([10 o]) % we go max 10 sessions back (no animal has 10 recordings within the same day)
            prev = days(datetime(fileBase(6:end),'InputFormat','yyyy-MM-dd_HH-mm-ss')-...
                datetime(T.session{o-i}(6:end),'InputFormat','yyyy-MM-dd_HH-mm-ss'));% fileBase of this mouse's previous session
            if prev > 0.9
                prev = o-i;
                % if its ripples or settle or approach go back one more
                cont = 1;
                while cont 
                    if strcmp(T.manipulation{prev},'ripples') ||...
                            strcmp(T.manipulation{prev},'settle') ||...
                            strcmp(T.manipulation{prev},'aborted') ||...
                            strcmp(T.manipulation{prev},'failed') ||...
                            strcmp(T.manipulation{prev},'approach')
                        prev = prev - 1;
                    else
                        cont = 0;
                    end
                end
                session.info.previousSession.fileBase = T.session{prev};
                session.info.previousSession.manipulation = T.manipulation{prev};
                break;
            end
        end
    catch
        session.info.previousSession.fileBase = [];
        session.info.previousSession.manipulation = [];
    end
    %     if strcmp(events.TTL,'no pulses available')
    %         info.breakDurations = [];
    %     else
    %         info.breakDurations = floor(max(diff(events.TTL.atStart)/(60*par.lfpSampleRate))); % this is susceptble to 
    %     end
    % get number of cells if possible
    try
        sp = loadKSdir(pwd);
        session.info.nClusters.SUA = length(find(sp.cgs == 1));
        session.info.nClusters.MUA = length(find(sp.cgs == 2));
    catch
        session.info.nClusters.SUA = NaN;
        session.info.nClusters.MUA = NaN;
    end



%% SAVE 
%
    % session.info = info;
    % session.events = events;    
    %session.helper = helper;
    % behavior.name = behavior.name';
    fprintf('saving session info in session.mat ...');
    save(fullfile(processedPath,'session.mat'),'session','-v7.3');
    % save(fullfile(processedPath,'behavior_interim.mat'),'behavior','-v7.3');
    fprintf('DONE\n');

    %     fprintf('generating some report figures...');
    %     figure('pos',get(0,'screensize').*[1 1 0.4 0.4]); 
    %     plot(tScale,behavior.data(find(strcmp(behavior.name,'position')),:));
    %     xlabel('time (s)'); ylabel('position (deg)'); title('carouselPosition');    
    %     print(fullfile(getfullpath(fileBase),'positionByTime.jpg'),'-djpeg');
    % %    
    %     figure('pos',[127 181 1558 1640]); 
    %     imagesc(zscore(behavior.data));
    %     set(gca,'YTick',[1:1:size(behavior.data,1)],'YTickLabel',behavior.name,'TickLabelInterpreter','none');    
    % %    
    %     print(fullfile(getfullpath(fileBase),'interim_behavior_table.jpg'),'-djpeg');
    %     fprintf('DONE\n')