% INPUT: 
% x: LFP signal (1D or 2D). If 2D, : channels x time
% ev: events to trigger on
% d: number of samples before/after (symmetric)
% 
% OUTPUT

function [out, trig_t] = mtrig_filt(data,chan, ev, fpass, d)

if nargin<5; d=0.5; end;
d=d*data.info.sr;

ev = ev(:)';

filebase = data.info.fn;
m = memmap_datfile(filebase,'lfp');


maxlen = size(m.Data.m,2);


mf = min(fpass); mf = max(mf,0.5); % in case fpass = [0 X], we treat it as if it was [0.5 X]
d1 = 5 * 1/mf * data.info.sr; % contain at least 5 cycles of the minimum frequncy
d2 = round(max(d1,d));

ev((ev-d2)<1 | (ev+d2)>maxlen) = [];

idx  = cell2mat(arrayfun(@(x) [x-d2:x+d2],ev,'un',0));

tmp = m.Data.m(chan,idx);
tmp = filter_lfp(tmp,data.info.sr,fpass);
out = double(squeeze(reshape(tmp,length(chan),2*d2+1,length(ev))));

% Cut back the signal to only the requested length
if length(size(out))==3;
    idx = [((size(out,2)-1)/2 - d): ((size(out,2)-1)/2 + d)];
    if min(idx)==0; idx = idx+1; end; % to deal with the case that d=d1;
    out = out(:,idx,:);
elseif length(size(out))==2;
     idx = [((size(out,1)-1)/2 - d): ((size(out,1)-1)/2 + d)];
     if min(idx)==0; idx = idx+1; end; % to deal with the case that d=d1;
     out = out(idx,:);
end

if numel(size(out))==2;
    out = out';
end;

trig_t = linspace(-d/data.info.sr,d/data.info.sr,2*d+1);