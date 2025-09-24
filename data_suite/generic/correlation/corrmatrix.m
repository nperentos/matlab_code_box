% Returns the correlation matrix for 2 neurons
%
% Input should be in the form : 
% rows : trials, columns : time bins
% matrices should have the same size
%
% For an example, use : neuron1  = randn(10,20); % 10 trials, 20 time bins
% and neuron2  = randn(10,20); % 10 trials, 20 time bins
%
% Author : Nikolas Karalis
% Date : 23/04/2013

function corrs=corrmatrix(neuron1, neuron2)

timebins = size(neuron1,2);

corrs = zeros(timebins,timebins);
for t1 = 1:timebins
    for t2 = 1:timebins
        c=corrcoef(neuron1(:,t1),neuron2(:,t2));
        corrs(t1,t2)=c(1,2);
    end;
end;

% If you want to plot (in the single pair case), uncomment the following
% line.

%imagesc(corrs);