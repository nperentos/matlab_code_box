function T = classify_new_neurons(unit_spikes,unit_templates)

if length(unit_spikes)~=length(unit_templates); error('Spikes and templates have different length.'); end;

%% Load pre-trained classifier
load('neuron_classifier.mat','SVMModel')

%% Calculate properties
props = struct();
for c=1:length(unit_spikes);
    tmp = spike_properties(unit_spikes{c},unit_templates{c});
    if c==1;
        props = tmp;
    else
        props(c) = tmp;
    end
end

amp = [props.amp];
freq = [props.freq];
halfwidth = [props.halfwidth];
asymmetry = [props.asymmetry];
t2p = [props.t2p];

properties = [t2p(:), asymmetry(:), halfwidth(:),log(freq(:))];

%% Predict label
T = predict(SVMModel,properties(:,1:2));