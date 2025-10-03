% Extract spike times and waveforms 
%
% Date : 22/05/2013
% Author : Nikolas
%
% Dependencies : inputparser,nonlinear_energy_operator, filter_lfp
%
% Updates : 

function [spiketimes,waveforms] = extract_spikes(signal, samplingrate, varargin)

% Input parsing
options = {'mode','neo','interactive',0,'thres_mult',4,'alignment','peak','filter',1,'waveformlength',1.6,'plot',0,'maxlim',20,'manualthr',0,'upsampleratio',1};
options = inputparser(varargin,options);
if strcmp(options,'error'); return; end;

if options.upsampleratio>1
    signal = spline(linspace(1,length(signal),length(signal)),signal,linspace(1,length(signal),length(signal)*options.upsampleratio));
    samplingrate=options.upsampleratio*samplingrate;
end

%% Filtering
% If option is set, the signal is bandpass filterted between 500 and 8000 Hz.
if options.filter
    signal = filter_lfp(signal, samplingrate, [500 8000]);
end;
signal = signal(:)';   

%% Detection
if strcmp(options.mode,'neg')
    noise_std = median(abs(signal)/0.6745);
    % If interactive mode is set, the signal is plotted and the user is
    % asked to provide the desired threshold.
    % Otherwise the default value is set.
    if options.interactive
        disp(['Noise standard deviation : ', num2str(noise_std)]);
        response = input('Please provide the threshold to be used : ','s');
        if ~strcmp(response,'0'); thr= str2num(response); else; thr = options.thres_mult * noise_std; end;
    else
        thr = options.thres_mult * noise_std;
    end;
    disp(['Threshold used : ' num2str(thr)])
    detections = find(signal < -thr);
    % find all moments when the threshold is crossed
    crossings = find([0; diff(detections)>1]);
    crossings = [crossings ; length(detections)+1]; % to account for the last spike
    % find the minimum value for each spike
    peaktimes = zeros(length(crossings)-1,1);
    cross = zeros(length(crossings)-1,1);
    for c=1:length(crossings)-1
        [v,idx]= min(signal(detections(crossings(c):crossings(c+1)-1)));
        peaktimes(c) = idx + detections(crossings(c))-1;
        cross(c) = detections(crossings(c));
    end;
    
elseif strcmp(options.mode,'pos')
    noise_std = median(abs(signal)/0.6745);
    if options.interactive
        disp(['Noise standard deviation : ', num2str(noise_std)]);
        response = input('Please provide the threshold to be used : ','s');
        if ~strcmp(response,'0'); thr= str2num(response); else; thr = options.thres_mult * noise_std; end;
    else
        thr = options.thres_mult * noise_std;
    end;
    disp(['Threshold used : ' num2str(thr)])
    detections = find(signal > thr); 
    % find all moments when the threshold is crossed
    crossings = find([0 ; diff(detections)>1]);
    crossings = [crossings ; length(detections)+1]; % to account for the last spike
    % find the maximum value for each spike
    peaktimes = zeros(length(crossings)-1,1);
    cross = zeros(length(crossings)-1,1);
    for c=1:length(crossings)-1
        [v,idx]= max(signal(detections(crossings(c):crossings(c+1)-1)));
        peaktimes(c) = idx + detections(crossings(c))-1;
        cross(c) = detections(crossings(c));
    end; 
    
% Nonlinear Energy Operator
elseif strcmp(options.mode,'neo')
    % The transformed signal used for the detection is calculated
    signal_detection = nonlinear_energy_operator(signal)';
    disp(['Signal rms: ' num2str(rms(signal_detection))])
    if options.interactive
        plot_lfp(signal_detection,samplingrate);
        response = input('Please provide the threshold to be used : ','s');
        if ~strcmp(response,'0'); thr= str2num(response); else; thr = 4*rms(signal_detection); end;
        disp(['Threshold used : ' num2str(thr)]);
        close
    elseif strcmp(options.thres_mult,'adaptive')        
        signal_detection = chunk_signal(signal_detection,0.1*samplingrate,1);
        thr = 4*rms(signal_detection')';
        disp('Threshold used : Adaptive (100ms window');
    elseif options.manualthr>0
        thr = options.manualthr;
    else 
        thr = options.thres_mult*rms(signal_detection);
        disp(['Threshold used : ' num2str(thr)]);
    end;   
    
 
    if strcmp(options.thres_mult,'adaptive')
        for s=1:size(signal_detection)
            peaktimes{s} = (s-1)*size(signal_detection,2) + LocalMinima(-signal_detection(s,:), options.waveformlength*samplingrate, -thr(s));            
        end
        peaktimes=cell2mat(peaktimes');
    else        
        peaktimes = LocalMinima(-signal_detection, options.waveformlength*samplingrate, -thr); % 1ms distance of peaks     
    end
    
    % This is a maximum value of the peak, to avoid artifacts being taken
    % into account
    
    peaktimes(signal_detection(peaktimes)>options.maxlim*thr)=[];    
end;

%Identify positive detections and instead keep the local minimum
% for c=1:length(peaktimes)
%     if signal(peaktimes(c)) > signal(peaktimes(c)-1) || signal(peaktimes(c)) > signal(peaktimes(c)+1)
%         signalpart = signal(peaktimes(c)-dp_pre:peaktimes(c)+dp_post);
%         [m,idx]=min(signalpart);
%         peaktimes(c) = idx + (peaktimes(c) - dp_pre) - 1;
%     end;
% end;

%% Get waveforms

if options.upsampleratio>1
    signal = decimate(signal,options.upsampleratio);
    samplingrate = samplingrate/options.upsampleratio;
    peaktimes = round(peaktimes/options.upsampleratio);
end

dt= options.waveformlength; %ms
dp = dt*samplingrate/1000;
dp_pre = ceil(dp*0.3);
dp_post = dp-dp_pre;

if strcmp(options.alignment,'peak')    
    waveforms = signal(cell2mat(arrayfun(@(x)x-dp_pre:x+dp_post,peaktimes,'un',0)));
    spiketimes = peaktimes/samplingrate;
    
elseif strcmp(options.alignment,'threshold')
    waveforms = zeros(length(peaktimes),dp);
    for c=1:length(peaktimes)
        waveforms(c,:) = spline(1:dp,signal(cross(c)-dp_pre+1:cross(c)+dp_post), linspace(1,dp,dp*10));
        spiketimes = cross/samplingrate;
    end;    
end;


%% Plot
if options.plot
    figure;
    for c=1:size(waveforms,1); 
        plot(waveforms(c,:),'k'); 
        %[m,idx]=min(waveforms(c,:)); 
        %jplot(idx,m,'r*'); 
        hold on; 
    end;
end
