%% mPFC tone retr
fn = 'hfh01_S1_mPFC_2_5mm_toneretr';
fn = fn_from_fn(fn);
data = load_data(fn);



%%
fn = files{7};
data = load_data(fn);

resp = getmd(data,data.channels.resp(1));
bla = getmd(data,data.channels.bla(end));
resp_ph = MakeUniformDistr(angle(hilbert(filter_lfp(resp,1000,[1 5]))));

%%
[~,idx]=spikes_in_periods(data.units.channel,[min(data.channels.bla) max(data.channels.bla)+1]);
blaunits = data.units(idx,:);
blaunits = blaunits(strcmp(blaunits.type,'good') | strcmp(blaunits.type,'ok'),:);
blaunits = blaunits(strcmp(blaunits.type,'good'),:);

logz = [];
for c=1:size(blaunits,1)
    ph = resp_ph(round(blaunits.spikes{c}/30));
    logz(c) = log((abs(mean(exp(1i*ph)))^2)*length(ph));
end
[f,x]=ecdf(logz,'function','cdf');
fig; plot(x,100*(1-f),'k')

%%
S = specmt([resp ; bla],'defaults','gamma');

fig; 
sp(3,1); 
plot_spectra(S,1);
sp; 
plot_spectra(S,2);
sp;
plot_spectra(S,[1 2],'mode','coherogram','smooth',2);
link_axes('xy')

%% 3D
fn = fn_from_fn('hfh01_S1_mPFC_3_5mm');

