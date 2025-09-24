function varargout=calculate_xcorr(spikes1,spikes2,varargin)

options = {'binsize',0.005,'units','count','maxlag',0.5,'plot',1,'color','k','mode','xcorr'};
options = inputparser(varargin,options);
if strcmp(options,'error'); return; end;

if nargin<2 || isempty(spikes2); options.mode = 'auto'; spikes2=[]; end;

if strcmp(options.mode, 'auto');
    psth1 = calculate_psth(spikes1,'binsize',options.binsize);
    if strcmp(options.units,'coeff')
        x = xcorr(psth1,options.maxlag/options.binsize,'coeff'); 
    else
        x = xcorr(psth1,options.maxlag/options.binsize); 
    end;
    x((length(x)-1)/2+1)=0; % Remove zero lag    
    varargout{1}=x;
else
    psth1 = calculate_psth(spikes1,'binsize',options.binsize,'time',[min(min(spikes1),min(spikes2)), max(max(spikes1),max(spikes2))]);
    psth2 = calculate_psth(spikes2,'binsize',options.binsize,'time',[min(min(spikes1),min(spikes2)), max(max(spikes1),max(spikes2))]);
    if strcmp(options.units,'coeff') && length(psth1)==length(psth2)
        x = xcorr(psth1,psth2,round(options.maxlag/options.binsize),'coeff'); 
    else
        x = xcorr(psth1,psth2,round(options.maxlag/options.binsize)); 
    end;
    [cc,p] = corrcoef(psth1,psth2);
    cc = cc(1,2);
    varargout{1}=x;
    varargout{2}=cc;
    varargout{3}=p;    
end;
if options.plot,'on';
        plot(linspace(-options.maxlag,options.maxlag,length(x)),x,options.color)
        box off; set(gca,'TickDir','out');
        if strcmp(options.mode, 'auto'); title('Autocorrelogram'); else title('Crosscorrelogram'); end;
        xlabel('Lag (s)')
        if strcmp(options.units, 'count'); ylabel('Count'); else ylabel('Probability'); end;        
end;