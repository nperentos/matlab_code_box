% 
% 
% Date: 27/05/2014
% Author: Nikolas Karalis
function out = chunk_signal(signal,piecelength,padflag)
if nargin<3; padflag=0; end;

signal = signal(:);

N1 = length(signal)/piecelength;
N = floor(N1);

if (N1-N)>0 && padflag
    l1 = (N+1)*piecelength;
    signal = cat(1,signal,zeros(l1-length(signal),1));
    N = N+1;
elseif (N1-N)>0 && ~padflag
    signal = signal(1:N*piecelength);
end

out = zeros(N,piecelength);

for k=1:N
    out(k,:) = signal((k-1)*piecelength+1:k*piecelength);
end
