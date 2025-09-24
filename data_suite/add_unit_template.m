function add_unit_template(filebase, filtermode);

if nargin<2; filtermode = 1; end;

info = get_datfile_info(filebase);

unitsfn = get_lfp_filename(filebase,'units');
tmp = load(unitsfn,'units','-mat');
units = tmp.units;
%%
if filtermode;
    nspikes = 1000;
    filter_window = 1000;
    spike_window = 30;

    m = memmap_datfile(filebase,'dat');
    maxtime = size(m.Data.m,2);

    template = cell(length(units.id),1);
    waveform = cell(length(units.id),1);
    ids = units.id;
    parfor c=1:length(ids)
        tic;
        disp(['Calculating template ' num2str(c) '/' num2str(length(ids))]);
        spikes = units.spikes{c};
        spikes = spikes(randi(length(spikes),min(nspikes,length(spikes)),1)); % random 1000 spikes (or all spikes if less than 1000);    
        spikes((spikes<filter_window) | (spikes>maxtime - filter_window) )=[]; % ensure we get spikes that fit the window
        idx = periodindices(spikes,filter_window); idx = idx(:);
        chans = units.channel(c);
        chans = chans-5:chans+5;
        chans = spikes_in_periods(chans,[1 size(m.Data.m,1)+1]);
        sig = double(m.Data.m(chans,idx));
        sigout = [];
        for ch=1:size(sig,1);
            %sig1 = sig(ch,:);
            sig1 = filter_lfp(double(sig(ch,:)),info.fs,[20 0]);    
            sig1 = reshape(sig1(:),2*filter_window+1,length(spikes))';
            sample_idx = (filter_window-spike_window+1):(filter_window+spike_window+1); % keep samples from the middle
            sigout(:,:,ch) = sig1(:,sample_idx);
        end
        sigout = squeeze(mean(sigout,1))';
        for ch=1:size(sigout,1); sigout(ch,:) = sigout(ch,:)+ch*1000; end;
        template{c} = sigout;
        waveform{c} = sigout(find(chans==units.channel(c)),:);
        toc;
    end
else
    nspikes = 1000;
    spike_window = 30;

    m = memmap_datfile(filebase,'dat');
    maxtime = size(m.Data.m,2);

    template = cell(length(units.id),1);
    waveform = cell(length(units.id),1);
    ids = units.id;
    parfor c=1:length(ids)
        tic;
        disp(['Calculating template ' num2str(c) '/' num2str(length(ids))]);
        spikes = units.spikes{c};
        %spikes = spikes(randi(length(spikes),min(nspikes,length(spikes)),1)); % random 1000 spikes (or all spikes if less than 1000);    
        spikes((spikes<spike_window) | (spikes>(maxtime - spike_window)) )=[]; % ensure we get spikes that fit the window
        idx = periodindices(spikes,spike_window); idx = idx(:);
        chans = units.channel(c);
        chans = chans-5:chans+5;
        chans = spikes_in_periods(chans,[1 size(m.Data.m,1)+1]);
        sig = double(m.Data.m(chans,idx));
        sig1 = reshape(sig,length(chans),2*spike_window+1,length(spikes));
        sigout = squeeze(mean(sig1,3));
        for ch=1:size(sigout,1); sigout(ch,:) = sigout(ch,:)+ch*1000; end;
        template{c} = sigout;
        waveform{c} = sigout(find(chans==units.channel(c)),:);
        toc;
    end
end;

units.template = template;
units.waveform = waveform;
%%
save(unitsfn,'units');