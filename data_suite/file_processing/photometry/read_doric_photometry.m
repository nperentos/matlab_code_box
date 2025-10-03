%Time(s)	AnalogIn-1	AnalogIn-2	AnalogIn-3	AnalogIn-4	Sequence	TTL-1	TTL-2	TTL-3	TTL-4	AnalogOut-1	AnalogOut-2	AnalogOut-3	AnalogOut-4

function out = read_doric_photometry(filebase, nchannels)
if nargin<2; nchannels = 2; end;
%out.csv = dlmread(fn,',',1,0);

if isdir(filebase)
    fn = get_lfp_filename(filebase,'fbr.csv');
else
    fn = filebase;
end

%% Load the csv file
fid = fopen(fn);
csvdata = textscan(fid,'%f %f %f %f %f %*f  %f  %*f  %*f  %*f  %*f  %*f  %*f  %*f  %*f','HeaderLines',1,'Delimiter',',');
fclose(fid);

%% Organize the data
out.t = csvdata{1};

out.sig470 = csvdata{2};

if nchannels>1
    out.sig405 = csvdata{3};
end

if nchannels>2
    out.sig470ref = csvdata{4};
end

if nchannels>3
    out.sig470lockin = csvdata{5};
end

ttlch = length(csvdata);
out.ttl = csvdata{1}(find(csvdata{ttlch}>0,1,'first'));

clear tmp

%% Fix timestamps and resample

[tmp,tmpt] = resample(out.sig470,out.t,1000);
out.sig470 = tmp;


if nchannels>1
    [tmp,tmpt] = resample(out.sig405,out.t,1000);
    out.sig405 = tmp;
end

if nchannels>2
    [tmp,tmpt] = resample(out.sig470ref,out.t,1000);
    out.sig470ref = tmp;
end

if nchannels>3
    [tmp,tmpt] = resample(out.sig470lockin,out.t,1000);
    out.sig470lockin = tmp;
end

out.t = tmpt;

[~,idx]=min(abs(out.t - out.ttl));
out.ttl = out.t(idx);
out.ttl_idx = idx;

%% Save
%disp('Saving...');
%fnout = [fn(1:end-3) 'doric.mat'];
%save(fnout,'out','-v7.3');


