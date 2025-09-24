function [ThPh, ThAmp,Cycles]=theta_phase_extraction(signal, SR, max_theta_freq,method)
if nargin<4; method = 'hilbert'; end;
if nargin<3 || isempty(max_theta_freq); max_theta_freq = 15; end;

% max and min don't work nicely
switch method
    case 'max'
        signal_f = filter_lfp(signal,SR,[1 20]);
        nT = length(signal_f);
        ThPk = LocalMinima(-signal_f,1/max_theta_freq*SR,0);
        ThPk = [1; ThPk; nT];
        ThPh = PhaseFromCycles([1:nT]', ThPk(1:end-1), ThPk(2:end));
        ThAmp = interp1(ThPk, abs(signal_f(ThPk)), [1:nT]','cubic');
        ThPh(1)=ThPh(2);
        
    case 'min'
        signal_f = filter_lfp(signal,SR,[1 20]);
        nT = length(signal_f);
        ThTr = LocalMinima(signal_f,1/max_theta_freq*SR,0);
        ThTr = [1; ThTr; nT];
        ThPh = PhaseFromCycles([1:nT]', ThTr(1:end-1), ThTr(2:end));
        ThAmp = interp1(ThTr, abs(signal_f(ThTr)), [1:nT]','cubic');
        
    case 'hilbert'
        signal_f = filter_lfp(signal,SR,[4 max_theta_freq]);
        hilb = hilbert(signal_f);
        ThPh = angle(hilb);
        ThAmp = abs(hilb);
        Tr = LocalMinima(ThPh,1/max_theta_freq*SR,-3);
        Cycle_start = Tr(1:end-1);
        Cycle_end = Tr(2:end)-1;                
        Cycles = [Cycle_start(:) Cycle_end(:)];
end