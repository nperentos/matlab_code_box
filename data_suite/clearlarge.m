% Clears from memory variables larger than maxsize (default: 10mb)
% Optionally, an excludelist is provided (cell), with variables to be
% preserved
% 
% Date: 12/10/2017
% Author: Nikolas Karalis


function clearlarge(maxsize,excludelist)

if nargin<1 || isempty(maxsize); maxsize = 1e7; end;
if nargin<2; excludelist = []; end;


tmp = evalin('base','whos');
tmp1 = {tmp(cellfun(@(x) x>maxsize,{tmp.bytes})).name};
tmp1 = setdiff(tmp1,excludelist);

for c=1:length(tmp1); evalin('base',['clear ' tmp1{c}]); end;

clear tmp*