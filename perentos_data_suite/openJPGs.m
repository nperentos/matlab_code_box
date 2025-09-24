function openJPGs(fileBase,varargin);
% a function to sort tuning jpg reports fileNames according to cluster's
% main channel, or MUA/SUA or channel number. Mainly it is useful for
% opening clusters with close channels so as to do some qualitative
% inspection/comparison of their tunings
% INPUT: fileBase: but relies on the presence of place_cell_tunings.mat
%        sortBy:   1 for cluster ID, 2 for channel number  (optional)
% OUTPUT: none, just opens figures outside matlab

options = {'sortBy',[2]};
options = inputparser(varargin,options);

