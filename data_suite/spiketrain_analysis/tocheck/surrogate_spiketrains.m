% maxlag in seconds (i.e. 5ms --> 0.005)
function surrogate = surrogate_spiketrains(spikes,n,method,maxlag)
if nargin<4; lag=1; end;

if nargin<3 || isempty(method);
    method = 'jitter';
end;

surrogate = zeros(n,length(spikes));

if strcmp(method,'isi_perm')
    isi = diff(spikes);
    for c=1:n
        new_isi = isi(randperm(length(isi)));
        new_spikes = [spikes(1);cumsum(new_isi)+spikes(1)];
        surrogate(c,:)=new_spikes;
    end;
elseif strcmp(method,'jitter')
    surrogate = repmat(spikes,1,n) -maxlag +2*maxlag*(rand(length(spikes),n));
end;