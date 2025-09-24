function ripples = find_ripples(x, varargin)

%% Input parsing
options = {'sr',1000,'method','hilbert','plot',1,'ripplefreq',[80 250],'mode','auto','thr',2.5,'mincycles',4,'refsig',[], 'periods',[],'wavelet_freq',0};

options = inputparser(varargin,options);

if strcmp(options,'error'); return; end;



%% Hilbert (new)
if strcmp(options.method,'hilbert')
    % Reference the signal
    %if ~isempty(options.refsig) && length(options.refsig)==length(x);
    %    x = x - options.refsig;
    %end
       
    filt_sig = filter_lfp(x,options.sr, options.ripplefreq); % Filter
    swr_env = abs(hilbert(filt_sig)); % Envelope
    
    if ~isempty(options.refsig) && length(options.refsig)==length(x);
        filt_sig1 = filter_lfp(options.refsig,options.sr, options.ripplefreq); % Filter
        swr_env1 = abs(hilbert(filt_sig1)); % Envelope
        swr_env = swr_env - swr_env1;
        clear filt_sig1 swr_env1
    end
    
    %swr_env = abs(nonlinear_energy_operator(swr_env));
    
    % Low-pass filter
    sigma = 0.1;
    kernelsize = 0.1 * options.sr; % 100ms
    gaussFilter = gausswin(kernelsize,1/(2.5*sigma));
    gaussFilter = gaussFilter / sum(gaussFilter); % Normalize.    
    swr_env = conv(swr_env, gaussFilter,'same');
    %swr_env = filtfilt(gaussFilter,1,swr_env);

    ripple_t = LocalMinima(-swr_env,0.02 * options.sr)';

    if ~isempty(options.periods);
        ripple_t = spikes_in_periods(ripple_t,options.periods .* options.sr)'; % transpose!
    end   
    %%
    ripple_amp = swr_env(ripple_t);
    
    if ~isempty(options.periods);
        t = linspace(0, length(swr_env)/options.sr,length(swr_env));
        [~,tmp] = spikes_in_periods(t, options.periods);
        thr = mean(swr_env(tmp)) + options.thr*std(swr_env(tmp));
        thrmax = mean(swr_env(tmp)) + 18*std(swr_env(tmp));
    else
        thr = mean(swr_env) + options.thr*std(swr_env);
        thrmax = mean(swr_env) + 18*std(swr_env);    
    end   
    
    if strcmp(options.mode,'manual')
        figure;
        jplot(linspace(0,length(x)/options.sr,length(x)),0.02*x);
        hold on;
        jplot(linspace(0,length(swr_env)/options.sr,length(swr_env)),swr_env,'r');
        jplot(ripple_t/options.sr,ripple_amp,'r*');
        h = imline(gca,get(gca,'xlim'), [thr thr]);
        disp('Move the line to the desired threhold');        
        resp = input('Are you done (press Enter)?');        
        thr = h.getPosition;
        thr = thr(1,2);
    end;
    
    %allripple_t = ripple_t(ripple_amp>(mean(swr_env) + 1*std(swr_env))); % get most events (>1SD)
    %allripple_amp = swr_env(allripple_t);
    
    ripple_t = ripple_t(ripple_amp>=thr & ripple_amp<thrmax);    
    ripple_t = sort(ripple_t);
    
    ripple_amp = swr_env(ripple_t);
    ripple_amp_norm = (ripple_amp-mean(swr_env))/std(swr_env);   
    
    
    %% Calculate ripple stats (duration, number of cycles, frequency)
    
    ripple_onset = zeros(1,length(ripple_t));
    ripple_offset = zeros(1,length(ripple_t));
    ripple_dur = zeros(1,length(ripple_t));
    ripple_cycles = zeros(1,length(ripple_t));
    ripple_f = zeros(1,length(ripple_t));    
    ripple_ici = zeros(1,length(ripple_t));    
    ripple_troughs_min = zeros(1,length(ripple_t));
    
    for c=1:length(ripple_t)
        %tmp = round(ripple_t(c)-0.25*options.sr):round(ripple_t(c)+0.25*options.sr);
        %tmp = tmp(tmp>0 & tmp<length(filt_sig));
        fsig = trig_lfp(filt_sig,ripple_t(c),0.25*options.sr);        
        env = trig_lfp(swr_env,ripple_t(c),0.25*options.sr);        
        
        if isempty(fsig); 
            ripple_cycles(c) = 0;
            continue; 
        end;
        
        idx = LocalMinima(env);
        idx1 = idx(find(idx<0.25*options.sr,1,'last'));
        
        idx2 = idx(find(idx>0.25*options.sr,1,'first'));
        if isempty(idx1) | isempty(idx2); continue; end;
        ripple_onset(c) = round(ripple_t(c) - (251 - idx1)/2);
        ripple_offset(c) = round(ripple_t(c) + (idx2 - 251)/2);       
      
        troughs=LocalMinima(fsig, 1*options.sr./options.ripplefreq(2), 0);
        ripple_troughs = spikes_in_periods(ripple_t(c)-251+troughs, [ripple_onset(c) ripple_offset(c)]);
        
        try; %if there are no troughs within the cycle - no worries, they are removed in the next step (mincycles)
            [~, idx] = min(filt_sig(ripple_troughs));
            ripple_troughs_min(c) = ripple_troughs(idx);
        catch;
            ripple_troughs_min(c) = 0;
        end
       
        ripple_dur(c) = ripple_offset(c) - ripple_onset(c);        
        ripple_cycles(c) = length(ripple_troughs);
        ripple_f(c) = options.sr/mean(diff(ripple_troughs));
        ripple_ici(c) = mean(diff(ripple_troughs));
    end
    
    % Remove events with few cycles
    idx = (ripple_cycles<options.mincycles) | (ripple_troughs_min==0);
    ripple_dur(idx)=[];
    ripple_cycles(idx)=[];
    ripple_f(idx)=[];
    ripple_t(idx)=[];
    ripple_amp(idx)=[];
    ripple_amp_norm(idx)=[];
    ripple_ici(idx)=[];
    ripple_onset(idx) = [];
    ripple_offset(idx) = [];
    ripple_troughs_min(idx) = [];
    
    %% Find ripple sequences
    tmp = find(diff(ripple_t)<500); % Find ripples spaced at least half a second
    [~,rippleseq] = find_sequential(tmp);
    rippleseq = cellfun(@(x) [x x(end)+1], rippleseq,'un',0);
    isolatedripples = setdiff(1:length(ripple_t),cell2mat(rippleseq));
    firstripples = [cellfun(@(x) x(1), rippleseq) isolatedripples];
    
    %% Prepare output
    ripples = struct();
    ripples.ripple_t = ripple_t;
    ripples.ripple_dur = ripple_dur;
    ripples.ripple_cycles = ripple_cycles;
    ripples.ripple_f = ripple_f;
    ripples.ripple_amp = ripple_amp;    
    ripples.ripple_amp_norm = ripple_amp_norm;
    ripples.ripple_troughs_min = ripple_troughs_min;    
    %ripples.swr_env = swr_env;
    %ripples.filt_sig = filt_sig;
    ripples.ripple_ici = ripple_ici;
    ripples.rippleseq = rippleseq;
    ripples.isolatedripples = isolatedripples;
    ripples.firstripples = firstripples;
    ripples.ripple_onset = ripple_onset;
    ripples.ripple_offset = ripple_offset;
    ripples.threshold = thr;
    ripples.meanpower = mean(swr_env);
    ripples.stdpower = std(swr_env);
    ripples.thr_rank = (thr - ripples.meanpower) / ripples.stdpower;
    ripples.options = options;
    
    %% Recalculate frequency using wavelet
    % This is much slower procedure, so not doing it by default
    % ~40 sec / 1000 ripples --> 5min/hour of recording
    if options.wavelet_freq
        tic;
        fw = [];
        for c=1:size(pyrtrig,1);
            tmp = specwt(trig_lfp(x,ripples.ripple_t(c),500),'freqrange',[70:1:200]);
            [~,tidx] = spikes_in_periods(tmp.t,[0.48 0.52]);
            [~,fidx]=max(abs(tmp.S(:,tidx)));
            ripples.f = mean(tmp.f(fidx));            
        end
        toc;
    end
    
    %% Plot
    if options.plot;
        figure;
        jplot(linspace(0,length(x)/options.sr,length(x)),x);
        hold on;
        jplot(linspace(0,length(swr_env)/options.sr,length(swr_env)),swr_env,'r');
        jplot(ripple_t/options.sr,ripple_amp,'r*');

        fig;
        subplot(2,3,1);
        [tmp,xax,yax] = hist2([ripple_f ; ripple_amp_norm]',50,50);
        imagesc(xax,yax,smoothn(tmp,5)'); axis xy;
        ylabel('Amplitude (# SDs)');
        xlabel('Frequency (Hz)');
        
        subplot(2,3,2);
        [tmp,xax,yax] = hist2([ripple_dur ; ripple_amp_norm]',50,50);
        imagesc(xax,yax,smoothn(tmp,5)'); axis xy;
        ylabel('Amplitude (# SDs)');
        xlabel('Duration (ms)');

        subplot(2,3,3);
        tmp = diff(ripple_t)/options.sr;        
        [tmp,xax,yax] = hist2([tmp(tmp<1) ; ripple_amp_norm(tmp<1)]',50,100);
        imagesc(xax,yax,smoothn(tmp,10)'); axis xy;        
        xlabel('Inter-ripple interval (s)');
        ylabel('Amplitude (# SDs)');
               
        subplot(2,3,4);
        [tmp,xax,yax] = hist2([ripple_f ; ripple_dur]',50,50);
        imagesc(xax,yax,smoothn(tmp,5)'); axis xy;        
        ylabel('Duration (ms)');
        xlabel('Frequency (Hz)');
        
        
        subplot(2,3,5);
        tmp = diff(ripple_t)/options.sr;
        [tmp,xax,yax] = hist2([tmp(tmp<1) ; ripple_f(tmp<1)]',50,100);
        imagesc(xax,yax,smoothn(tmp,10)'); axis xy;
        xlabel('Inter-ripple interval (s)');
        ylabel('Frequency (Hz)');
        
        subplot(2,3,6);
        tmp = diff(ripple_t)/options.sr;
        [tmp,xax,yax] = hist2([tmp(tmp<1) ; ripple_dur(tmp<1)]',50,100);
        imagesc(xax,yax,smoothn(tmp,10)'); axis xy;
        xlabel('Inter-ripple interval (s)');
        ylabel('Duration (ms)');


        suptitle(['n = ' num2str(length(ripple_t)) ' ripples'])
        
        fixfig;

        fig; 
        subplot(2,2,1)
        hist(ripple_amp_norm,50)
        xlabel('Amplitude (# SDs)');
        ylabel('# ripples');
        subplot(2,2,2)
        hist(ripple_f,50)
        xlabel('Frequency (Hz)');
        ylabel('# ripples');
        subplot(2,2,3)
        hist(ripple_dur,50)
        xlabel('Duration (ms)');
        ylabel('# ripples');
        subplot(2,2,4)
        tmp = diff(ripple_t)/options.sr;
        hist(tmp(tmp<2),100)
        xlabel('Inter-ripple interval (s)');
        ylabel('# ripples');
        
        suptitle(['n = ' num2str(length(ripple_t)) ' ripples'])
        
        fixfig;
        
        
        fig;
        tmp = [ones(1,length(isolatedripples)) cellfun(@length,rippleseq)];
        [tmp1,tmp2]=hist(tmp,unique(tmp));
        subplot(2,1,1);
        bar(tmp2,tmp1);
        ylabel('Number of bursts')
        xlabel('Ripples in sequence')
        subplot(2,1,2);
        bar(tmp2,tmp1.*tmp2);
        ylabel('Number of ripples')
        xlabel('Ripples in sequence')       
    end
    
end

