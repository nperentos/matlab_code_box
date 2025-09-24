function dwaves = find_dwaves(data, channels,recalc,appendfn)

if nargin<2;
    error('Please provide the data structure and channels')
end

if nargin<3 | isempty(recalc)
    recalc = 0;
end

if nargin<4 | isempty(appendfn)
    appendfn = [];
    cortexmuafn = get_lfp_filename(data.info.fn,'cmua');
else    
    cortexmuafn = get_lfp_filename(data.info.fn,['cmua' '.' appendfn]);
end

%% Calculate MUA
if ~exist(cortexmuafn) | recalc;
    start_parallel;
    parfor ch=1:length(channels)
        disp(['Converting channel ' num2str(ch)]);

        m = memmap_datfile(data.info.fn,'dat');
        maxl = size(m.Data.m,2);
        chunksize = 1200*data.info.datsr; % 20min of signal --> <200 MB at each time --> ~1.5 min/hour of signal for processing
        chunks = ceil(maxl/(chunksize));

        chunkidx = [([0:chunks-1] .* chunksize)'+1 ([1:chunks] .* chunksize)'];
        chunkidx(end,2) = maxl;

        tic;
        sigout = [];
        for c=1:size(chunkidx,1);
            sig = double(m.Data.m(channels(ch),chunkidx(c,1):chunkidx(c,2)));
            sig = filter_lfp(sig,data.info.datsr,[300 5000]);
            sig = abs(hilbert(sig));
            sig = decimate(sig,data.info.datsr/data.info.sr);
            sigout = cat(2,sigout,sig(:)');
        end
        toc;
        sigout = smooth_gauss(sigout,0.1*data.info.sr,0.05*data.info.sr);

        mua{ch,1} = sigout;    
    end

    % Create average MUA
    mua1 = zeros(1,length(mua{1}));

    for c=1:length(mua)
        mua1 = mua1 + mua{c};
    end
    mua1 = mua1./length(mua);
    mua1 = rescale_values(mua1,-(2^15-1),2^15-1);
    binary_save(cortexmuafn,mua1)
else
    mua1 = double(load_binary_noxml(cortexmuafn,1,1));
end

%% Find delta waves
sleep = data.states.sleep *data.info.sr;
muasleep = [];
for c=1:size(data.states.sleep,1)
    idx = round(sleep(c,1):sleep(c,2));
    muasleep = cat(2,muasleep,mua1(idx));
end
downthr = prctile(muasleep,30);
upthr = prctile(muasleep,50);
maxthr = prctile(muasleep,90);

down = LocalMinima(mua1,0.2*data.info.sr,downthr);
down = spikes_in_periods(down,data.states.sleep*data.info.sr);
%up = LocalMinima(-mua1,0.2*data.info.sr,-upthr);
%up(mua1(up)>maxthr)=[];
%up = spikes_in_periods(up,data.states.sleep*data.info.sr);

delta = (mua1 - downthr)<0;
delta = find_consecutive(delta);
[~,tmp]=spikes_in_periods(down,delta,1);
delta = delta(cellfun(@length,tmp)==1,:);
down(cell2mat(tmp(cellfun(@length,tmp)~=1)')) = [];

%% Calculate statistics
dwaves = struct();
dwaves.downthr = downthr;
dwaves.median = prctile(muasleep,50);

dwaves.rank = zeros(size(delta,1),1);
dwaves.onset = zeros(size(delta,1),1);
dwaves.offset = zeros(size(delta,1),1);

for c=1:size(delta,1)
    dwaves.rank(c) = sum(mua1(delta(c,1):delta(c,2)));
    dwaves.onset(c) = delta(c,1);
    dwaves.offset(c) = delta(c,2);    
end

dwaves.duration = diff(delta,[],2);
dwaves.ampl = mua1(down)';

[dwaves.rank,idx]= sort(dwaves.rank);
dwaves.rank = dwaves.rank./dwaves.median;
dwaves.t = down(idx);
dwaves.onset = dwaves.onset(idx);
dwaves.offset = dwaves.offset(idx);
dwaves.duration = dwaves.duration(idx);
dwaves.ampl = dwaves.median./dwaves.ampl(idx);

%% Add to the states
if ~isempty(appendfn)
    statesfn = get_lfp_filename(filebase,'states');
    tmp = load(statesfn,'-mat');
    states = tmp.states;
    states.dwaves = dwaves;
    save(statesfn,'states','-v7.3')
end
