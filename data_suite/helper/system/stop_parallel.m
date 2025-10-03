function stop_parallel(myPool)
if nargin<1; myPool = gcp('nocreate'); end;
    
delete(myPool);