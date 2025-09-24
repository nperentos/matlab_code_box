% first script for basic data processing of EXELU data post dat and lfp creation
% KS has already ran at this stage by another script that resides on the recording PC
% the script is called convertDataEXELU.m


dataPath = 'I:\';
fileBase = '2025-09-20_16-51-22';
load(fullfile(dataPath,fileBase,[fileBase,'.chanmap.mat']));
load(fullfile(dataPath,fileBase,'analog_events.mat'));
num_channels = length(chanMap);
[data,settings,tScale] = getLFP(fileBase, dataPath);


% theta
params.tapers = [2 3];    % Or [3 5] for slightly smoother spectra
params.Fs     = 1000;     % Sampling rate (Hz)
params.fpass  = [0 100];   % Focus on theta band
params.pad    = 0;        % No additional frequency padding
% params.win    = [1 0.5];  % 1 s window, 0.5 s step (50% overlap)
[S,t,f]=mtspecgramc(data',[1.5 1.5*0.8],params);
figure;
for i = 1:num_channels
    imagesc(t,f,S(:,:,i)');
    axis xy; title(['ch ',num2str(i)]);
    pause(0.2); cla;
end



% out = specmt(data,{'defaults','theta'});

test = analogEvents{1};
test =reshape(test,2,floor(length(test)/2));
durations = test(2,:)-test(1,:);





% % we need to run some corrections on the event detection since the script used had 
% % an incorrect event indexing method
% fbs = {'2025-09-18_09-59-40','2025-09-18_20-10-12','2025-09-20_10-49-09', ...
% '2025-09-20_13-33-23','2025-09-20_16-51-22'};
% dataPath = 'I:\';
% 
% for j = 1:length(fbs)
%     fileBase = fbs{j};
%     load(fullfile(dataPath,fileBase,'analog_events.mat'));
%     load(fullfile(dataPath,fileBase,[fileBase,'.chanmap.mat']));
%     num_channels = length(chanMap);
%     fle = fullfile(dataPath,fileBase,[fileBase,'.dat']);
%     fid = fopen(fle);
%     fseek(fid,0,'eof');
%     len = ftell(fid);
%     len = len/(num_channels*2);
%     m = memmapfile(fle,'Format',{'int16',[num_channels len],'m'},'writable',false);
%     d = m.Data.m;
%     ev_chans = [135:139];
%     ADCs = d(ev_chans,:);
% 
%     for i = 1:size(ADCs,1)
%         test = double(ADCs(i,:));
%         tmp1 = find(test(1:end-1)>max(test)*.75); % if this occasionaly doesnt work we have to switch to prctile
%         tmp2 = find(test(2:end)>max(test)*.75);
%         [both, fall, rise] = setxor(tmp1,tmp2);
%         analogEvents{i} = tmp1(rise); % add names of event channels as per arduino connections and correspondece to the py code conditions
%     end
%     analog_ch_names{5} = 'run_encoder';
%     % overwrite the analog_events.mat
%     save(fullfile(dataPath,fileBase,'analog_events.mat'),'analogEvents','analog_ch_names','user_msgs','ts_user_msgs');
% end
% 
% 
% 
% 
% 
% % we should make a session variable that holds
% 
% session.events =
% session.num_channels = 
% session.SR = 
% session.ADCs = 
% session.speed = 
% session.CA1
% session.V4