% Update: 14/10/2017: Changed the way motion is calculated from mov (to
% remove DC and reduce base fluctuations).

function states = state_detection(filebase,channels,recalc)

%% Input parsing
filebase = directory_sanitizer(filebase);

if nargin<2 | isempty(channels)
    
    ChannelMaps % Load channel maps
    fn = get_lfp_filename(filebase);
    [~, session]=fileparts(fn);
    session
    disp('Channels loaded from ChannelMaps')
    if isfield(channelmaps,session)
        channels = channelmaps.(session);
    else
        disp(filebase);
        states = [];
        error('Please provide the list of channels.')
        return;
    end
end

if nargin<3
    recalc = 0;
end

%% Files
fn = get_lfp_filename(filebase);
infofn = get_lfp_filename(filebase,'info');
statesfn = get_lfp_filename(filebase,'states');
xmlfn = get_lfp_filename(filebase,'xml');

if ~exist(fn);
    states = [];
    disp('No file found');
    disp(fn);
    return;
end;

if ~exist(infofn) | recalc
    % Create info file
    % Only happens when there is no info file and channels are provided
    
    settings = xml2struct(xmlfn);
    info.datsr = str2num(settings.parameters.acquisitionSystem.samplingRate.Text);
    info.sr = str2num(settings.parameters.fieldPotentials.lfpSamplingRate.Text);
    
    info.fn = filebase;
    
    if ~isempty(channels);
        info.channels = struct();
        for c = 1:2:length(channels);
            info.channels.(channels{c}) = channels{c+1};
        end
    end
    
    try;
        settings = xml2struct(get_lfp_filename(filebase,'oe.xml'));
        info.date = settings.SETTINGS.INFO.DATE.Text;
    catch;
        disp('No .oe.xml found');
    end
    
    % Find TTLs
    if isfield(info.channels, 'ttl')
        
        m = memmap_datfile(info.fn,'lfp');
        ttl = m.Data.m(info.channels.ttl,:);
        [beg, fin] = find_ttl_periods(ttl, 0.1, info.sr, 20);
        info.ttl_start = beg;
        info.ttl_stop = fin;
    end
    
    save(infofn,'info')
end

%% Filenames
if exist(statesfn) & ~recalc;
    disp('States exist. Nothing to be done');
    disp('If you want to recalculate, provide the recalc flag.');
    tmp = load(statesfn,'-mat');
    states = tmp.states;
    return
else
    data = load_data(filebase);
    
    if isempty(data);
        disp('File not found. Skipping...');
        return;
    end
    
    sr = data.info.sr;
    try; data = rmfield(data,'states'); catch; end;
    recalc = 1;
end

%% Create mov
[mov,movtype] = load_mov(data);
if ~isempty(movtype);
    data.info.movtype = movtype;
end;
if ~isfield(data.info,'movtype'); data.info.movtype = movtype; end;
disp('Movement loaded');

%% Create empty fields, in case there is no calculation performed below
data.states = struct();
data.states.spec = struct();

%% Check if spectrograms exist otherwise calculate
if ~isfield(data.channels,'states') | ~isfield(data.states,'specs')
    
    pyrch = [];
    posib = {'pyr','dCA1','dca1','CA1','vCA1','vca1','hpc','dhpc','vhpc'};
    for c=posib
        if isfield(data.channels, c)
            pyrch = data.channels.(c{1})(1);
            pyrtmp = getmd(data,pyrch); % Only for the first channel
            pyrtmp = decimate(pyrtmp,4);
            data.states.spec.pyr = specmt(pyrtmp,'defaults','universal','sr',sr/4); % Only for the first channel
        end
    end
       
    if isfield(data.channels, 'mpfc')
        cortextmp = getmd(data,data.channels.mpfc(1));
    elseif isfield(data.channels, 'cortex')
        cortextmp  = getmd(data,data.channels.cortex(1));
    elseif isfield(data.channels, 'eeg')
        cortextmp  = getmd(data,data.channels.eeg(1));
    elseif isfield(data.channels, 'pyr') | isfield(data.channels, 'dCA1')
        cortextmp  = pyrtmp;
    else
        cortextmp  = [];
    end
    
    if ~isempty(cortextmp);
        cortextmp = decimate(cortextmp,4);
        data.states.spec.cortex = specmt(cortextmp ,'defaults','universal','sr',sr/4);
    end
    
    disp('Spectra calculated');
end

