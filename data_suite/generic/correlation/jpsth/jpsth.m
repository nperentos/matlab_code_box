% modified from JPSTH Toolbox to work directly from spike timestamps in one
% function
% 
% Copyright 2008 Vanderbilt University.  All rights reserved.
% John Haitas, Jeremiah Cohen, and Jeff Schall

% Functions:
% trig_spikes
% equation3, pst_coincidence_histogram, significant_span, cross_correlation_histogram

function data = jpsth(spikes1, spikes2, events, varargin)

%% Arguments
options = {'binsize',10,'windowsize',500,'sameelectrode',0};
options = inputparser(varargin,options);

coin_width = options.binsize;

%% Triggered spikes
spikes1 = trig_spikes(spikes1,events,options.windowsize,options.binsize);
spikes2 = trig_spikes(spikes2,events,options.windowsize,options.binsize);

%% PSTH
psth_1 = mean(spikes1);
psth_1_std = std(spikes1);
psth_1_var = var(spikes1);

psth_2 = mean(spikes2);
psth_2_std = std(spikes2);
psth_2_var = var(spikes2);

%%
% JPSTH Equations from Aertsen et al. 1989
raw_jpsth = equation3(spikes1, spikes2);						% Eq. 3
psth_outer_product = psth_1(:) * psth_2(:)';			% Eq. 4
unnormalized_jpsth = raw_jpsth - psth_outer_product;	% Eq. 5
normalizer = psth_1_std(:) * psth_2_std(:)';			% Eq. 7a
normalized_jpsth = unnormalized_jpsth ./ normalizer;	% Eq. 9


% When normalizer = 0 it causes divide by zero which results in NaN
% the following for loop replaces these NaN's with 0's
% this occurs for discrete time points with no spikes
normalized_jpsth(isnan(normalized_jpsth)) = 0;

% analyze JPSTH
xcorr_hist = cross_correlation_histogram(normalized_jpsth);

pstch = pst_coincidence_histogram(normalized_jpsth, -coin_width:coin_width);

[covariogram,sig_high,sig_low] = covariogram_brody(spikes1,spikes2,psth_1,psth_2,psth_1_var,psth_2_var);
sig_peak_endpoints = significant_span(covariogram,sig_high);
sig_trough_endpoints = significant_span(-covariogram,-sig_low);


%if pair recorded on same electrode, then negative peak on main diagonal results from recording limitations
%to keep this from skewing pstch we need to exclude the main diag from pstch in these cases
if options.sameelectrode
    pstch = pst_coincidence_histogram(normalized_jpsth, [-coin_width:-1,1:coin_width]);
else
    pstch = pst_coincidence_histogram(normalized_jpsth, -coin_width:coin_width);
end
    
% build data structure to return from function
data = struct('psth_1',psth_1,'psth_2',psth_2, ...
    'normalized_jpsth',normalized_jpsth, ...
    'unnormalized_jpsth',unnormalized_jpsth, ...
    'xcorr_hist',xcorr_hist, ...
    'pstch',pstch, ...
    't',linspace(-options.windowsize,options.windowsize,length(pstch)), ...
    'sig_low',sig_low, ...
    'sig_high',sig_high, ...
    'sig_peak_endpoints',sig_peak_endpoints,...
    'sig_trough_endpoints',sig_trough_endpoints);

%%
