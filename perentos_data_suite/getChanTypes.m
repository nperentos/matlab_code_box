function [chanTypes] = getChanTypes(settings)
% how many ADC channels are there+

% how many channels altogether?
try
    n = length(settings.SETTINGS.SIGNALCHAIN{1, 1}.PROCESSOR{1, 1}.CHANNEL_INFO.CHANNEL);
catch
    n = length(settings.SETTINGS.SIGNALCHAIN(1, 1).PROCESSOR{1, 1}.CHANNEL_INFO.CHANNEL);
end

OnOff = nan(1,n);
type = nan(1,n);
for i = 1:n
    try
        OnOff(i) = str2num(settings.SETTINGS.SIGNALCHAIN{1, 1}.PROCESSOR{1, 1}.CHANNEL{1, i}.SELECTIONSTATE.Attributes.record);
        tmp = settings.SETTINGS.SIGNALCHAIN{1, 1}.PROCESSOR{1, 1}.CHANNEL_INFO.CHANNEL{1, i}.Attributes.name;        
    catch
        OnOff(i) = str2num(settings.SETTINGS.SIGNALCHAIN(1, 1).PROCESSOR{1, 1}.CHANNEL{1, i}.SELECTIONSTATE.Attributes.record);
        tmp = settings.SETTINGS.SIGNALCHAIN(1, 1).PROCESSOR{1, 1}.CHANNEL_INFO.CHANNEL{1, i}.Attributes.name;
    end
    
    if strcmp(tmp(1:2),'CH')
        type(i) = 1;
    elseif strcmp(tmp(1:2),'AD')
            type(i) = 2;
    end
end
type(OnOff == 0) = [];
chanTypes = type;