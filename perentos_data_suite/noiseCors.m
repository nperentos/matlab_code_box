function out = noiseCors(fileBase)

% takes tun structure from a particular session from place_cell_tunings.mat 
% and computes various quantities relating to residual activity across
% cells by removing the mean activity (the tuning curve) from each trial
% and each neuron's response

% what we want to achieve here is to see whether there is any deviations
% from the mean response of place cells that are shared across neurons


