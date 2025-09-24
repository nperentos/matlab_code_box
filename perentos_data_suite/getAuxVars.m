function getAuxVars(fileBase,varargin)

%% PREREQUISITES
    options = {'respCh',[],'thetaCh',[],'pth',[]};
    options = inputparser(varargin,options);
    if strcmp(options,'error'); return; end;
    
    pth = getfullpath(fileBase,options.pth); % processed folder
    cd(pth);

%% GENERATE AUXILIARY CHANNELS
    disp 'generating auxiliary channels...';

% get all channels into workspace
    [data,settings,tScale] = getLFP(fileBase);
    %xml = LoadXml(pth);xml = LoadXml(fullfile(pth,fileBase));
    [chanTypes] = getChanTypes(settings);
    chPeriph = find(chanTypes == 2);

% auxiliary channel assignment (based on known channel port assignments
    if numel(chPeriph) == 4
        runCh = chPeriph(1); lickCh = chPeriph(2); carouselCh = chPeriph(3); rewardCh = chPeriph(4); 
    elseif numel(chPeriph) == 5
        runCh = chPeriph(1); lickCh = chPeriph(2); carouselCh = chPeriph(3); rewardCh = chPeriph(4); vidPulsesCh = chPeriph(5);
    elseif numel(chPeriph) == 8 %(photometry on 6 and empty on 7&8)
        runCh = chPeriph(1); lickCh = chPeriph(2); carouselCh = chPeriph(3); rewardCh = chPeriph(4); vidPulsesCh = chPeriph(5); AChPulsesCh = chPeriph(6);
    else
        error('I was expecting 4 or 5 ADC channels - aborting');
    end 

% try identify theta  and olfactory bulb channels
    if isempty(options.thetaCh)
        options.thetaCh= str2double(searchMasterSpreadsheet(fileBase,'thetaCh'));
        warning('check thatspreadsheet has absolute channel and not offset inside an electrode group');
    end         
    if isempty(options.respCh)
        options.respCh= str2double(searchMasterSpreadsheet(fileBase,'respCh'));
        warning('check thatspreadsheet has absolute channel and not offset inside an electrode group');
    end    
         
% data at 30k res
    [data30k,settings30k,tScale30k] = getDAT(fileBase,chPeriph);
% respiration frequency and phase    
    resp = getRespFreq(data(options.respCh,:),1/tScale(1));
% events (from dedicated arduino pulses)
    events = getRewards(data30k(4,:));
% run speed from the encoder
    runSpeed = getRunSpeed(data30k(1,:));
% carousel speed from the respective encoder
    carouselSpeed = getCarouselSpeed(data30k(3,:));
% position and direction of movement of the carousel
    [position, direction] = getCarouselPosition(data30k(3,:),peripherals.events); 
% lick events
    licks = getLicks(data(lickCh,:)); 
% video frame times (from dedicated arduino pulses)
    if numel(chPeriph) == 5
        vidPulses = getVidTimes(data30k(5,:)); 
    end
% Ach pulses from MCS or other platform that drives the LEDs and OceanView
    if numel(chPeriph) == 8 || numel(chPeriph) == 6 
        vidPulses = getVidTimes(data30k(5,:)); 
        AchPulses = getVidTimes(data30k(6,:)); 
    end

% manual text events by user during the recording     
    netEvfle = [fileBase,'.messages']; %netEvfle = 'messages.events';
    fid = fopen(netEvfle);    
    linenum = 4;
    delimiter = ' ';
    formatSpec = '%f%s%s%s%s%f%s%f%s%s%s%[^\n\r]';
    ev = textscan(fid, formatSpec, 'Delimiter', delimiter, 'MultipleDelimsAsOne', true, 'EmptyValue' ,NaN, 'ReturnOnError', false);
    fclose(fid);
    ev = ev{1,1};ev(1) = [];ev = ev-ev(1);ev(1)=[];   
    disp([num2str(length(ev)),' manual events were discovered']);
    disp 'here'
