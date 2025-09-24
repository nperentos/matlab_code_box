function [LFPpth] = pathconstructor(sessionFolder, dataPath)

% below is the silly way i was using in germany
% if ~isempty(sessionFolder)
%         if nargin > 0
%             TF = isstrprop(sessionFolder(3:4),'digit');
%             % if exist('processed','file'); pmod = '/processed'; else pmod = []; end
%             if exist(fullfile(defaultDataPath, sessionFolder(1:4),'/',sessionFolder,'processed'),'file'); pmod = '/processed'; else pmod = []; end
%             if sum(TF) == 2
%                 LFPpth = [defaultDataPath, sessionFolder(1:4),'/',sessionFolder,pmod,'/',sessionFolder,'.lfp'];
%             elseif TF(1) == 1
%                 LFPpth = [defaultDataPath, sessionFolder(1:3),'/',sessionFolder,pmod,'/',sessionFolder,'.lfp'];
%             else 
%                 disp('I was expecting a sessionFolder to start with NP (or other 2 initials characters followed by 1 or 2 digits');
%                 disp 'EXAMPLE:  NP3_2018-04-11_19-37-06'
%                 error('fix sessionFolder input variable and try again');e
%             end
%         end
%     catch
% 
% end
% 
% 
% % if nargin > 1 && ~isempty(dataPath)% alternative data path supplied
% %     defaultDataPath = dataPath;
% %     LFPpth = fullfile(defaultDataPath,sessionFolder,'processed',[sessionFolder,'.lfp']);
% % end
% 
% if nargin > 1 && ~isempty(dataPath)% ony a data path supplied - look inside for .lfp
%     lst = dir([dataPath,'*.lfp']);
%     if length(lst) == 1
%         defaultDataPath = dataPath; 
%         LFPpth = fullfile(defaultDataPath,lst.name);
%     end
% end

LFPpth = fullfile(dataPath,sessionFolder,[sessionFolder,'.lfp']);
% ensure .lfp file is here 

if ~exist(LFPpth)
    error('file not found');
end