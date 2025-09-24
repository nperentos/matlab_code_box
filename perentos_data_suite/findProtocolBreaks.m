function out = findProtocolBreaks(fileBase)
% function findProtocolBreaks(fileBase) identifies the start and stop
% timestamps of the breaks found in between blocks of trials on the
% carousel task

%% PRE
try
    goto(fileBase);
catch
    error('the fileBase you defined doesnt exist');
end


%% GET USEFUL VARIABLES
[session, behavior] = loadSession(fileBase);
breakDurations = session.info.breakDurations;
nBreaks = session.info.nBlocks + 1;
nBlocks = session.info.nBlocks;
breaks = nan(nBreaks,2);
nTrials = session.info.nTrials;
atStart = session.events.TTL.atStart;
beh = behavior.data.data;
pos = beh(:,find(strcmp(behavior.name,'position')));
speed = beh(:,find(strcmp(behavior.name,'carouselSpeed')));
idxTrials = vc(session.helper.idxTrials);

%% FIRST BREAK EPOCH START AND END
breaks(1) = 1;
breaks(1,2) = find(speed(1:atStart(1)) >= 0.1, 1, 'first');


%% LAST BREAK EPOCH START AND END
breaks(end,1) = find(idxTrials == max(idxTrials),1,'last') + 1; %find(fliplr(speed) < 0.1,1,'last'); % TWO WAYS OF COMPUTING SAME THING FOR SANITY
breaks(end)   = session.info.nSamples_LFP;


%% MIDDLE BLOCK BREAK EPOCHS
if length(breaks) >= 2
    trialsPerBlock = nTrials/nBlocks;
    for x = 1:nBreaks-2
        tr = trialsPerBlock * x
        % end of middle epoch
        tmp = find(idxTrials == tr+1, 1, 'first')-1;
        breaks(x+1,2) = tmp;
        % start of middle epoch
        tmp1 = tmp - find(flipud(speed(1:tmp-1)) > 1,1,'first');
        breaks(x+1,1) = tmp1;    
    end
end
out=breaks;

%% A PLOT FOR INSPECTIONS
figure;plot(pos); hold on;
plot(speed);
plot(idxTrials);
plot(breaks(:),0,'ok','markersize',10)
title('break epochs');
print(gcf,[pwd,'/breakEpochs'],'-djpeg');
