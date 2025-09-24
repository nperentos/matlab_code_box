%function [TrigSpec, f,t] = TrigSpecgram(Trig,HalfSpan, x or {FileBase, Channels}, nFFT,Fs,WinLength,nOverlap,NW,Detrend,nTapers,FreqRange);
%  Trig (time of trigger in samples, same sampling rate as x (Fs)
% HalfSpan - in samples one-sided span for specgram calculation (if a
% scalar)
% left/right span if a 2-element vector
% the rest -  same parameters as mtcsglong 
function [TrigSpec,f,t] = TrigSpecgram(Trig, HalfSpan, x, varargin);

%if isempty(Trig) & isempty(HalfSpan) & ndims(x)==3
    
if iscell(x)
    FileBase = x{1};
    Channels = x{2};
    par = LoadPar([FileBase '.xml']);
    nChannels = par.nChannels;
    nSamples = FileLength([FileBase '.lfp']);
else
    [nSamples nChannels]  = size(x);
end

if length(HalfSpan)==1
    HalfSpan=[1 1]*HalfSpan;
elseif length(HalfSpan)>2
    error('HalfSpan is 1 or 2 element vector');
end
    
MyTriggers = Trig(Trig>HalfSpan(1) & Trig<nSamples-HalfSpan(2));
nTriggers = length(MyTriggers);

for i=1:nTriggers
    if ~iscell(x)
        Segment = x(MyTriggers(i)+[-HalfSpan(1):HalfSpan(2)],:);
    
    else
        Segment= LoadSegs([FileBase '.lfp'],  MyTriggers(i)-HalfSpan(1), sum(HalfSpan)+1, nChannels, Channels, ...
                                        1000,1, 2);
    end
    [yo, f,t]=mtcsglong(Segment,varargin{:});
    if (i==1)
        TrigSpec =yo;
    else
        TrigSpec = TrigSpec + yo;
    end
end

TrigSpec = TrigSpec/nTriggers;
% now need to correct t: first offset by half window, second - shift 0 to
% be a central window
Fs =varargin{2}; WinLength = varargin{3};
t = t - t(1) - HalfSpan(1)/Fs + WinLength/2/Fs; 

if (nargout ==0)
   figure
   for i=1:nChannels
       subplotfit(i,nChannels);
       imagesc(t,f,squeeze(TrigSpec(:,:,i))');axis xy
   end
   title(num2str(i));
end
