function [carouselSpeed] = getCarouselSpeed(ch,varargin)
% 08/09/2020 - 
fprintf('computing carousel speed...');

options = {'decFlag','1','lfpSR',1000};
options = inputparser(varargin,options);
if strcmp(options,'error'); return; end;

% % this input was used for the SiNAPS IIT data 
% if nargin == 2
%     decFlag = decmate;
% else
%     decFlag  = 1;
% end
    
% takes a single time series of rotary encoder pulses and computes speed of
% 'translation' of animal

win = 100*30;%=100ms window

if nargin <= 2
    % find threshold crossings upwards
    if isvector(ch)
        if size(ch,1) > size(ch,2); ch = ch'; end
        %         remainder = mod(length(ch),100);
        %         if remainder % make multiple of 100ms
        %             ch = [ch, zeros(1,100-mod(length(ch),100))]; 
        %             oddFlag = 1; 
        %         end
        
        % check range
        if range(ch) < 3000 || (max(ch)<0 && min(ch) < 0) % there are no pulses
            carouselSpeed = nan(1,length(ch));
            carouselSpeed = resample(carouselSpeed,1,30);
            warning('there appear to be no pulses in this recording. Setting carouselSpeed to NaN...');
            return;
        end
        
        idxl = ch>0.75*max(ch);
        idx = [idxl(2:end),0];
        idxn = idx-idxl; 
        idxn(idxn==-1)=0;
        carouselSpeed = movsum(idxn,[win, 0])*20*pi*25/4096; % cm/s current carousel diameter:25cm and number of pulses per rev: 4096
        if options.decFlag
            fprintf('   downsampling to lfp rate...');
            carouselSpeed = decimate(carouselSpeed,30);
            fprintf('   smoothing...');
            carouselSpeed = ButFilter(carouselSpeed,4,50/options.lfpSR*2,'low');
            %carouselSpeed = eegfilt(carouselSpeed,1000,0,50); % this is smoothing       
        else
            carouselSpeed = eegfilt(carouselSpeed,30000,0,50);        % this is smoothing       
        end
    else
        error('must supply vector not matrix i.e. one channel only)');
    end        
else 
    error('you need to supply one or two input variables - cannot proceed');
end
fprintf('DONE\n');