%% Find theta & movement periods
if ~isempty(mov) & recalc
    
    %motion = smooth_gauss(single(mov),2 * sr, 0.1 * sr);
    motion = smooth_gauss(single(abs(hilbert(filter_lfp(mov,sr,[0.1 0])))),2 * sr, 0.1 * sr);
    
    motion = motion(:)';
    mt = make_time(motion,0,sr);
    
    figure;
    subplot(2,2,3);
    jplot(mt,motion);
    ypos = median(motion);
    tmp2 = imline(gca,get(gca,'xlim'),[ypos ypos]);
    setPositionConstraintFcn(tmp2,@(pos) [pos(:,1) repmat(mean(pos(:,2)),2,1)]);
    setColor(tmp2,'r')
    title('Movement');
    %%
    if isfield(data.states.spec, 'pyr')
        st = data.states.spec.pyr.t;
        data.states.ratio_pyr_t = st;
        f = data.states.spec.pyr.f;
        specsr = round((1 / mean(diff(st))));
        
        slowPyr = smooth_gauss(sum(data.states.spec.pyr.Sxy(:,f>15),2),5 *  specsr,2 * specsr);
        thetaPyr = smooth_gauss(sum(data.states.spec.pyr.Sxy(:,f>6 & f<=10),2),5 *  specsr,2*specsr);
        
        data.states.ratio_pyr = thetaPyr./slowPyr;
        
        subplot(2,2,1);
        jplot(st,data.states.ratio_pyr);
        ypos = median(data.states.ratio_pyr);
        tmp1 = imline(gca,get(gca,'xlim'),[ypos ypos]);
        setPositionConstraintFcn(tmp1,@(pos) [pos(:,1) repmat(mean(pos(:,2)),2,1)]);
        setColor(tmp1,'r')
        title('CA1 Pyr  \theta / \delta ratio');
        
        subplot(2,2,2);
        plot_spectra(data.states.spec.pyr,1,'freqrange',[0 20]); colorbar off;
        title('CA1 spec');
    end
    
    if isfield(data.states.spec,'cortex')
        subplot(2,2,4);
        plot_spectra(data.states.spec.cortex,1,'freqrange',[0 20]); colorbar off;
        title('Cortex spec');
    end
    
    link_axes;
    fixfig;
    
    input('Are you ready to proceed? ');
    if isfield(data.states.spec, 'pyr')
        thr = tmp1.getPosition;
        thr = thr(1,2);
        data.states.theta_thr = thr;
    end
    
    thr = tmp2.getPosition;
    thr = thr(1,2);
    data.states.mov_thr = thr;
    
    %%
    % Find movements, including twiches, that are at least 0.2 s duration and merge the ones that are less than 2 sec apart.
    % Essentially, this find even the tiniest movements.
    movement_periods = find_periods(motion>data.states.mov_thr, 0.2 * sr, 2 * sr) / sr; % get it in seconds
    
    % Keep only longer (>5 sec) periods of mobility
    % The rest is probably twiches.
    idx = diff(movement_periods,[],2)>5;
    
    data.states.active = movement_periods(idx,:);
    
    % Now take the rest as immobility periods (which includes occasional twiches).
    data.states.immobility = find_no_freeze_periods(data.states.active,max(mt));
    
    % Get small movements
    idx = diff(movement_periods,[],2)<=5;
    data.states.micromotions = movement_periods(idx,:);
    
    % Sleep periods are defined as > 20 sec periods without micromotions
    tmp = period_nooverlap(data.states.immobility,data.states.micromotions);
    sleep_thr = 20; % sec of complete immobility
    data.states.sleep = tmp(diff(tmp,[],2)>sleep_thr,:);
    
    % Merge sleep periods that are <10 sec apart (i.e. interrupted by
    % occasional micromotions, but are not long periods with
    % micromotions)
    if ~isempty(data.states.sleep)
        sleep_merge = find((data.states.sleep(2:end,1) - data.states.sleep(1:end-1,2)) < 10);
        sleep1 = data.states.sleep;
        for c=1:length(sleep_merge);
            sleep1(sleep_merge(c),2) = sleep1(sleep_merge(c)+1,2);
            sleep1(sleep_merge(c)+1,:) = [];
            sleep_merge = sleep_merge-1;
        end
        data.states.sleep = sleep1;
    end
    
    % Quiet awakening periods are all the other periods that contain
    % micromotions but are not the <5 sec periods with micromotions that
    % are between long sleep episodes
    data.states.quiet = period_nooverlap(data.states.immobility,data.states.sleep);
    
    if isfield(data.states,'ratio_pyr');
        data.states.theta = find_periods(data.states.ratio_pyr>data.states.theta_thr, 5 * specsr, 5 * specsr)/specsr; % get it in seconds
    else
        data.states.theta = [];
    end
    data.states.rem = period_overlap([data.states.sleep ; data.states.quiet], data.states.theta);
    
    % Merge REM periods that are <10 sec apart (i.e. interrupted by
    % occasional micromotions, but are not long periods with
    % micromotions)
    if ~isempty(data.states.rem);
        rem_merge = find((data.states.rem(2:end,1) - data.states.rem(1:end-1,2))<10);
        rem1 = data.states.rem;
        for c=1:length(rem_merge);
            rem1(rem_merge(c),2) = rem1(rem_merge(c)+1,2);
            rem1(rem_merge(c)+1,:) = [];
            rem_merge = rem_merge-1;
        end
        data.states.rem = rem1;
        data.states.rem(diff(data.states.rem,[],2)<20,:) = [];
        data.states.sws = period_nooverlap(data.states.sleep, data.states.theta);
    end
