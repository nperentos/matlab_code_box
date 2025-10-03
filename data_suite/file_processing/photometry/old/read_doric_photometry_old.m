%Time(s)	AnalogIn-1	AnalogIn-2	AnalogIn-3	AnalogIn-4	Sequence	TTL-1	TTL-2	TTL-3	TTL-4	AnalogOut-1	AnalogOut-2	AnalogOut-3	AnalogOut-4

function out = read_doric_photometry(fn)
%out.csv = dlmread(fn,',',1,0);

fid = fopen(fn); 
tmp = textscan(fid,'%f %f %f %*f %*f %*f  %f  %*f  %*f  %*f  %*f  %*f  %*f  %*f  %*f','HeaderLines',1,'Delimiter',','); 
fclose(fid); 
%%
out.t = tmp{1};
out.sig470 = tmp{2};
out.sig405 = tmp{3};
out.sig470ref = 
out.ttl = tmp{1}(find(tmp{4}>0,1,'first'));

clear tmp

%% Fix timestamps and resample
[tmp,tmpt] = resample(out.sig470,out.t,1000);
out.sig470 = tmp;

[tmp,tmpt] = resample(out.sig405,out.t,1000);
out.sig405 = tmp;

out.t = tmpt;

[~,idx]=min(abs(out.t - out.ttl));
out.ttl = out.t(idx);
out.ttl_idx = idx;

%%out.S = specmt(out.sig470(30000:40000),'window',1,'freqrange',[0 250]);

