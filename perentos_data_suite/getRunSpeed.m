function [runSpeed] = getRunSpeed(ch,decmate)
% takes a single time series of rotary encoder pulses and computes speed of
% 'translation' of animal
% works on the raww data i.e. 30k
fprintf('computing running speed...')
% this input was used for the SiNAPS IIT data 
if nargin == 2
    decflag = decmate;
else
    decflag = 1;
end

win = 100*30;


if nargin <= 2
    % find threshold crossings upwards
    if isvector(ch)
        if size(ch,1) > size(ch,2); ch = ch'; end
        %         remainder = mod(length(ch),100);
        %         if remainder % make multiple of 100ms
        %             ch = [ch, zeros(1,100-mod(length(ch),100))]; 
        %             oddFlag = 1; 
        %         end
        idxl = ch>0.75*max(ch);
        idx = [idxl(2:end),0];
        idxn = idx-idxl; 
        idxn(idxn==-1)=0;
        runSpeed = movsum(idxn,[win, 0])*20*pi*9/600; % cm/s
        if decflag
            runSpeed = decimate(runSpeed,30);
        end
    else
        error('must supply vector not matrix i.e. one channel only)');
    end        
    fprintf('DONE\n');
else 
    error('you need to supply one or two input variables - cannot proceed');
end

