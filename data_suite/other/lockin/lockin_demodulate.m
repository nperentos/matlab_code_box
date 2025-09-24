function dem_sig = lockin_demodulate(sig,ref_sig,sr)
%%
ref_sig1 = ref_sig; % The first reference signal is the one we use to modulate
ref_sig2 = real(hilbert(ref_sig1)* exp(-1i*pi)); % The second is same but shifted 180 degrees


%% Find modulation frequency
s = ref_sig1(1:(10*sr));
L = length(s);
Y = fft(s);
P2 = abs(Y/L);
P1 = P2(1:L/2+1);
P1(2:end-1) = 2*P1(2:end-1);
f = sr*(0:(L/2))/L;

[~,idx]=max(P1(2:end)); % starting from second frequency bin, to avoid a peak at 0 frequency
ref_f = f(idx+1);

%%

% Demodulate signal
% It is not yet clear if you need to filter it or not...
% Without filtering it also works, but I don't know if it might preserve
% some noise
sig = filter_lfp(sig,sr,[ref_f-50 ref_f+50]);

Vs = sig .* ref_sig1;
Vc = sig .* ref_sig2;

Vc = filter_lfp(Vc,sr,[0 12]);
Vs = filter_lfp(Vs,sr,[0 12]);

dem_sig = 2*real(Vs + 1i*Vs);

%%
%S = out.sig470_ref;
%Y = fft(S);
%P2 = abs(Y/length(S));
%P1 = P2(1:length(S)/2+1);
%P1(2:end-1) = 2*P1(2:end-1);
%f = 1000*(0:(length(S)/2))/length(S);
%plot(f,P1);

