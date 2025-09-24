function props = spike_properties(spikes,waveform, autocorrflag)

if nargin<3; autocorrflag = 0; end; % faster

%% Parameters
upfactor = 10;
sr = 30000;
bitVolt = 0.195/1000;

%% Input parsing
if ~isvector(waveform); 
    error('Please provide a single waveform');    
end;
waveform = double(waveform(:)); % Make sure it is column and double
spikes = double(spikes(:));
%%
m = trimean(waveform(:));
[minw,minidx] = min(waveform);
[maxw,maxidx] = max(waveform);
if (maxw-m)>(m-minw); wfsign = 1; else; wfsign=-1; end;
props.sign = wfsign;
%if wfsign==1; waveform = -waveform; end;


%% Upsample waveform
waveform = interp1(1:61,waveform,linspace(1,61,61*upfactor),'spline');

%% Basic calculations
[minv,minidx]= min(waveform);
[m_pre,m_pre_idx] = max(waveform(1:minidx));
[m_post,m_post_idx] = max(waveform(minidx:end));

%% Amplitude
props.amp = minv*bitVolt;
props.rel_amp = (m - minv)*bitVolt;

%% Spike width (half-amplitude)
thr = m - (m - minv)/2;
[~,idx1]=min(abs(waveform(1:minidx) - thr));

[~,idx2]=min(abs(waveform(minidx:end) - thr));
idx2 = minidx + idx2;

props.halfwidth = (idx2 - idx1)/sr/upfactor*1000;
%props.halfwidth = (idx2 - idx1)/sr*1000;

%% Trough-to-peak
props.t2p = m_post_idx/sr/upfactor * 1000;
%props.t2p = m_post_idx/sr * 1000;

%% Asymmetry
m_post = m_post - m;
m_pre = m_pre - m;
props.asymmetry = (m_post - m_pre)/(m_pre + m_post);

%% Frequency
tmp = diff(spikes)/sr;
tmp = tmp(tmp<20); % exclude large intervals
props.freq = 1/trimean(tmp);
%props.freq = length(spikes)/((max(spikes)-min(spikes))/sr);

%% Mean of autocorr
if autocorrflag;
    T = spikes(:);
    G = ones(length(T),1);
    props.autocorr = CCG(T,G,0.001*sr,0.5/0.001,sr,1,'count');
    [~,idx]=max(props.autocorr);
    props.refr = abs(501 - idx);
    props.burstiness = max(props.autocorr(503:506))./max(props.autocorr(507:550)); % if >0.5, is bursty
    props.isimode = mode(1000*diff(spikes)/sr); % >35ms : regular spiking
    props.isispikes = sum(props.autocorr(500:502));
end;

