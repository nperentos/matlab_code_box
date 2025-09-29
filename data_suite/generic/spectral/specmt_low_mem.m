%% Description
%  Multitaper Time-Frequency analysis
%  Optimized for long files

%  This function returns the complex auto/crossspectrograms, coherograms + phase, imaginary coherograms + phase, Phase Locking Index and FStats for all pairs of channels

%  If x is a multicolumn matrix, each column will be treated as a time series
%  For point processes, the input should be a matrix of the format:
%  x = [Res Clu]; (times groupIDs), ie. x = nSpikes x nGroups
%  For single spiketrain, it is enought to provide the spiketrain as a  vector array

%  Original code by Partha Mitra - modified by Ken Harris and adopted for long files and phase by Anton Sirota
%  Heavily modified by Nikolas Karalis (07/2015)

%  Dependencies: inputparser

%  To Do:
%  * What about FStats? What do they show ?
%  * Phase locking index ? Need to check and uncomment
%  * Partial coherence ?
%  * Partial directed coherence?
%  * Transfer entropy
%  * Granger
%  * Wavelets

%%
function out = specmt(x,varargin)

%% Arguments
options = {'defaults',[],'window',1,'overlap',90,'pad',1,'nw',3, 'whiten', 0,...
    'freqrange',[],'pointprocess',0,'sr',1000,'spikeSR', 1000, 'tapers',[], ...
    'minspikes',[],'detrend','linear','blocksize',2^16};
options = inputparser(varargin,options);

if strcmp(options.defaults,'theta')
    options.whiten = 0;
    options.pad=1;
    options.nw = 1.5;
    options.freqrange = [0.1 20];
    options.window = 1.5;
    options.overlap = 80;

elseif strcmp(options.defaults,'4Hz')
    options.whiten = 0;
    options.pad=1;
    options.nw = 1.5;
    options.freqrange = [0.1 20];
    options.window = 3;
    options.overlap = 80;    
    
elseif strcmp(options.defaults,'gamma')
    options.whiten = 1;
    options.pad=2;
    options.nw = 2.5;
    options.freqrange = [10 200];
    options.window = 0.1;
    options.overlap = 80;

elseif strcmp(options.defaults,'gammaNP')
    options.whiten = 1;%1
    options.pad=2;
    options.nw = 1;
    options.freqrange = [10 200];
    options.window = 1;%0.3
    options.overlap = 80;    
    
elseif strcmp(options.defaults,'ripples')
    options.whiten = 1;
    options.pad=2;
    options.nw = 2.5;
    options.freqrange = [20 400];
    options.window = 0.1;
    options.overlap = 80;

elseif strcmp(options.defaults,'universal')    
    options.whiten = 1;
    options.pad=1;
    options.nw = 1.5;
    options.freqrange = [0.1 250];
    options.window = 2.5;
    options.overlap = 80;    
    
elseif strcmp(options.defaults,'universal')    
    options.whiten = 1;
    options.pad=1;
    options.nw = 1.5;
    options.freqrange = [0.1 250];
    options.window = 2.5;
    options.overlap = 80;  
end

out.options = options;

%% Prepare

% Make sure the array has the correct size
if size(x,1)<size(x,2); x = x'; end;

% Simplify for case of single spiketrain
if options.pointprocess && isvector(x); x = [x ones(length(x),1)]; end;

if options.whiten && ~options.pointprocess
    whitenorder = 2;
    whitenwindow = 20 * options.sr; % 20sec window
    if whitenwindow>size(x,1); whitenwindow = size(x,1); end; % In case signal is less than 20 sec
    
    for c=1:size(x,2);
        [A ,nv] = arburg(double(x(1:whitenwindow,c)),whitenorder);
        x(:,c) = filter(A,1,double(x(:,c)));
        options.NoiseVariance(c) = nv;
        options.WhitenModel(c,:) = A;
    end
end

if options.pointprocess
    options.sr = options.spikeSR;
    Res = x(:,1);
    Clu = x(:,2);
    CluInd = unique(Clu);
    nChannels = length(CluInd);
    nSamples = max(Res)+1;
    if isempty(options.minspikes);
        MinSpikes = 2*options.tapers; % theoretical
    end;
else
    nChannels = size(x, 2);
    nSamples = size(x,1);
end

% Default values for frequencies and tapers
if isempty(options.freqrange); options.freqrange = [0 options.sr/2]; end;
if isempty(options.tapers); options.tapers = 2*options.nw - 1; end;

