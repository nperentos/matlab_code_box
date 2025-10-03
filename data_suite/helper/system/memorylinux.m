function [freemem, memsize] = memorylinux
    
if ismac 
    freemem = 10000000;
    memsize = 10000000;
elseif isunix; 
    [r,w] = unix('free | grep Mem');
    stats = str2double(regexp(w, '[0-9]*', 'match'));
    memsize = stats(1)/1e6;
    freemem = (stats(3)+stats(end))/1e6;  % free memory
else; 
    freemem = memory; 
    freemem= freemem.MaxPossibleArrayBytes/1e9; 
end;


