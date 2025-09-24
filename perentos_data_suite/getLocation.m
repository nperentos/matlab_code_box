function location = getLocation(ch,rewards)

%% special case for location extraction for NP25. Missing 3pl pulse for CW rotation
% and changing direction. In addition
warning('computation of ''location'' relies on correct interpretation of TTLs, especially the start point pulse sequence');
exp = [rewards.atStart' rewards.atCW' rewards.atACW';
    2*ones(length(rewards.atStart),1)' 1*ones(length(rewards.atCW),1)' 3*ones(length(rewards.atACW),1)']';
[~,idx]=sort(exp(:,1));
exp = exp(idx,:);



% % extract angular location on carousel based on rotary encoder pulses and
% % knowledge of the starting/reset point defined as the time of reward
% % sound. This will need to be changed later on in case the sound is removed
% % altogether
% 
if nargin <2
	error('two inputs needed, carousel encoder channel number and rewards structure array')  
else   
    % find threshold crossings upwards
    if isvector(ch)
        if size(ch,1) > size(ch,2); ch = ch'; end       
            % [pks,idxn]=findpeaks(ch,'MinPeakProminence',3000);
        idxl = ch>3e3;
        idx = [idxl(2:end),0];
        idxn = idx-idxl; 
        idxn(idxn==-1)=0; % keep up crossings
        location = idxn;
        %location = nan(size(ch,1),size(ch,2));
        location(location == 0) = nan;

        
        
        for i = 1:length(rewards.atStart)%soundIdx
            tmp2 = 30*rewards.atStart(i);%soundIdx
            if i == 1
                fill = find(location(1:tmp2) == 1);
                for j = length(fill):-1:1
                    location(fill(j)) = j;
                end
            end
            if i>=2
                tmp1 = 30*rewards.atStart(i-1);%soundIdx
                fill = tmp1 -1 + find(location(tmp1:tmp2) == 1);
                for j = length(fill):-1:1
                    location(fill(j)) = j;
                end       
            end
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