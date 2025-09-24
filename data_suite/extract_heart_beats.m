function beats = extract_heart_beats(ecg0,sr,plotflag)
if nargin<2; sr = 1000; end;
if nargin<3; plotflag = 1; end;

ecg = abs(hilbert(filter_lfp(ecg0,sr,[60 0])));

tmp = window_data(ecg,sr,1);
thr = (trimean(max(tmp,[],2)) - trimean(min(tmp,[],2)))/2;

[tmp1,tmp2] = LocalMinima(-ecg,sr/20);
tmp2 = -tmp2;
beats = tmp1(tmp2>thr);
t = make_time(ecg);

if plotflag
    fig; 
    jplot(t,ecg); 
    hold on; 
    jplot(t(beats), ecg(beats),'*r');
end;