nFFT = 2^(nextpow2(options.window*options.sr)+options.pad);
windowsize_samples = options.window*options.sr;
overlap_samples = ceil(windowsize_samples*(options.overlap/100));


% calculate Slepian sequences.  Tapers is a matrix of size [windowsize_samples, options.tapers]
Tapers =dpss(windowsize_samples,options.nw,options.tapers, 'calc');
TaperingArray = repmat(Tapers, [1 1 nChannels]);

if options.pointprocess;
    Tapers = Tapers*sqrt(options.sr);
    H = fft(Tapers,nFFT); %  Calculate the Slepian transforms - use in bias calculation for point process
end




if length(overlap_samples)==1
    winstep = windowsize_samples - overlap_samples;
    % calculate number of FFTChunks per channel
    %remChunk = rem(nSamples-Window)
    nFFTChunks = max(1,round(((nSamples-windowsize_samples)/winstep))); %+1  - is it ? but then get some error in the chunking in mtcsd... let's figure it later
    out.t = winstep*(0:(nFFTChunks-1))'/options.sr;
else
    winstep = 0;
    overlap_samples = overlap_samples(overlap_samples>windowsize_samples/2 & overlap_samples<nSamples-windowsize_samples/2);
    nFFTChunks = length(overlap_samples);
    out.t = overlap_samples(:)/options.sr;
end

% Move the t by half the windowsize to be centered
out.t = out.t+options.window/2;

if isreal(x)
    if rem(nFFT,2),    % nfft odd
        freqselect = [1:(nFFT+1)/2];
    else
        freqselect = [1:nFFT/2+1];
    end
    nFreqBins = length(freqselect);
else
    freqselect = 1:nFFT;
end

out.f = (freqselect - 1)'*options.sr/nFFT;
nfreqranges = size(options.freqrange,1);

if nfreqranges==1
    freqselect = find(out.f>options.freqrange(1) & out.f<options.freqrange(end));
    out.f = out.f(freqselect);
    nFreqBins = length(freqselect);
else
    freqselect=[];
    for c=1:nfreqranges
        freqselect=cat(1,freqselect,find(out.f>options.freqrange(c,1) & out.f<options.freqrange(c,2)));
    end
    out.f = out.f(freqselect);
    nFreqBins = length(freqselect);
end


nFFTChunksall= nFFTChunks;

nBlocks = ceil(nFFTChunksall/options.blocksize);


% Allocate memory
Sxy=complex(zeros(nFFTChunks,nFreqBins, nChannels));%, nChannels)); % output array memory allocation % original that takes way too much memory
%out.pli=complex(zeros(nFFTChunks,nFreqBins, nChannels, nChannels)); % phase array memory allocation

