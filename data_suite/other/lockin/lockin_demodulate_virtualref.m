function dem_sig = lockin_demodulate_virtualref(sig,ref_sig,time,sr)
%%
disp('lockin_demodulate_virtualref');
ref_sig1 = ref_sig; % We need to extract the reference frequency from the modulation signal

%% Find modulation frequency
s = ref_sig1(1:(10*sr));
L = length(s);
Y = fft(s);
P2 = abs(Y/L);
P1 = P2(1:L/2+1);
P1(2:end-1) = 2*P1(2:end-1);
f = sr*(0:(L/2))/L;


[~,idx]=max(P1(2:end)); % starting from second frequency bin, to avoid a peak at 0 frequency
ref_f = f(idx+1)
disp('Reference frequency extracted from Analog REf Input');

%% Create demodulation reference signals
% taken from Doric code

mytime1 = time;
N = length(time);   % Number of datapoints
tmin = mytime1(1);  % First Time value
tmax = mytime1(N);  % Time at the end of data
t = linspace(tmin, tmax, N); % Equi-distant time vector (for FFT)

ref_sin = sin(2*pi*ref_f*t); % first reference frequency
ref_cos = cos(2*pi*ref_f*t); % second reference frequency shifted by 90°

%% Demodulate signal

% Filter signal to reduce the noise
%sig = filter_lfp(sig,sr,[ref_f-20 ref_f+20]);

% Multiply the signal with the transposed reference signals
Vs = sig .* ref_sin';
Vc = sig .* ref_cos';

% Apply a LPF to only take the DC component
Vc = filter_lfp(Vc,sr,[0 12]);
Vs = filter_lfp(Vs,sr,[0 12]);

dem_sig = 2* sqrt(Vs.^2+Vc.^2); %multiplication by 2 is required to keep 1:1 scale from original signal amplitude in the mathematics of the demodulation
%dem_sig = real(Vs + 1i*Vc);%dem_sig = real(Vs + 1i*Vs);

disp('Signal demodulated...');