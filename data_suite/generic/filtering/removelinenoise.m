function varargout = removelinenoise(sig,varargin)
% Input parsing
options = {'method','ica','window',5,'targetfreq',50,'freqband',4,'SR',1000,'plot',1,'defaults',1,'pcaeig',[],'manual',1}; % freqband: [46 62] for SNR calculation, pcaeig defines the reduced dimensions for ICA
options = inputparser(varargin,options);
if strcmp(options,'error'); return; end;

if options.defaults && strcmp(options.method,'fit');
    options.window = 60;
    options.freqband = 2;
end;

if options.defaults && strcmp(options.method,'icachunk');
    options.window = 20;
    options.freqband = 4;
    
end;

if options.defaults && strcmp(options.method,'ica');
    options.freqband = 4;
    if isempty(options.pcaeig); options.pcaeig = max(size(sig,1),10); end; % Keeping max 10 components. We don't want too many, because then the noise is going to be distributed. If you have to few, then they are going to capture more than the noise.
end;

sig = double(sig);
if size(sig,1)>size(sig,2); sig = sig'; end; % Make sure it is nChannels x nSamples
sig_clean = zeros(size(sig));



if strcmp(options.method,'icachunk');
    options.window = options.window*options.SR;
    
    nIC = size(sig,1);
    if isempty(options.pcaeig); options.pcaeig = size(sig,1); end;
    
    segs = (1:options.window:size(sig,2))';      
    segs=[segs(1:end-1)  , segs(2:end)-1];    
    segs = cat(1,segs,[segs(end,2)+1 size(sig,2)]);    
    if segs(end,1)==segs(end,2); segs(end,:)=[]; end;    
    
    nChunks = size(segs,1);
    
    IC_snrs = zeros(nIC, nChunks);
    noiseIC = zeros(nChunks,1);
    
    progressbar
    for c=1:nChunks
        [icasig, A, ~] = fastica(sig(:,segs(c,1):segs(c,2)), 'lastEig',options.pcaeig, 'numOfIC',nIC,'displayMode','off','stabilization','on','g','pow3','approach','defl','verbose','off');
        out = specmt(icasig,'window',2,'overlap',60,'pad',1,'nw',1.5,'freqrange',[10 200]);
        line_freqs = (abs(out.f-options.targetfreq)<options.freqband);
        out = MatDiag(squeeze(mean(abs(out.Sxy),1)));
        [s,idx]=sort(mean(out(line_freqs,:))./mean(out(~line_freqs,:)),'descend');
        
        %noiseIC = idx(s>2*std(s));
        
        noiseIC(c) = idx(1);
        IC_snrs(:,c) = s;
        goodIC =setdiff(1:size(icasig,1),noiseIC(c));
        sig_clean(:,segs(c,1):segs(c,2)) = A(:,goodIC)*icasig(goodIC,:);
        progressbar(c/nChunks);
    end
    
    varargout{1} = sig_clean; varargout{2} = IC_snrs; varargout{3} = noiseIC;
        
elseif strcmp(options.method,'fit')
    %progressbar
    figure;
    for c=1:size(sig,1);        
        sig_clean(c,:) = chunkwiseDeline(sig(c,:)',options.SR,[options.targetfreq options.targetfreq*3 options.targetfreq*5],1./options.freqband,options.window,options.plot);
        %progressbar(c/size(sig,1))
    end;
    
    varargout{1} = sig_clean;

elseif strcmp(options.method, 'ica')
        figure; plot_lfp(sig); title('Bad channel selection');
        badChannels = input('Are there any bad channels to be ignored? (e.g. input in the form: [3,5] or []) : ');
        goodChannels = setdiff(1:size(sig,1),badChannels);
        close
        
        nIC = size(sig,1);
        if isempty(options.pcaeig); options.pcaeig = length(goodChannels); end;
        [icasig, A, ~] = fastica(sig(goodChannels,:), 'lastEig',options.pcaeig, 'numOfIC',nIC,'displayMode','off','stabilization','on','g','pow3','approach','defl','verbose','off');
        
        
        if options.manual;         
            % Plot and ask for advice
            figure; imagesc(1:size(A,2),goodChannels,abs(A)); colorbar; box off; set(gca,'TickDir','out');
            ylabel('Channels'); xlabel('IC #'); title('Mixing Matrix (abs)');
            %figure; jplot(out.f,out1); legend(arrayfun(@(x)num2str(x), idx,'un',0));
            figure; subplot(2,1,1); plot_lfp(icasig); subplot(2,1,2); plot_lfp(sig); link_axes;
            title('IC selection');
            noiseIC = input('Which ICs should be removed? (e.g. input in the form: [3,5]) : ');
            out1 = [];
        else
            out = specmt(icasig,'window',2,'overlap',50,'pad',1,'nw',1.5,'freqrange',[20 90]);
            line_freqs = (abs(out.f-options.targetfreq)<options.freqband);
            out1 = MatDiag(squeeze(mean(abs(out.Sxy),1)));
            [s,idx]=sort(mean(out1(line_freqs,:))./mean(out1(~line_freqs,:)),'descend');
            noiseIC = idx(1);            
        end
        
        goodIC =setdiff(1:size(icasig,1),noiseIC);
        sig_clean(goodChannels,:) = A(:,goodIC)*icasig(goodIC,:);
        sig_clean(badChannels,:) = sig(badChannels,:);
        
        varargout{1} = sig_clean; varargout{2} = icasig(noiseIC,:); varargout{3} = out1;
        
elseif strcmp(options.method, 'fft')
    
elseif strcmp(options.method, 'templatefilter')

end