function pval = CCGSignifConv(ccg, win, varargin)
%function CCGSignifConv(ccg, win, kern, alpha, bin)
% this test the significance of peak in ccg (presence of cofirings)
% using convolution with hollowed windows as in
% Stark & Abeles JNMethods 2009
% input: ccg - raw ccg btw 2 spike trains returned by CCG or PointCorrel.
% win - size of the smoothing window (in bins) which corresponds to
% expected correlation time scale. smoothing with it should destroy
% correlation structure of interest .. try first! see the plots, predictor
% should be flat in the time scale you care about. if too noisy - recompute
% the ccg with larger, more appropriate bin size.
% bin - vector of bin value (returned by ccg calculation)
% kern - type of kernel ('square' or 'gauss')
% alpha - just for plotting - significance level
%..no multiple comparion so far.
[kern, alpha,bin, nRand] = DefaultArgs(varargin,{'gauss',0.01,[],1});
if ~mod(win,2) win=win+1; end
nbins = size(ccg,1);
switch kern
    case 'square'
        conv_kern = ones(win,1);
        conv_kern((win-1)/2)=conv_kern((win-1)/2)*0.5;
        
    case 'gauss'
        sdg = (win-1)/2;
        conv_kern = gausskernel(sdg, 0, 6*sdg+1, 1);
        conv_kern(sdg*3+1) = conv_kern(sdg*3+1)*1/3;
        
        
end
conv_kern = conv_kern/sum(conv_kern);

ccgrep = [ccg(end:-1:2); ccg; ccg(end-1:-1:1)];

ccg_pred = Filter0(conv_kern,ccgrep);

ccg_pred = ccg_pred(nbins:end-nbins+1);

pval = 1 - poisscdf(ccg-1, ccg_pred);
if nRand>0
            R = rand(nbins, nRand);
            dP = (poisspdf(ccg, ccg_pred) * ones(1, nRand) ).*R;
            pval = pval * ones(1,nRand)-dP;
end
%keyboard
if nargout<1
    if isempty(bin)
        bin = [1:nbins];
    end
   figure(881);clf
   subplot(211)
   plot(bin,ccg);
   hold on
   plot(bin,ccg_pred,'g');
   legend('original','predictor');
   plot(bin(pval<alpha),ccg(pval<alpha),'rx')
    subplot(212)
    plot(bin,-log10(pval));
    ylabel('-log10(pval)');
end

return
function K = gausskernel(sigmaX,sigmaY,N,M)
x = -(N-1)/2:(N-1)/2;
y = -(M-1)/2:(M-1)/2;
if sigmaY == 0 & sigmaX == 0
    K = zeros(M,N);
    return;
elseif sigmaY == 0
    X = -inf*ones(M,N);
    Y = X;
    X(ceil(M/2),:) = x;
    Y(ceil(M/2),:) = 0;
    sigmaY = 1;
elseif sigmaX == 0
    Y = -inf*ones(M,N);
    X = Y;
    X(:,ceil(N/2)) = 0;
    Y(:,ceil(N/2)) = y(:);
    sigmaX = 1;
else
    X = repmat(x,M,1);
    Y = repmat(y,N,1)';
end
K = 1/(2*pi*sigmaX*sigmaY)*exp(-(X.^2/2/sigmaX^2)-(Y.^2/2/sigmaY^2));
