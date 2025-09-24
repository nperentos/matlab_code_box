function [location, direction] = getLocationPassiveRotation(ch,rewards)

%% special case for location extraction for NP25. Missing 3pl pulse for CW rotation
% and changing direction. In addition
warning('computation of ''location'' on carousel relies on correct interpretation of TTLs, especially the start point pulse sequence');
if isstr(rewards)
    if strcmp(rewards, 'no pulses available') 
        display('there are no rewards so assuming that the carousel did not spin'); 
        location = 'there was no carousel movement'; 
        direction  = 'there was no carousel movement'; 
        return; 
    end
end; 
% lets get the TTL markers - used for position resetting
if isfield(rewards,'all')
    exp = rewards.all(rewards.all(:,2)<4,:)
else
    exp = [rewards.atStart' rewards.atCW' rewards.atACW';
        2*ones(length(rewards.atStart),1)' 1*ones(length(rewards.atCW),1)' 3*ones(length(rewards.atACW),1)']';
    [~,idx]=sort(exp(:,1));
    exp = exp(idx,:);
end

% now lets create a direction variable based on the sequence of pulses we
% get whereby: 
%               2 pulses (Start point) -> 3 pulses (RHS cage) -> 1 pulse  (LHS cage) = clockwise rotation
%               2 pulse  (Start point) -> 1 pulse  (LHS cage) -> 3 pulses (RHS cage) = anticlockwise
cpts = find(exp(:,2)==2);
prev = exp(cpts-1,2);
prev(prev == 3) = 'R';
prev(prev == 1) = 'L';
direction = char(prev);
%direction = ['LLRLLLRLRRRLLLRLRRLR']'; % forceddirections for IIT b/c of missing pulses (bad arduino code)
%direction = ['RRRLLRRRLLRLLRLRRLLRRLLLRLRLLRLRRRLLRLLR']';
clear prev;

%% extract location
% extract angular location on carousel based on rotary encoder pulses and
% knowledge of the starting/reset point defined as the time of start
% point reward/sound. Older recordings relied on a TTL that corresponded to
% Algorythm: Detect all positive crossings and mark them as 1 in an
% otherwise nan array. Then star coounting up till first start point TTL.
% If the first rotation was ACW, then replace the counts with counting
% down 0 till the first start TTL. From there one either reset to zero or
% start counting down 
% 
if nargin <2
	error('two inputs needed, carousel encoder channel number and rewards structure array')  
else   
    % find threshold crossings upwards
    if isvector(ch)
        if size(ch,1) > size(ch,2); ch = ch'; end 
        idxl = ch>max(ch)*.75;
        idx = [idxl(2:end),0];
        idxn = idx-idxl; 
        idxn(idxn==-1)=0; % keep up crossings
        location = idxn;
        location(location == 0) = nan;
        
        % fill in pulses with incremental integers: 
        % there are four cases. If the sequence is L followed by R then we
        % go from 4k to 0 and from 0 to 4k. If the sequence is R followed
        % by L then we go from 0 4k and from 4k down to zero. If its L L,
        % then we go from 4k to 0 and then jump to 4k and count to 0 once
        % more. If its R R, then we go from 0 to 4k, then jump to zero
        % again and count up to 4k once more.
        
        % first rotation is special case for now
        tmp2 = 30*rewards.atStart(1); % where to stop looking for pulses
        tmp1 = 1;% where to start looking for pulses
        fill = find(location(tmp1:tmp2) == 1); % the indices of points to fill
        
        % for the first trial
        if direction(1) == 'L'                
            for j = tmp1:1:length(fill)
                location(fill(j)) = length(fill)-j+1;
            end
        elseif direction(1) == 'R'
            for j = tmp1:1:length(fill)
                location(fill(j)) = j;
            end
        end 
        last = fill(end);
        
        % for remaining trials  
        for i = 2:length(rewards.atStart)            
            tmp1 = 30*rewards.atStart(i-1);% previous end or rotation
            tmp2 = 30*rewards.atStart(i);%current end of rotation
            fill = tmp1 -1 + find(location(tmp1:tmp2) == 1); % indices of pulses within relevant range
            
            
            if direction(i-1) == 'R' & direction(i) == 'L' % count up from 4k
                down_from = location(last);
                for j = 1:1:length(fill)
                    location(fill(j)) = down_from-j;
                end
            elseif direction(i-1) == 'R' & direction(i) == 'R' % count up from zero
                for j = 1:1:length(fill)
                    location(fill(j)) = j;
                end
            elseif direction(i-1) == 'L' & direction(i) == 'R' % count up from zero
                for j = 1:1:length(fill)
                    location(fill(j)) = j;
                end
            elseif direction(i-1) == 'L' & direction(i) == 'L' % count up from zero in the reverse direction
                for j = 1:1:length(fill)
                    location(fill(j)) = length(fill)-j+1;
                end             
            end
            last = fill(end);
        end
        a = location;
        a = [0 0 a];
        b = [a(2:end),inf];
        from = find(~isnan(a) & isnan(b)) + 1;
        to   = find(~isnan(b) & isnan(a));
        idxFiller = from - 1;
        % fill nans with preceding number
        for i = 1:length(from)
            a(from(i):to(i)) = a(idxFiller(i));
        end
        location = a(3:end); 
        location = downsample(location,30);
    else
        error('must supply vector not matrix i.e. one channel only)');        
    end
end
        
        
        
        
        
        
