function out = specwt(sig,varargin)

%% Arguments
options = {'freqrange',[],'df',0.1,'sr',1000,'wavelet','cmor3-1.5','resample',5};
options = inputparser(varargin,options);
if strcmp(options,'error'); return; end;
out.options = options;

%% Calculate
%tic;
if options.resample & ~isempty(options.resample) & options.resample>1;
    sig = decimate(sig,options.resample);
    options.sr = options.sr/options.resample;
end



out.w0 = centfrq(options.wavelet); 
factor = (1/(options.sr*out.w0)); % scale /freq. transform factor

if isempty(options.freqrange)
    out.f = [exp(0.1:0.045:log(min(250,options.sr/2)))]; % The default uses a geometric progression in the frequency scale
    out.t=0:(1/options.sr):(length(sig)/options.sr); out.t(1)=[];
    out.scales = 1./(factor*out.f);
    out.S = cwt(sig,out.scales,options.wavelet);
    %out.S = cwtft(sig,'scales',out.scales,'wavelet',options.wavelet);
    %out.S = dwt(sig,out.scales,options.wavelet);   
    
elseif length(options.freqrange) == 2
    if options.freqrange(1)<0.1; options.freqrange(1)=0.1; end;
    out.f = options.freqrange(1):options.df:options.freqrange(2);
    out.t=0:(1/options.sr):(length(sig)/options.sr); out.t(1)=[];
    out.scales = 1./(factor*out.f);
    out.S = cwt(sig,out.scales,options.wavelet);
    
else
    out.f = options.freqrange;
    out.t=0:(1/options.sr):(length(sig)/options.sr); out.t(1)=[];
    out.scales = 1./(factor*out.f);
    out.S = cwt(sig,out.scales,options.wavelet);    
end

% Calculate COI
out.N = length(sig);
bound = wavsupport(options.wavelet);
border = ceil(bound(2) * out.scales);
L  = min(floor(out.N/2), border);
R = max(ceil(out.N/2), out.N-border);
out.coi = [L(:), R(:)];

%toc;
