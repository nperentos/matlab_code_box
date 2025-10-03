% Input: x = [1 1 1 0 0 0 1 1 0 0 0 0 5 5 5 5 4 1 1 1]
% Output:
%      1     3
%      4     6
%      7     8
%      9    12
%     13    16
%     17    17
%     18    20

    
function periods = find_consecutive(sig)

sig = sig(:);
tmp1 = find(abs(diff([-Inf ; sig])) > 0 );
tmp2 = find(abs(diff([sig; Inf])) > 0);
if length(tmp2)<length(tmp1); tmp2 = [tmp2 ; tmp1(end)]; end;
periods = [tmp1 tmp2];