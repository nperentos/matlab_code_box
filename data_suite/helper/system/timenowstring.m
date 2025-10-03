function [t,t1] = timenowstring(separator, fieldnum,european)
if nargin<3; european = 1; end;
if nargin<2; fieldnum = 6; end;
if nargin<1; separator = '_'; end;

outputformat = [];
for c=1:fieldnum-1;
    outputformat = cat(2,outputformat,['%d' separator]);
end;
outputformat = cat(2,outputformat,'%d'); % To avoid the last separator
t1 = datevec(datetime);
if european; t1 = t1([3 2 1 4:end]); end;
t1 = t1(1:fieldnum);
t = sprintf(outputformat,round(t1));



