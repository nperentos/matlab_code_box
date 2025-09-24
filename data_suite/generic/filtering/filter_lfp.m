% Frequency band is provided as [4 8].
% For low pass : [0 10] 
% For high pass : [10 0]
% For stop pand: [55 45] (reverse order)

% Update: 31/10/2016 (NK): I added automatic casting to double (and recasting back to original class) so that I
% can generally keep int16 files in memory
% Update: 31/10/2016 (NK): I added the possibility of using stop bands
% (e.g. to filter out line noise). For that you provide the stop band, but
% with reverse order. E.g. [55 45] will filter out the frequencies 45 - 55 Hz.
% Updates : 25/07/2013 (NK) : I changed the default filter to butterworth
% (after some testing I see that it is more stable).
% I change the implementation to use the [z,p,k] format instead of the
% [b,a] format, because the [b,a] filters are unstable for higher order.
% The filtfilt is not accepting [z,p,k] filter designs, so I use the
% function filtfilthd (in helper folder).
% 
% Update : 27/11/2013 (NK) : I added the functionality of applying the
% filter to a 2d array, by transposing it so that time is in the column
% dimension and then transposing it back.

function lfp_filtered = filter_lfp(lfp, samplingfrequency, frequency_band,filtertype,options)

if nargin<5 || isempty(options); options = [6,20]; end;
if nargin<4 || isempty(filtertype); filtertype = 'butter'; end;

% This takes care that lfp is provided in the form : row x column =
% channels x time so that the transformations are applied on the time dim
transposed=0;
if ~isvector(lfp) && ismatrix(lfp); if size(lfp,2)>size(lfp,1); lfp=lfp'; transposed=1; end; end;

% Defaults
order = options(1);
ripple = options(2);
nyquist = samplingfrequency/2;

if frequency_band(2) == 0 % highpass
   highpass = frequency_band(1);
   if strcmp(filtertype,'cheby2')
   [z, p, k] = cheby2(order,ripple,highpass/nyquist,'high');
   elseif strcmp(filtertype,'butter')
       [z, p, k] = butter(order,highpass/nyquist,'high');
   end;
elseif frequency_band(1) == 0 % lowpass
   lowpass = frequency_band(2);
   if strcmp(filtertype,'cheby2')
       [z, p, k] = cheby2(order,ripple,lowpass/nyquist,'low');
   elseif strcmp(filtertype,'butter')
       [z, p, k] = butter(order,lowpass/nyquist,'low');
   end;
elseif frequency_band(2)>frequency_band(1) % bandpass
    if strcmp(filtertype,'cheby2')
       [z, p, k] = cheby2(order,ripple,frequency_band/nyquist);
    elseif strcmp(filtertype,'butter')
       [z, p, k] = butter(order,frequency_band/nyquist,'bandpass');
   end;
elseif frequency_band(1)>frequency_band(2) % bandstop
    if strcmp(filtertype,'cheby2')
       [z, p, k] = cheby2(order,ripple,frequency_band([2 1])/nyquist,'stop');
    elseif strcmp(filtertype,'butter')
       [z, p, k] = butter(order,frequency_band([2 1])/nyquist,'stop');       
   end;
end;

[sos_var,g] = zp2sos(z, p, k);
Hd = dfilt.df2sos(sos_var, g);
reset(Hd) % reset initial states

%fvtool(sos_var,'Analysis','freq')
%lfp_filtered =  filtfilt(b,a,lfp);
%lfp_filtered =  filtfilthd(Hd,lfp);
if ~isa(lfp,'double'); 
    varclass = class(lfp); 
    lfp = double(lfp); 
else; 
    varclass = []; 
end;
lfp_filtered =  filtfilt(sos_var,g,lfp); % This seems to be better (and some times different) from the filtfilthd
%lfp_filtered =  filter(Hd,lfp); % causal filter ; problematic but slightly
%faster when needed

if ~isempty(varclass); cast(lfp_filtered,varclass); end; % in theory this can introduce small errors, but in practice this effect is negligible

% Convert back to original shape for the matrix case
if transposed;
     lfp_filtered=lfp_filtered';
end;
%freqz(b,a) % Show filter response
%FIR  : [b a] = fir1(order,lowpass/nyquist,'low');