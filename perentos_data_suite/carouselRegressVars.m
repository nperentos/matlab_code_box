function [B,BINT,R,RINT,STATS] = carouselRegressVars(fileBase,varNames,data)

% take any two variables from the ppp matrix and regress
% e.g.

if nargin < 3 
    if sum(~cellfun(@isempty,regexp(pppNames,strjoin(varNames,'|'))))>0 % request variable likely exists
        try
            load(fullfile(getfullpath(fileBase),'peripheralsPP.mat'));
        catch
            disp('peripheralsPP is missing');
            disp('will try to generate');
            peripheralsPP(fileBase);
            load(fullfile(getfullpath(fileBase),'peripheralsPP.mat'));
        end
    end 
end

pppNames = {'tScale', 'runSpeed', 'carouselSpeed', 'posDiscr', 'wholeROI', 'whiskerROI'...
    'snoutROI', 'tongueROI', 'earROI', 'eyeROI', 'pupilDiam', 'pupilX', 'pupilY' ...
    'licking', 'respRate', 'idxMov', 'idxTrials'}; 

varNames = {'respRate','pupilDiam'};

vars = find(~cellfun(@isempty,regexp(pppNames,strjoin(varNames,'|'))) == 1);
X = [ones(size(ppp(vars(2),:)')), ppp(vars(2),:)'];
Y = ppp(vars(1),:)';

[B,BINT,R,RINT,STATS] = regress(Y, X,0.01);

L = length(pppNames);
ns = numSubplots(L);
figure;
for i = 1:L
    subplot(ns(1),ns(2),i);
    x = ppp(i,:);
    histogram(x,100);
    hold on;
    thr = prctile(x,0.99);
    histogram(x(x<thr),100);
    axis tight;
    title(pppNames(i))
end
    
    
    
    
    








