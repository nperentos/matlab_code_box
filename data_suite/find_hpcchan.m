function hpcchan = find_hpcchan(data)

if isfield(data.channels,'ca1')
    hpcchan = data.channels.ca1;
elseif isfield(data.channels,'dca1')
    hpcchan = data.channels.dca1;
elseif isfield(data.channels,'hpc')
    hpcchan = data.channels.hpc;
elseif isfield(data.channels,'vca1')
    hpcchan = data.channels.vca1;
elseif isfield(data.channels,'v1')
    hpcchan = data.channels.v1;
else
    hpcchan = [];
end