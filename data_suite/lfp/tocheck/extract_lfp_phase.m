% The lfp must be filtered in the desired band
% If the input is matrix, it should be given in a way that the lfp is in
% the columns and trials are in rows.
% The phases are between [-pi +pi] 
function [lfp_phases lfp_power] = extract_lfp_phase(lfp)

% I have to investigate the possibility of demeaning the lfp before
% converting to analytical signal
% According to Anton Sirota's equivalent function : 
%Remove a constant offset in the filtered LFP to avoid bias
%fsamples  = fsamples - repmat(mean(fsamples), size(fsamples,1), 1);


lfp_hilb = hilbert(lfp);
lfp_phases = angle(lfp_hilb);
lfp_power = abs(lfp_hilb);



% Alternative calculation (gives exactly the same results
% Provided here only for understanding

% lfp_hilb = hilbert(lfp);
% ht=imag(lfp_hilb);
% phi=atan2(ht,lfp);

%moving window averaging to reduce noise?
%ht=moving_average(ht,5);
