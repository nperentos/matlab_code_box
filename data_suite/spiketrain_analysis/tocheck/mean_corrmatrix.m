% Returns the correlation matrix for 2 neurons
%
% Input should be a 3 dimensional matrix of the form : 
% rows : trials, columns : time bins
% matrices should have the same size
% 3rd dimension : different neurons
%
% For an example, use : neurons=randn(10,20,5); % 10 trials, 20 time bins,
% 5 neurons
%
% Author : Nikolas Karalis
% Date : 23/04/2013

function corrs=mean_corrmatrix(neurons)
combinations = combnk(1:size(neurons,3),2);

timebins = size(neurons,2);

corrs = zeros(timebins,timebins);

for c=1:size(combinations,1)
    corrs = corrs + corrmatrix(neurons(:,:,combinations(c,1)),neurons(:,:,combinations(c,2)));
end;

corrs=corrs/length(combinations);

imagesc(corrs); colorbar;