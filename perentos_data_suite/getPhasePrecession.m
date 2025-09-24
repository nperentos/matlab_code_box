function out = getPhasePrecession(fileBase)
% check the one in natalias folder which works this is working progress
% /storage2/natalia/code/matlab/phase_precession
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function getPhasePrecession(fileBase) extracts phase for spikes during
% running around the carousel. It does this for all clusters irrespective
% of quality or the presence of place fields. Output is saved into
% filebase.phasePrecession.mat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
error('script is not finished');
% clearvars -except fileBase
goto(fileBase);
[session, behavior] = loadSession(fileBase);

% position
posid = find(strcmp(behavior.name,'posDiscr'));
position = behavior.data.data(:,posid);
if min(position)>360
    position = position - 360;
end
% speed and times of movement
spdid = find(strcmp(behavior.name,'runSpeed'));
speed = behavior.data.data(:,spdid );

% raw theta phase
thphid = find(strcmp(behavior.name,'theta_raw_phase'));
thphase = behavior.data.data(:,thphid );

% indices of timepoints with movement
idxMv = (session.helper.idxMov == 1);
SR = session.info.SR_LFP;

% load spikes into normal Res/Clu
sp = loadKSdir(pwd);
cids_id =ismember(sp.clu,sp.cids);
Res = round(sp.st(cids_id)*SR);
[uClu, ~,Clu] = unique(sp.clu(cids_id));
nClu= length(uClu);

% 
rt =  RayleighTest(thphase(Res),Clu);

%%
for c = 1:nClu
  myRes= Res(Clu==uClu(c)); %randi(nClu)
  my_inMv = idxMv(myRes);
  myRes = myRes(my_inMv); %only spikes in motion
  
  figure(13);clf
  plot(repmat(position(myRes),2,1),[ thphase(myRes)*180/pi;  thphase(myRes)*180/pi+360 ],'.');
%   plot(position(myRes), thphase(myRes)*180/pi,'.');
  xlim([0,360]);  
  title(num2str(uClu(c)));grid on;
  drawnow;pause(1);% waitforbuttonpress;  
end