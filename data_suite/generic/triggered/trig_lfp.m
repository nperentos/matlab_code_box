% INPUT: 
% x: LFP signal (1D or 2D). If 2D, : channels x time
% ev: events to trigger on
% d: number of samples before/after (symmetric)
% 
% OUTPUT

function [out,excluded] = trig_lfp(x,ev, d)
if nargin<3; d=500; end; % default: 500 samples --> usually 500 ms for 1kHz SR

% Remove the events that fall outside the length of the signal
if isvector(x);
    excluded = (ev-d)<1 | (ev+d)>length(x);
    ev(excluded) = [];
    out = zeros(length(ev),2*d+1);
    for c=1:length(ev);
        out(c,:) = x(ev(c)-d:ev(c)+d);
    end
    
elseif numel(size(x))==2;
    excluded = (ev-d)<1 | (ev+d)>size(x,2);
    ev(excluded) = [];
    out = zeros(size(x,1),2*d+1,length(ev));
    for c=1:length(ev);
        out(:,:,c) = x(:,ev(c)-d:ev(c)+d);
    end
end