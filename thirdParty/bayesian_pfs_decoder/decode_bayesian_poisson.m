function E=decode_bayesian_poisson(ratemaps,spikecounts,varargin)
%DECODE_BAYESIAN_POISSON stimulus decoding using bayesian method
%
%  posterior=DECODE_BAYESIAN_POSSION(ratemaps,spikecounts) computes the
%  posterior probability distribution from a set of tuning curves (size:
%  [D1 D2 ... Dn Ncells]; D1 to Dn represent the n stimulus dimensions; the
%  last dimension represents the number of cells) and a matrix of spike
%  counts (size: [Ncells NTimeBins]).
%
%  posterior=DECODE_BAYESIAN_POISSON(...,parm1,val1,...) set optional
%  parameters for decoding. Valid parameters are:
%   prior - an array (size: [D1 D2 ... Dn]) that defines the prior
%           probability distribution. Use empty array for uniform prior
%           (equivalent to maximum likelihood estimation). (default = [])
%   bins - scalar or vector (size: [NTimeBins 1]) with the duration of time
%          bins (default = 1) NP: number of time steps to average across -
%          reduces noisy and refers to the continuity constraint of Zhang 1998
%          if I understand correctly 
%   alpha - scalar or vector (size: [1 Ncells]) with scaling factor for
%           tuning curves (default = 1)
%   baseline - scalar. Baseline rate added to all tuning curves. (default =
%              0.01 Hz)
%

%  Copyright 2006-2011 Fabian Kloosterman

options = struct('prior',         [],    ...
                 'bins',          [],    ...
                 'normalization', 'sum', ...
                 'alpha',         1,     ...
                 'baseline',      0.01);

[options,other, remainder] = parseArgs_pfs(varargin,options); %#ok


sz = size(ratemaps);
nt = size(spikecounts,2);

%collapse dimensions 2...n
if numel(sz)>2
  ratemaps = reshape( ratemaps, [prod(sz(1:(end-1))) sz(end)] );
end

%process bin sizes
if isempty(options.bins)
  options.bins = ones( 1, nt );
elseif isscalar(options.bins)
  options.bins = options.bins.*ones(1, nt );
elseif isvector(options.bins) && numel(options.bins)==nt
  options.bins = options.bins(:)';
elseif size(options.bins,1)==nt && size(options.bins,2)==2
  options.bins = diff( options.bins, [], 2)';
else
  error('reconstruct_bayesian_poisson:invalidArguments', 'Invalid bins')
end

%apply alpha factor
if ~isequal(options.alpha,1)
  if isvector(options.alpha) && numel(options.alpha)==size(spikecounts,1)
    ratemaps = bsxfun( @times, ratemaps, options.alpha(:)' );
  elseif isscalar(options.alpha)
    ratemaps = ratemaps.*options.alpha;
  else
    error('reconstruct_bayesian_poisson:invalidArguments', ['Invalid ' ...
                        'alpha'])
  end
end

ratemaps(ratemaps<0)=0;
ratemaps=ratemaps+options.baseline; %add very small value to make algorithm robust

%do reconstruction
E = sum( ratemaps, 2 ) * -options.bins;
E = exp( E + bayesian_helper( log(ratemaps), spikecounts ) );

%multiply by prior
if ~isempty(options.prior)
  E = E .* repmat( options.prior(:), [ 1 size(E, 2) ] );
end

%normalize
E = E ./ nansum(E );

%"uncollapse" dimensions
if numel(sz)>2
  E = reshape(E, [sz(1:(end-1)) nt] );
end
