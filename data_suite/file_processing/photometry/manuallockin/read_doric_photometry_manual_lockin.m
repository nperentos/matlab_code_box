%Time(s)	AnalogIn-1	AnalogIn-2	AnalogIn-3	AnalogIn-4	Sequence	TTL-1	TTL-2	TTL-3	TTL-4	AnalogOut-1	AnalogOut-2	AnalogOut-3	AnalogOut-4

% Generally slow function. ~10min/hour of recording

% Reading file: ~4 min/hour of recording
% Resampling data: ~ 3 min/hour of recording
% Demodulating signals: ~2 min/hour of recording
% Downsampling signals: ~1 min/hour of recording

function out = read_doric_photometry_lockin(fn, uvflag)

if nargin<2; uvflag = 1; end;

tic;
fid = fopen(fn); 
csvdata = textscan(fid,'%f %f %f %f %f %*f  %f  %*f  %*f  %*f  %*f  %*f  %*f  %*f  %*f','HeaderLines',1,'Delimiter',','); 
fclose(fid); 
disp('Finished reading file')
toc;

%%
out.t = csvdata{1};

newsr = 12000;

tic;
[tmp,tmpt] = resample(csvdata{2},out.t,newsr);
out.sig470 = tmp;
tmp = toc;

disp([num2str(tmp*4) ' sec remaining']);

[tmp,tmpt] = resample(csvdata{4},out.t,newsr);
out.sig470_ref = tmp;

if uvflag;
    [tmp,tmpt] = resample(csvdata{3},out.t,newsr);
    out.sig405 = tmp;

    [tmp,tmpt] = resample(csvdata{5},out.t,newsr);
    out.sig405_ref = tmp;
end

[tmp,tmpt] = resample(csvdata{6},out.t,newsr);
out.ttl_trace = tmp;

out.t = tmpt;

% Find first TTL
ttl_idx = find(out.ttl_trace>0,1,'first');
out.ttl = out.t(ttl_idx);

clear csvdata

disp('Data resampled');

disp('Demodulating 470nm signal');
tic; out.sig470_dem = lockin_demodulate(out.sig470,out.sig470_ref,newsr); toc;

if uvflag;
    disp('Demodulating 405nm signal');
    tic; out.sig405_dem = lockin_demodulate(out.sig405,out.sig405_ref,newsr); toc;
end

%% Downsample everything
disp('Downsampling signals');

tic; out.sig470 = decimate(out.sig470,newsr/1000); tmp = toc;

disp([num2str(tmp*6) ' sec remaining']);

out.sig470_ref = decimate(out.sig470_ref,newsr/1000);
out.sig405_dem = decimate(out.sig405_dem,newsr/1000);
out.sig470_dem = decimate(out.sig470_dem,newsr/1000);
out.ttl_trace = decimate(out.ttl_trace,newsr/1000);

out.t = make_time(out.sig470_dem,0,1000);

if uvflag;
    out.sig405 = decimate(out.sig405,newsr/1000); 
    out.sig405_ref = decimate(out.sig405_ref,newsr/1000);
end

if ~isempty(out.ttl);
    [~,idx]=min(abs(out.t - out.ttl));
    out.ttl = out.t(idx);
    out.ttl_idx = idx;
end

%% Save 
disp('Saving...');
fnout = [fn(1:end-3) 'doric.mat'];
save(fnout,'out','-v7.3');