end

%% Sleep depth ranking
fields = {'rem','sws','theta','quiet','sleep','active','immobility'};
for c=1:length(fields);
    if ~isfield(data.states,fields{c}); data.states.(fields{c}) = []; end;
end

if isfield(data.states.spec,'cortex')
    [~,idx] = spikes_in_periods(data.states.spec.cortex.t, data.states.sws,1);
else
    idx = [];
end

if ~isempty(idx);
    if isfield(data.states.spec, 'cortex');
        tmp = cellfun(@(x) mean(mean(data.states.spec.cortex.Sxy(x,data.states.spec.cortex.f<5),2)), idx);
        [data.states.swsrank.mag, data.states.swsrank.order]=sort(tmp);    
    else
        data.states.swsrank.mag = [];
        data.states.swsrank.order = [];
    end
else
    data.states.swsrank.mag = [];
    data.states.swsrank.order = [];
end

%% Find ripples
if isfield(data.channels,'pyr') & recalc
    if isfield(data.channels,'rippleref')
        ref = getmd(data,data.channels.rippleref);       
    elseif isfield(data.channels, 'cortex')
        ref  = getmd(data,data.channels.cortex(1));
    elseif isfield(data.channels, 'eeg')
        ref  = getmd(data,data.channels.eeg(1));        
    elseif isfield(data.channels, 'mpfc')
        ref = getmd(data,data.channels.mpfc(1));
    elseif isfield(data.channels, 'mPFC')
        ref = getmd(data,data.channels.mpfc(1));
    else
        ref=[];
    end
    if ~isempty(ref);
        data.states.swr = find_ripples(pyrtmp,'thr',2.5,'plot',0,'periods',[data.states.quiet ; data.states.sleep],'refsig',ref); % Remove ripples inside theta periods
    else
        data.states.swr = find_ripples(pyrtmp,'thr',2.5,'plot',0,'periods',[data.states.quiet ; data.states.sleep]); % Remove ripples inside theta periods
    end
    clear ref
end

%% Find delta waves
% if (isfield(data.channels, 'mpfc') | isfield(data.channels, 'cortex') | isfield(data.channels, 'eeg')) & recalc
%     delta = filter_lfp(cortextmp ,data.info.sr,[0 3]);
% elseif isfield(data.channels, 'pyr') | isfield(data.channels, 'dCA1') & recalc
%     delta = filter_lfp(pyrtmp ,data.info.sr,[0 3]);
% else
%     delta = [];
% end
% 
% if ~isempty(delta);
%     [mmax, mmin]=minimamaxima(delta);
%     [~,idx] = spikes_in_periods(mmax(:,1),data.states.sws*data.info.sr);
%     
%     data.states.dwaves.t = mmax(idx,1);
%     data.states.dwaves.amp = mmax(idx,2);
%     
%     for c=1:length(data.states.dwaves.t);
%         t = data.states.dwaves.t(c);
%         t1 = mmin(find((mmin(:,1) - t)<0,1,'last'));
%         if ~isempty(t1);
%             data.states.dwaves.onset(c,1) = t1;
%         else
%             data.states.dwaves.onset(c,1) = NaN;
%         end
%     end;
% end

cortexmuafn = get_lfp_filename(data.info.fn,'cmua');

if exist(cortexmuafn)
    data.states.dwaves = dwaves;
else
    data.states.dwaves = [];
end

%% Find spindles

%% Find UP states

%% Plot

figure;

sp;
if exist('motion');
    jplot(make_time(motion,0,sr),motion,'k');
    plot_events(data.states.sleep,'r',5,'all');
    plot_events(data.states.quiet,'y',5,'all');
    plot_events(data.states.active,'b',5,'all');
    manual_legend({'r','y','b'},{'Sleep','Quiet','Active'});
end

if isfield(data.states,'ratio_pyr')
    sp;
    jplot(data.states.ratio_pyr_t,data.states.ratio_pyr,'k');
    plot_events(data.states.rem,'g',5,'all');
    manual_legend({'g'},{'REM'});
    xlabel('Time (s)');

    link_axes;
end

[tmp,session] = get_lfp_filename(filebase,'');
session = session{1};
plotdir = directory_sanitizer([filebase 'plots'],1);
plotfn = [plotdir session '_states'];

%% Save files
data.info.states_calculation_date = datetime;
info = data.info;
save(infofn,'info')

states = rmfield(data.states,'spec');
save(statesfn,'states','-v7.3')

fixfig(plotfn);
