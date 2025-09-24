function [csd,csd_interp]=calculate_csd(lfp,samplingfrequency,varargin)

if nargin<2; samplingfrequency = 1000; end;

% Input parsing
options = {'method','manual','time',[],'plot',1,'smooth',1,'smoothmethod','linear','step',2,'smoothpoints',3,'filter',0,'freqs',[2 300],'plotlfp',1};
options = inputparser(varargin,options);
if strcmp(options,'error'); return; end;

if ~isvector(lfp) && size(lfp,1)>size(lfp,2)
    lfp = lfp';
    transpose=1;
else
    transpose=0;
end;


if ~isempty(options.time)
    time = options.time * samplingfrequency;
    if time(1)==0; time(1)=1; end; % If the user provides 0 seconds to start, it is converted to the first datapoint.
    lfp=lfp(:,time(1):time(2));  % keep specified part of lfp
end

if options.filter
    lfp = filter_lfp(lfp,samplingfrequency,options.freqs);
end;

if strcmp(options.method,'manual')
    % Algorithm by Anton Sirota
    step=options.step;
    chans=[step+1:size(lfp,1)-step];
    csd = lfp(chans+step,:) - 2*lfp(chans,:) + lfp(chans-step,:);
    csd = csd/(step^2);
elseif strcmp(options.method,'diff')
    % Not working correctly
    % Needs fixing
    %csd = -diff(lfp,2,2);
elseif strcmp(options.method,'inverse')
    
    [csd, z] = inverseCSD(lfp,options.positions,'spline',1000,1);

end;

if options.smooth;
    if strcmp(options.smoothmethod,'linear') 
        csd_interp=interp2(csd, options.smoothpoints, 'linear'); % 3-point Hamming filter (Freeman & Nicholson, 1975,  Rappelsberger et al., 1981)
    elseif strcmp(options.smoothmethod,'cubic') 
        csd_interp=interp2(csd, options.smoothpoints, 'cubic');
    elseif strcmp(options.smoothmethod,'spline') 
        csd_interp=interp2(csd, options.smoothpoints, 'spline');
    end;
end;

if options.plot
    t=linspace(0,length(lfp)/samplingfrequency, length(csd_interp)); 
    imagesc(t, 1:size(lfp,1),csd_interp);    
    axis tight; box off;set(gca,'TickDir','out'); 
    
    % Normalize colors
    cxmax = max(abs(caxis));
    caxis([-cxmax cxmax]);
    
    % Plot LFP traces on top
    if options.plotlfp
        hold on; 
        % I am not sure if I should display only n-2 or n-4 or all channels
        % I have to check
        plot_lfp(lfp,samplingfrequency,'oncsd','on');
        %plot_lfp(lfp(2:size(lfp,1)-1,:),samplingfrequency,'oncsd','on');
        hold off;
    end
end;

if transpose;
    csd = csd';
end;