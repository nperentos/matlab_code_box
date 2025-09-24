function [out] = getRewards(ch,tp)

% Takes input as the reward pulses continuous channel and returns the
% location of reward points in the lfp array. There are three kinds of
% pulses whic all appear together every time the animal reaches the reward
% point. The first gives the time of the sound stimulus, the second gives
% the time of the pump reward delivery and the third is a long pulse that
% gives the delay time during which the carousel is locked at the starting
% point while the animal is consuming the reward. 
% Now also takes input a variable that defines the type of events to search
% for
fprintf('extracting events...');
if nargin < 2
    tp = 1;
end

rewardCh = smooth(ch,20,'lowess');
tmp1 = find(rewardCh(1:end-1)>max(rewardCh)*.75);
tmp2 = find(rewardCh(2:end)>max(rewardCh)*.75);
[both, fall, rise] = setxor(tmp1,tmp2);

if tp == 0
    out.soundIdx    = round(tmp1(rise(1:3:end))./30); % first is the sound
    out.pumpIdx     = round(tmp1(rise(2:3:end))./30); % first is the sound
    out.consumeIdx  = round([tmp1(rise(3:3:end)),tmp1(fall(3:3:end))]./30); % first is the sound
end
%%
IPI = 7000;
if tp == 1
    cnt = 1;
    riseTimes = tmp1(rise);
    % lets add some trailing NaNs so we can easily go to the end without
    % troubles???
    LL = length(riseTimes); riseTimes = [riseTimes; [NaN NaN NaN]'];
    if isempty(riseTimes); out = 'no pulses available'; display('no triggers found, will break...');return; end
    labels = nan(size(riseTimes));
    for k = 1:LL%length(riseTimes)-2
        if ~isnan(labels(k)); continue; end
        if riseTimes(k+1) - riseTimes(k) < IPI % 10000 samples = 50ms
            labels(k) = 2; labels(k+1) = 0;
            if riseTimes(k+2) - riseTimes(k+1) < IPI
                labels(k) = 3; labels(k+1) = 0; labels(k+2) = 0;
                if riseTimes(k+3) - riseTimes(k+2) < IPI
                    labels(k) = 4; labels(k+1) = 0; labels(k+2) = 0;  labels(k+3) = 0; 
                end
            end
        else
            labels(k) = 1;
        end        
    end
    % since we added the trailing zeros no need special cases anymore
    %     % special cases at the last two events
    %     if riseTimes(end)-riseTimes(end-1) < IPI
    %         labels(end-1:end) = [2 0];
    %     if riseTimes(end)-riseTimes(end-1) < IPI
    %         labels(end-1:end) = [2 0];        
    %     else
    %         labels(end-1) = 1;
    %         labels(end) = 1;
    %     end
        
end
out.atStart =       round(riseTimes(find(labels == 2))/30); % two pulses - arrive at center
out.atCW =          round(riseTimes(find(labels == 3))/30);    % three pulses is a clockwise rotation 
out.atACW =         round(riseTimes(find(labels == 1))/30); 
out.atHalfCircle =  round(riseTimes(find(labels == 4))/30); 
% these were double checked and they are correct for the appettitive only code       

out.all = [riseTimes(labels>0),labels(labels>0)];
fprintf('DONE\n');

    
%%    
%     allTransitions = diff(riseTimes);
%     taskTransitions1 = find(diff(riseTimes) < 150000);
%     
%     taskTransitions2 = find(diff(riseTimes) > 150000);
    
end


















% tSound = tScale(tmp1(rise(1:3:end))); % first is the sound
% tPump = tScale(tmp1(rise(2:3:end))); % first is the sound
% tRewardConsume = tScale(tmp1(rise(3:3:end))); % first is the sound


% rewardCh = smooth(data(38,:),20,'lowess');
% tmp1 = find(rewardCh(1:end-1)>3000);
% tmp2 = find(rewardCh(2:end)>3000);
% [both, fall, rise] = setxor(tmp1,tmp2);
% tSound = tScale(tmp1(rise(1:3:end))); % first is the sound
% tPump = tScale(tmp1(rise(2:3:end))); % first is the sound
% tRewardConsume = tScale(tmp1(rise(3:3:end))); % first is the sound
% % plot(tScale(tmp1(rise)),2000*ones(length(tmp1(rise)),1),'bx')