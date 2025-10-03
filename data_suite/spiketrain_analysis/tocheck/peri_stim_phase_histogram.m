function psph = peri_stim_phase_histogram(spiketrain,spikephases, event, time_binsize, phase_binsize, window, plot_flag, method)

if nargin<6
    display('Please provide the necessary arguments.')
    return;
end

if nargin<7
    plot_flag = 'on';
end;

if nargin<8
    method = 'bins';
end;

start = event-window;
stop = event+window;
phase_bins = linspace(phase_binsize/2,360+phase_binsize/2,360/phase_binsize);

if strcmp(method,'bins')
    bins = linspace(start,stop, ceil(2*window/time_binsize)+1);
    ph_hist = zeros(length(phase_bins),length(bins)-1);
    for n=1:length(bins)-1
        % get the phases of the spikes that are in each bin and calculate
        % the phase histogram
        ph_hist(:,n) = hist(rad2deg(spikephases(spiketrain>bins(n) & spiketrain<=bins(n+1)),1),phase_bins)';     
    end;
    psph = ph_hist;
    if strcmp(plot_flag,'on');
       imagesc(bins,linspace(0,360,360/phase_binsize), psph)
    end;
end;
