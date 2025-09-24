% Returns an array with the split lfp around events or in periods.
% Each row corresponds to one event/period
% If events is a list, then they are treated as events
% If events is an n x 2 array, then they are treated as periods.
% If padding option is set to 1, then in the case of non-equal length periods of
% events, the shortest periods are 0-padded.
% If padding option is set to -1, then in the case of non-equal length periods of
% events, the shortest periods are truncated. 

function lfps = split_lfp(lfp, samplingfrequency, events, windowsize,pad)
if nargin<5 || isempty(pad); pad=0; end;
if nargin<4 || isempty(windowsize); windowsize=0.5; end;

if size(events,2) == 1
    lfps = zeros(length(events),2*windowsize*samplingfrequency+1);
    for t=1:length(events)
        slice=int32((events(t)-windowsize)*samplingfrequency): int32((events(t)+windowsize)*samplingfrequency);
        if length(slice)~= size(lfps,2); slice = slice(1:size(lfps,2)); end;  % This is to deal with the rare case in which arithmetics erros cause the wrong calculation of the limits
        lfps(t,:) = lfp(slice);
    end;
else
    lfps = cell(size(events,1),1);
    for t=1:size(events,1)
        % The if is controling for the case that some of events terminate
        % outside of the lfp
        if int32(events(t,2)*samplingfrequency) <= length(lfp)
            lfps{t,1} = lfp(int32(events(t,1)*samplingfrequency): int32(events(t,2)*samplingfrequency));
        else
            lfps{t,1} = lfp(int32(events(t,1)*samplingfrequency): end);
        end;
    end;
    
    if pad==1  
        max_l=max(cellfun(@length,lfps));
        lfps_mat = zeros(length(lfps),max_l);
        for c=1:length(lfps)
            lfps_mat(c,1:length(lfps{c}))=lfps{c};            
        end;
        lfps=lfps_mat;
    elseif pad==-1
        [min_l,minidx]=min(cellfun(@length,lfps));
        if min_l==0;  lfps(minidx)=[]; [min_l,minidx]=min(cellfun(@length,lfps)); end;
        lfps_mat = [];
        for c=1:length(lfps)
            temp=lfps{c};
            lfps_mat(c,:)=temp(1:min_l);            
        end;
        lfps=lfps_mat;
    end;
    
end;