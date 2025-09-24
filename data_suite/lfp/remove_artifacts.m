function [sig,periods] = remove_artifacts(sig, periods, merge_periods, thr, tthr,thr2,tthr2)
if nargin<3; merge_periods=0; end % I added this option to try it, but in the general case it can cause weird behavior, because channels can have different artifacts/different times.  Use with care.
if nargin<4; thr = 5; end
if nargin<5; tthr = 500; end 
if nargin<6; thr2 = 0.3; end;
if nargin<7; tthr2 = tthr; end;

if nargin<2 || isempty(periods);
    if isvector(sig);
        [periods, sig] = find_artifact_periods(sig,thr, tthr,thr2,tthr2);
    else
        periods = {};
        for c=1:size(sig,1);
            periods{c} = find_artifact_periods(sig(c,:),thr, tthr,thr2,tthr2);   
        end
        [sig,periods] = remove_artifacts(sig, periods,merge_periods,thr, tthr,thr2,tthr2); 
        % Careful: this is a recursive part. If the signal has many rows, 
        % the function calculates the periods for every row and then calls itself, 
        % giving the periods cell as an input, so that it runs for the condition 
        % where periods are provided as a cell and have to be combined (see below).
    end
    
else
    if iscell(periods) && merge_periods;
        all_periods = [];
        for c=1:length(periods)
            for k=1:size(periods{c},1);
                all_periods = cat(2,all_periods,periods{c}(k,1):periods{c}(k,2));
            end
        end
        all_periods = sort(unique(all_periods));
        jump_points = find(diff([0 all_periods 0])>1);
        periods = [all_periods(jump_points(1:end-1)) ; all_periods(jump_points(2:end)-1)]';        
    end
    
    if isvector(sig);
        for k=1:size(periods,1); sig(periods(k,1):periods(k,2)) = NaN; end;
    else
        if iscell(periods);
            for c=1:length(periods);
                for k=1:size(periods{c},1); 
                    sig(c,periods{c}(k,1):periods{c}(k,2)) = NaN; 
                end;
            end
        else
            for k=1:size(periods,1); 
                sig(:,periods(k,1):periods(k,2)) = NaN; 
            end;
        end;
    end
end