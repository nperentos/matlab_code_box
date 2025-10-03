function myPool = start_parallel(numCores)
distcomp.feature( 'LocalUseMpiexec', true);
maxCores = feature('numCores');
if nargin<1 || isempty(numCores) || numCores>maxCores; numCores=maxCores; end;

myPool = gcp('nocreate');
if isempty(myPool)
    myPool = parpool(numCores);
elseif myPool.NumWorkers ~=numCores 
    delete(gcp('nocreate'))
    myPool = parpool(numCores);
end