%% Main code
for Block=1:nBlocks
    
    minChunk = 1+(Block-1)*options.blocksize;
    maxChunk = min(Block*options.blocksize,nFFTChunksall);
    nFFTChunks = maxChunk - minChunk+1;
    iChunks = [minChunk:maxChunk];
    Periodogram = complex(zeros(nFreqBins, options.tapers, nChannels, nFFTChunks)); % intermediate FFTs
    Temp1 = complex(zeros(nFreqBins, options.tapers, nFFTChunks));
    Temp2 = complex(zeros(nFreqBins, options.tapers, nFFTChunks));
    Temp3 = complex(zeros(nFreqBins, options.tapers, nFFTChunks));
    eJ = complex(zeros(nFreqBins, nFFTChunks));
    tmpy =complex(zeros(nFreqBins,nFFTChunks, nChannels));%, nChannels));
    %tmppli=complex(zeros(nFreqBins,nFFTChunks, nChannels, nChannels));
    
    % New super duper vectorized alogirthm compute tapered periodogram with FFT
    % This involves lots of wrangling with multidimensional arrays.
    
    if options.pointprocess
        for j=1:nFFTChunks
            jcur = iChunks(j);
            Segment = (jcur-1)*winstep+[1 windowsize_samples];
            SegmentId = find(Res>=Segment(1) & Res<=Segment(2));
            if ~isempty(SegmentId)
                SegmentRes = Res(SegmentId);
                SegmentClu = Clu(SegmentId);
                SegmentRes = SegmentRes - SegmentRes(1) + 1;
                
                %fftOut = PointFFT(Tapers,SegmentRes, SegmentClu, nClu, CluInd, nFFT, options.sr,MinSpikes);
                
                % Replace here with PointFFT code
                for c = 1:nChannels
                    thisclu = find(SegmentClu==CluInd(c));
                    if length(thisclu)<options.minspikes
                        fftOut(:,:,c) = zeros(nFFT, size(Tapers,2));
                    else
                        thisres  = SegmentRes(thisclu);
                        dN = Accumulate(thisres, 1, size(Tapers,1));
                        dN = repmat( dN(:), [ 1 size(Tapers,2)]);
                        fftOut(:,:,c) = fft(dN .* Tapers, nFFT) - repmat(mean(dN),nFFT,1) .* H;
                    end
                end
                
                Periodogram(:,:,:,j) = fftOut(freqselect, : , :);
            else
                Periodogram(:,:,:,j) = zeros(nFreqBins,size(Tapers,2), nChannels);
            end
        end
    else
        for j=1:nFFTChunks
            jcur = iChunks(j);
            
            if length(overlap_samples)==1
                Seg = [(jcur-1)*winstep+1: min((jcur-1)*winstep+windowsize_samples,nSamples)];
                Segment = x(Seg,:);
            else
                Seg = [overlap_samples(jcur)-windowsize_samples/2+1: min(overlap_samples(jcur)+windowsize_samples/2,nSamples)];
                Segment = x(Seg,:);
            end
            
            if (~isempty(options.detrend)); Segment = detrend(single(Segment), options.detrend); end;
            
            SegmentsArray = permute(repmat(Segment, [1 1 options.tapers]), [1 3 2]);
            TaperedSegments = TaperingArray .* SegmentsArray;
            
            fftOut = fft(TaperedSegments,nFFT);
            normfac = sqrt(2/nFFT); %to get back rms of original units
            Periodogram(:,:,:,j) = fftOut(freqselect,:,:)*normfac; %fft(TaperedSegments,nFFT);
            % Periodogram: size  = nFreqBins, options.tapers, nChannels, nFFTChunks
        end
    end
    
    %% Calculate Fstatistics
    U0 = repmat(sum(Tapers(:,1:2:end)),[nFreqBins,1,nChannels,   nFFTChunks]);
    Mu = squeeze(sum(Periodogram(:,1:2:end,:,:) .* conj(U0), 2) ./  sum(abs(U0).^2, 2));
    Num = abs(Mu).^2;
    Sp = squeeze(sum(abs(Periodogram).^2,2));
    chunkFS = (options.tapers-1) * Num ./ (Sp ./ squeeze(sum(abs(U0).^2, 2)) - Num );
    out.FStats(iChunks, :, :)  = permute(reshape(chunkFS, [nFreqBins, nChannels, nFFTChunks]),[ 3 1, 2]);
    
    %% prepare for output NP avoiding cross spectra due to RAM limitations 
    for Ch1 = 1:nChannels % don't compute cross-spectra twice
        Temp1 = reshape(Periodogram(:,:,Ch1,:), [nFreqBins,options.tapers,nFFTChunks]);
        eJ=sum(Temp1, 2);
        tmpy(:,:, Ch1)= eJ/options.tapers;
        Sxx(iChunks,:,Ch1) = permute(tmpy(:,:,Ch1), [2 1 3]);
    end

    
%     %% Now make cross-products of them to fill cross-spectrum matrix
%     for Ch1 = 1:nChannels
%         for Ch2 = Ch1:nChannels % don't compute cross-spectra twice
%             Temp1 = reshape(Periodogram(:,:,Ch1,:), [nFreqBins,options.tapers,nFFTChunks]);
%             Temp2 = reshape(Periodogram(:,:,Ch2,:), [nFreqBins,options.tapers,nFFTChunks]);
%             Temp2 = conj(Temp2);
%             Temp3 = Temp1 .* Temp2;
%             eJ=sum(Temp3, 2);
%             tmpy(:,:, Ch1, Ch2)= eJ/options.tapers;
% 
%             % for off-diagonal elements copy into bottom half of matrix
%             if (Ch1 ~= Ch2)
%                 tmpy(:,:, Ch2, Ch1) = conj(eJ) / options.tapers;
%             end
% 
%             %tmppli(:,:,Ch1,Ch2) = sum(exp(-i*angle(Temp1)-i*angle(Temp2)),2);
%         end
%     end
% 
%     for Ch1 = 1:nChannels
%         for Ch2 = 1:nChannels
%             Sxy(iChunks,:,Ch1, Ch2) = permute(tmpy(:,:,Ch1, Ch2), [2 1 3 4]);
%             %out.pli(iChunks,:,Ch1, Ch2) = permute(tmppli(:,:,Ch1, Ch2), [2 1 3 4]);
%         end
%     end
% 
% end
% 
% 
% out.Sxy = Sxy;
out.Sxx = Sxx;
