function results = run_granger(sig,varargin)

% Input parsing
options = {'sr',1000,'targetSR',100, 'plot',1,'maxorder',20};
options = inputparser(varargin,options);
if strcmp(options,'error'); return; end;

%% Load data (Respiration)
X = [];
X(1,:) = decimate(sig(1,:),options.sr/options.targetSR);
X(2,:) = decimate(sig(2,:),options.sr/options.targetSR);

%% Estimation parameters
regmode   = 'OLS';  % VAR model estimation regression mode ('OLS', 'LWR' or empty for default)
icregmode = 'LWR';  % information criteria regression mode ('OLS', 'LWR' or empty for default)

morder    = 'AIC';  % model order to use ('actual', 'AIC', 'BIC' or supplied numerical value)
momax     = options.maxorder;     % maximum model order for model order estimation

acmaxlags = 1000;   % maximum autocovariance lags (empty for automatic calculation)

tstat     = 'F';     % statistical test for MVGC:  'F' for Granger's F-test (default) or 'chi2' for Geweke's chi2 test
alpha     = 0.05;   % significance level for significance test
mhtc      = 'FDR';  % multiple hypothesis test correction (see routine 'significance')

fs        = options.targetSR;    % sample rate (Hz)
fres      = [];     % frequency resolution (empty for automatic calculation)
ntrials   = 10;     % number of trials
nobs      = size(X,2);   % number of observations per trial

nvars = 2;
results = struct();

%% Model order estimation (<mvgc_schema.html#3 |A2|>)

% Calculate information criteria up to specified maximum model order.

ptic('\n*** tsdata_to_infocrit\n');
[AIC,BIC,moAIC,moBIC] = tsdata_to_infocrit(X,momax,icregmode);
ptoc('*** tsdata_to_infocrit took ');

% Plot information criteria.
if options.plot
    figure(1); clf;
    plot_tsdata([AIC BIC]',{'AIC','BIC'},1/fs);
    title('Model order estimation');

    fprintf('\nbest model order (AIC) = %d\n',moAIC);
    fprintf('best model order (BIC) = %d\n',moBIC);
end

% Select AIC model order
morder = moAIC;
results.morder = morder;

%% VAR model estimation (<mvgc_schema.html#3 |A2|>)

% Estimate VAR model of selected order from data.

ptic('\n*** tsdata_to_var... ');
[A,SIG] = tsdata_to_var(X,morder,regmode);
ptoc;

% Check for failed regression

assert(~isbad(A),'VAR estimation failed');

% NOTE: at this point we have a model and are finished with the data! - all
% subsequent calculations work from the estimated VAR parameters A and SIG.
results.A = A;

%% Autocovariance calculation (<mvgc_schema.html#3 |A5|>)

% The autocovariance sequence drives many Granger causality calculations (see
% next section). Now we calculate the autocovariance sequence G according to the
% VAR model, to as many lags as it takes to decay to below the numerical
% tolerance level, or to acmaxlags lags if specified (i.e. non-empty).

ptic('*** var_to_autocov... ');
[G,info] = var_to_autocov(A,SIG,acmaxlags);
ptoc;

% The above routine does a LOT of error checking and issues useful diagnostics.
% If there are problems with your data (e.g. non-stationarity, colinearity,
% etc.) there's a good chance it'll show up at this point - and the diagnostics
% may supply useful information as to what went wrong. It is thus essential to
% report and check for errors here.

var_info(info,true); % report results (and bail out on error)

results.G = G;
results.info = info;

%% Granger causality calculation: time domain  (<mvgc_schema.html#3 |A13|>)

% Calculate time-domain pairwise-conditional causalities - this just requires
% the autocovariance sequence.

ptic('*** autocov_to_pwcgc... ');
F = autocov_to_pwcgc(G);
ptoc;

% Check for failed GC calculation

assert(~isbad(F,false),'GC calculation failed');

% Significance test using theoretical null distribution, adjusting for multiple
% hypotheses.

pval = mvgc_pval(F,morder,nobs,ntrials,1,1,nvars-2,tstat); % take careful note of arguments!
signif  = significance(pval,alpha,mhtc);

% Plot time-domain causal graph, p-values and significance.
if options.plot
    figure(2); clf;
    subplot(1,3,1);
    plot_pw(F);
    title('Pairwise-conditional GC');
    subplot(1,3,2);
    plot_pw(pval);
    title('p-values');
    subplot(1,3,3);
    plot_pw(signif);
    title(['Significant at p = ' num2str(alpha)])
end

% For good measure we calculate Seth's causal density (cd) measure - the mean
% pairwise-conditional causality. We don't have a theoretical sampling
% distribution for this.

results.causaldens = mean(F(~isnan(F)));

fprintf('\ncausal density = %f\n',results.causaldens);

results.F = F;
results.pval = pval;
results.signif = signif;

%% Granger causality calculation: frequency domain  (<mvgc_schema.html#3 |A14|>)

% Calculate spectral pairwise-conditional causalities at given frequency
% resolution - again, this only requires the autocovariance sequence.

ptic('\n*** autocov_to_spwcgc... ');
f = autocov_to_spwcgc(G,fres);
ptoc;
fres = size(f,3)-1;
results.freqs1 = sfreqs(fres,fs)';
% Check for failed spectral GC calculation

assert(~isbad(f,false),'spectral GC calculation failed');

% Plot spectral causal graph.
if options.plot
    figure(3); clf;
    plot_spw(f,fs);
end

results.GC = [squeeze(f(2,1,:)) squeeze(f(1,2,:))]';

%% Granger causality calculation: frequency domain -> time-domain  (<mvgc_schema.html#3 |A15|>)

% Check that spectral causalities average (integrate) to time-domain
% causalities, as they should according to theory.

fprintf('\nchecking that frequency-domain GC integrates to time-domain GC... \n');
Fint = smvgc_to_mvgc(f); % integrate spectral MVGCs
mad = maxabs(F-Fint);
madthreshold = 1e-5;
if mad < madthreshold
    fprintf('maximum absolute difference OK: = %.2e (< %.2e)\n',mad,madthreshold);
else
    fprintf(2,'WARNING: high maximum absolute difference = %e.2 (> %.2e)\n',mad,madthreshold);
end

%% Example plot respiration
freqs = linspace(0,50, size(f,3));
results.freqs = freqs;

if options.plot
    figure; 
    subplot(2,1,1);
    plot(freqs,squeeze(f(1,2,:)))
    hold on;  plot(freqs,squeeze(f(2,1,:)));
    legend({'2 --> 1', '1 --> 2'});
    xlim([0 12])

    subplot(2,1,2);
    [~,idx] = spikes_in_periods(freqs,[2 6]);
    twobarplot([mean(f(1,2,idx)) ; mean(f(2,1,idx))],[],{'b','r'},{'2 --> 1', '1 --> 2'})
end