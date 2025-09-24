% To add:
% output, ascending/descending phase, internal bad state checking

function [trig_sig, trig_t] = prep_trig(data,varargin)

% Input parsing
options = {'channels',[],'refch',[],'triggers',[],'phase','trough','freqs',[],'goodepochs',[],'badepochs',[],'filterchannels',[],'window',0.5};
options = inputparser(varargin,options);

%% Input checking
if isempty(options.refch) | isempty(options.channels)
    error('Please provide all channels');
end

if isempty(options.triggers) & (isempty(options.freqs) | isempty(options.phase))
    error('Please provide either triggers or frequency band and phase');
end

%% Prepare signal
if ~isempty(options.triggers);
    trig = options.triggers * data.info.sr;
elseif isempty(options.triggers);    
    sig = getmd(data,options.refch);
    sig = filter_lfp(sig,data.info.sr,options.freqs);
    if strcmp(options.phase,'peak')
        sig = -sig;
    end
    peakspacing = 1.25 * 1000/max(options.freqs);
    trig = LocalMinima(sig,peakspacing); % This is just a heuristic to get the minimum distance between peaks to fall in a proper range.
end

trig = spikes_in_periods(trig,options.goodepochs * data.info.sr);
trig1 = spikes_in_periods(trig,options.badepochs * data.info.sr);
trig = setdiff(trig,trig1);


%% Filter output
if ~isempty(options.filterchannels)
    [trig_sig, trig_t] = mtrig_filt(data,options.channels,trig, options.filterchannels, options.window * data.info.sr);
else 
    [trig_sig, trig_t] = mtrig_lfp(data,options.channels,trig, options.window * data.info.sr);
end

