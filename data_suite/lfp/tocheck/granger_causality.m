%
function result = granger_causality(lfps,samplingrate,varargin)

% Input parsing
options = {'testing',0,'orderstesting',[1:5:100],'maxorder',100,'fpass',[1:1:20],'windowsize',1,'targetSR',100,'bootstrapN',0,'bootstrapWindow',1,'permuteN',0,'permuteWindow',1};
options = inputparser(varargin,options);
if strcmp(options,'error'); return; end;

if size(lfps,1)~=2; error('This function works only on bivariate signals.'); end;
if (~(samplingrate==options.targetSR)) && mod(samplingrate,options.targetSR)~=0; 
    error('The mod(samplingrate,targetSR) should be 0.'); 
end;

if samplingrate~=options.targetSR 
    lfps1(1,:) = decimate(lfps(1,:),samplingrate/options.targetSR);
    lfps1(2,:) = decimate(lfps(2,:),samplingrate/options.targetSR);
    lfps = lfps1;
    samplingrate = options.targetSR;
end;

if options.testing
    figure;
    subplot(2,1,1);
    acf(1,:) = cca_sacf(lfps(1,:),options.maxorder,1);
    subplot(2,1,2);
    acf(2,:) = cca_sacf(lfps(2,:),options.maxorder,1);

    for k=1:length(options.orderstesting)
        uroot(1,k) = cca_check_cov_stat(lfps(1,:),options.orderstesting(k));
        uroot(2,k) = cca_check_cov_stat(lfps(2,:),options.orderstesting(k));
        [H(1,k),ks(1,k)]= cca_kpss(lfps(1,:),options.orderstesting(k),0.01);
        [H(2,k),ks(2,k)]= cca_kpss(lfps(2,:),options.orderstesting(k),0.01);
    end
    
    result.acf = acf;
    result.uroot = uroot;
    result.H = H;
    result.ks = ks;
end

% Linear detrend
lfps = detrend(lfps')';

% Zero mean
lfps = bsxfun(@minus,lfps,mean(lfps,2));
lfps = bsxfun(@rdivide,lfps,std(lfps,0,2));

[bic,aic] = cca_find_model_order(lfps,1,options.maxorder);
result.bic = bic;
result.aic = aic;

modelorder = max(bic,aic);
result.modelorder = modelorder;

[ret] = cca_granger_regress(lfps,modelorder);
result.ret = ret;

[GW,COH,pp,waut,cons]=cca_pwcausal(lfps,1,size(lfps,2),modelorder,samplingrate,options.fpass,1);

result.GW = [squeeze(GW(1,2,:)) squeeze(GW(2,1,:))];
result.freqs = options.fpass;
result.coherence = squeeze(COH(1,2,:));
result.Power = pp;
result.waut = waut;
result.cons = cons;

if options.bootstrapN>0 
    [ret] = cca_pwcausal_bootstrap(lfps,1,size(lfps,2),modelorder,500,options.bootstrapWindow*SR,samplingrate, options.fpass,0.01);
    options.bootstrap = ret;
end

if options.permuteN>0 
    [ret] = cca_pwcausal_permute(lfps,1,size(lfps,2),modelorder,500,options.permuteWindow*SR,samplingrate, options.fpass,0.01);
    options.permute = ret;
end