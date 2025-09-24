function convertDataCarousel(fileBaseOrDataBaseEntry)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% convertDataCarousel(fileBaseOrDataBaseEntry) is a wrapper for convertData
% which gets all the input information from the carousel database excel
% spreadsheet.
% fileBaseOrDataBaseEntry can be session name eg 'NP49_2020-07-01_15-26-43'
% or the row number of the session inside 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%
T = getCarouselDataBase;OEmaps;

% fileBaseOrDataBaseEntry = 'NP49_2020-07-01_15-26-43';
% fileBaseOrDataBaseEntry = 80;


if strcmp(class(fileBaseOrDataBaseEntry),'char')
    idx = fileBaseOrDataBaseEntry;
    idx = find(strcmp(T.session,idx));
elseif strcmp(class(fileBaseOrDataBaseEntry),'double')
    idx = fileBaseOrDataBaseEntry;%T.session{fileBaseOrDataBaseEntry-1};
end

T.session{idx}

    
%% ADC channel numbers strictly not necessary as it defaults to the end of the file
    str = T.ADC{idx};
    del = strfind(str,'-'); 
    if del ~= 1
        fr = str2num(str(1:del-1));
        to = str2num(str(del+1:end)); 
        ADC = fr:to;
    else
        display('there is  no ADC in this recording session');
        ADC = []; 
    end

%% P1 channels assuming Probe 1 is at 1-64
    if sum(strcmp(fields(oemaps),{T.probe1{idx}}))
        P1 = oemaps.(T.probe1{idx})+0;
        display(['probe 1 is: ', T.probe1{idx}]); 
    else
        display('probe 1 is: NONE');
        P1 = [];
    end

%% P2 channels assuming Probe 2 is at 97-160
    if sum(strcmp(fields(oemaps),T.probe2{idx}))
        P2 = oemaps.(T.probe2{idx})+32+64;
        display(['probe 2 is: ', T.probe2{idx}]); 
        EEGofs = 64; % if two probes, EEG was on second HS (preceded by 64)
    else
        display('probe 2 is: NONE');
        P2 = [];
        EEGofs = 0; % if single probe, EEG was on first HS (1-32)
    end

%% EEG channel numbers
    str = T.EEG{idx};
    del = strfind(str,'-'); 
    if del ~= 1
        fr = str2num(str(1:del-1));
        to = str2num(str(del+1:end)); 
        EEG = [fr:to]+EEGofs;
    else
        display('there is  no EEG in this recording session');
        EEG = [];
    end     


%% FINAL MAP
    if isempty(P2) 
    % only one probe was used - expectation then is that P1 is at 33-96 so that one can use 
    % the PI microdrive. But perhaps also the cable was swapped so then P1
    % would be at 1-64
        map = [P1+32 EEG]; 
    else
        map = [P1 P2 EEG]; 
    end


%% CONVERT DATA
    convertData(T.session{idx},map);
    clear map;
