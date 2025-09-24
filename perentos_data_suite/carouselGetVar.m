function out = carouselGetVar(fileBase,var,ppp,pppNames)
% returns the particular variable from the postprocessed peripherals matrix
% INPUT: fileBase: e.g. NP46_2019-10-26_15-40-40
%        var: name of the variable e.g. posDiscr  
%        data: the ppp matrix, otherwise if empty it will load from storage

%pppNames = {'tScale', 'runSpeed', 'carouselSpeed', 'posDiscr', 'wholeROI', 'whiskerROI'...
%    'snoutROI', 'tongueROI', 'earROI', 'eyeROI', 'pupilDiam', 'pupilX', 'pupilY' ...
%    'licking', 'respRate', 'idxMov', 'idxTrials'};  

if nargin < 3 % load ppp
    try
        load(fullfile(getfullpath(fileBase),'peripheralsPP.mat'));
    catch
        disp('peripheralsPP is missing');
        disp('will try to generate');
        peripheralsPP(fileBase);
        load(fullfile(getfullpath(fileBase),'peripheralsPP.mat'));
    end
end

if ~iscell(var); var = {var}; end
tmp = ~cellfun(@isempty,regexp(pppNames,strjoin(var,'|')));
if sum(tmp) == 1
    
    out = ppp(find(tmp == 1),:);
else
    error('you must request exactly one variable - please try again');
end
    
