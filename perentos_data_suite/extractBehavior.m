themfunction [peripherals] = extractBehavior(fileBase,varargin)
    % this runs best on single sessions. For batches its better to run the
    % video processing separately, at least the parameter initialisations
    % extractBehavior.m goes through a carousel recording and extract the
    % following parameters:
    % 1. carousel position. 
    % 2. TTLs that correspond to points of interest around carousel.
    %  (1, 3 or 2 pulses for LHS cage, RHS cage and start point, respectively)
    % 3. licks from lick sensor as events)
    % 4. respiration from OB???? as respiration
    % 5. nose position if it has been created from DLC (to be confirmed)
    % 6. pupil size
    % 7. Facial videos PCAs

%% INPUT PARSING
    tic;
    options = {'respCh',[], 'resp',0,'events',0,'runSpeed',0,'carouselSpeed',0,'position',0,'direction',0,'licks',0,'vidPulses',0,'pupil',0,'faceROIs',0,'videoPCs',0}; % 1 for compute/recompute
    options = inputparser(varargin,options);
    if strcmp(options,'error'); return; end;

    % check peripherals.mat contents, if it exists
    varList = {'resp','events','runSpeed','carouselSpeed','position','direction','licks','vidPulses','pupil','faceROIs','videoPCs'};
    flags = zeros(1,length(varList));
    if exist(fullfile(getfullpath(fileBase),'peripherals.mat'))
        matObj = matfile(fullfile(getfullpath(fileBase),'peripherals.mat'));
        for  i = 1:length(varList)
            flags(i) = isfield(matObj.peripherals,varList{i}) & ~options.(varList{i});
        end
    end
    

%% INITIALISE PUPIL DETECTION
    trackPupilMorpho(fileBase,1,0); % initialise pupil detection
    frameDiffROIs(fileBase,1,0);    % initialise face ROIs


%% EXTRACT BEHAVIORAL VARIABLES FROM ADC CHANNELS
    processedPath = getfullpath(fileBase);
    if exist([processedPath,'peripherals.mat'],'file') == 2
        disp 'loading preprocessed peripherals';
        load([processedPath,'peripherals.mat']);
    end
    if ~all(flags) % at least one variable is missing...
        disp 'generating peripheral channels';
        % get all channels into workspace
        [data,settings,tScale] = getLFP(fileBase);
        xml = LoadXml(fullfile(processedPath,fileBase));

        % find the respiration channel
        if isempty(options.respCh)
            options.respCh= str2double(searchMasterSpreadsheet(fileBase,'respCh'));
            warning('check thatspreadsheet has absolute channel and not offset inside an electrode group');
        end  
        % T = readtable('/storage2/perentos/datda/recordings/animals_and_recording_session_particulars.xlsx','Sheet','AnalysisVars');
        % tmp = str2num(cell2mat(T.respCh(find(strcmp(fileBase,T.Session)))));
        % options.respCh = xml.ElecGp{end-1}(tmp);


        [chanTypes] = getChanTypes(settings);
        chPeriph = find(chanTypes == 2); % this type is the ADC channel which is the pressure sensor
        if numel(chPeriph) == 4
            runCh = chPeriph(1); lickCh = chPeriph(2); carouselCh = chPeriph(3); rewardCh = chPeriph(4); 
        elseif numel(chPeriph) == 5
            runCh = chPeriph(1); lickCh = chPeriph(2); carouselCh = chPeriph(3); rewardCh = chPeriph(4); vidPulsesCh = chPeriph(5);
        elseif numel(chPeriph) == 8 %(photometry on 6 and empty on 7&8)
            runCh = chPeriph(1); lickCh = chPeriph(2); carouselCh = chPeriph(3); rewardCh = chPeriph(4); vidPulsesCh = chPeriph(5); AChPulsesCh = chPeriph(6);
        else
            error('I was expecting 4 or 5 ADC channels - please check');
        end

        % need 30kHz to detect all the pulses from encoders
        [data30k,settings30k,tScale30k] = getDAT(fileBase,chPeriph);

        if ~flags(find(strcmp(varList,'resp')));            peripherals.resp =          getRespFreq(data(options.respCh,:),1/tScale(1)); end
        if ~flags(find(strcmp(varList,'events')));          peripherals.events =        getRewards(data30k(4,:)); end
        if ~flags(find(strcmp(varList,'runSpeed')));        peripherals.runSpeed =      getRunSpeed(data30k(1,:)); end
        if ~flags(find(strcmp(varList,'carouselSpeed')));   peripherals.carouselSpeed = getCarouselSpeed(data30k(3,:)); end
        if ~flags(find(strcmp(varList,'position')));       [peripherals.position, peripherals.direction] = getCarouselPosition(data30k(3,:),peripherals.events); end %location        = getLocation(data30k(3,:),rewards);    % CAROUSEL LOCATION for single direction%locationTD        = getLocationTwoDirections(ch,rewards); % for bidirectional CAROUSEL LOCATION
        if ~flags(find(strcmp(varList,'licks')));           peripherals.licks =         getLicks(data(lickCh,:)); end
        if numel(chPeriph) == 5
            if ~flags(find(strcmp(varList,'vidPulses'))); peripherals.vidPulses = getVidTimes(data30k(5,:)); end
        end
        if numel(chPeriph) == 8 || numel(chPeriph) == 6 
            if ~flags(find(strcmp(varList,'vidPulses'))); peripherals.vidPulses = getVidTimes(data30k(5,:)); end
            % if flags(find(strcmp(varList,'AchPulses'))); out.AchPulses = getVidTimes(data30k(6,:)); end
        end
    end

%% PROCESS VIDEOS    
    % extract pupil size and position
    if ~flags(find(strcmp(varList,'pupil'))); [peripherals.pupil] = trackPupilMorpho(fileBase,0,1); end 
    % compute a frame difference for the face camera
    if ~flags(find(strcmp(varList,'faceROIs'))); [peripherals.faceROIs] = frameDiffROIs(fileBase,0,1); end
    % video frame SVDs
    if ~flags(find(strcmp(varList,'videoPCs'))); [peripherals.videoPCs] = videoSVD(fileBase,1,1); end   


%% SAVE EVERYTHING INTO A BIG STRUCTURE CALLED PERIPHRELAS
    if exist('peripherals')
        disp('saving ''peripherals'' structure to ''peripherals.mat''...');
        save(fullfile(getfullpath(fileBase),'peripherals.mat'),'peripherals','-v7.3');
        disp('saved');
    else
        display('data was loaded from file');
    end

    toc;
    
%% GENERATE A LARGE MATRIX CONTAINING THE BEHAVIORAL VARIABLES
    display('generating final ''behavioral'' matrix');
    peripheralsPP (fileBase);

