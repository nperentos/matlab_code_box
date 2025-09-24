% INPUT: 
% x: LFP signal (1D or 2D). If 2D, : channels x time
% ev: events to trigger on
% d: number of samples before/after (symmetric)
% 
% OUTPUT

function [out, trig_t] = mtrig_lfp(data,chan, ev, d)

if nargin<4; d=0.5; end;
d=d*data.info.sr;

ev = ev(:)';

filebase = data.info.fn;
m = memmap_datfile(filebase,'lfp');

maxlen = size(m.Data.m,2);
ev((ev-d)<1 | (ev+d)>maxlen) = [];

idx  = cell2mat(arrayfun(@(x) [x-d:x+d],ev,'un',0));

tmp = m.Data.m(chan,idx);
out = double(squeeze(reshape(tmp,length(chan),2*d+1,length(ev))));

if numel(size(out))==2;
    out = out';
end;

trig_t = linspace(-d/data.info.sr,d/data.info.sr,2*d+1);