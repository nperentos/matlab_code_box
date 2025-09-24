function [vidTimes] = getVidTimes(ch,varargin)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% [vidTimes] = getVidTimes(ch,varargin) takes as input the
% data at the high sampling rate (default is 30kHz) and extracts the pulse
% rise times. Returns video frame times at lfp time scale (array of zeros
% with ones at the video time points)
% input ch must be dat NOT lfp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% PRE
    options = {'channel',[],'data',[],'freqRange',[4 12],'phaseMethod','hilbert',...
        'freqMethod','spect','filterMethod','adapt','dataType','raw',...
        'channelName','thetaCh','nICAComps',4,'lfpSR',1000,'datSR',30e3};
    options = inputparser(varargin,options);
    if strcmp(options,'error'); return; end;
    
%% MAIN
idxl = ch>max(ch)*.75; % this fails if there are no pulses!!!
idx = [idxl(2:end),0];
idxn = idx-idxl; 
idxn(idxn==-1)=0;
rm = (rem(length(ch),30));
tmp = reshape([idxn zeros(1,30-rm)],30,[]);
vidTimes = sum(tmp,1);

% the above is susceptible to problems if there are no pulses so we do a
% post fix here just in case. We expect pulses to be 5V amplitude so if the
% range of the data on this channel is less than, lets say 3000uV, then it
% is unlikley that there were any video pulses and so we zero the vidTimes
% timeseries
if max(ch)*.75 < 3e3
    display('it appears that there are no video pulses here...');
    vidTimes = zeros(size(vidTimes));
end
