function outlierIndexes = Isoutlier(vector,sens1,sens2)
% a two step outlier removal using median absolute deviation estimates. 
% to get a robust estimation of the distribution we first remove outliers
% from the full distribution, and then repeat the estimation but for the
% original data but this time we exclude the outliers
% thr1: threshold to identify outliers in the full distribution
% thr2: threshold to compute outliers in the restricted distribution
% (outliers removed)
% default thresholds are  set to 6 and 3 times the median abs deviation
if nargin <2; sens1 = 6; sens2 = 3; end

% Compute the median absolute difference
meanValue = mean(vector);
% Compute the absolute differences.  It will be a vector.
absoluteDeviation = abs(vector - meanValue);
% Compute the median of the absolute differences
mad = median(absoluteDeviation);
% Find outliers.  They're outliers if the absolute difference
% is more than some factor times the mad value.
sens1 = 3; % Whatever you want.
thresholdValue = sens1 * mad;
outlierIndexes = abs(absoluteDeviation) > thresholdValue;
% Extract outlier values:
outliers = vector(outlierIndexes);
% Extract non-outlier values:
nonOutliers = vector(~outlierIndexes);% Compute the median absolute difference
meanValue = mean(vector);
% Compute the absolute differences.  It will be a vector.
absoluteDeviation = abs(vector - meanValue);
% Compute the median of the absolute differences
mad = median(absoluteDeviation);
% Find outliers.  They're outliers if the absolute difference
% is more than some factor times the mad value.
sens2 = 6; % Whatever you want.
thresholdValue = sens2 * mad;
outlierIndexes = abs(absoluteDeviation) > thresholdValue;
% Extract outlier values:
% outliers = vector(outlierIndexes);
% Extract non-outlier values:
% nonOutliers = vector(~outlierIndexes);





%% below is an OK procedure but median is estimated using full distribution
% so its not robust enough
%  function [av] = Isoutlier(FF)
%   mk = median (FF);
%   M_d = mad (FF, 1);
%   c = -1 / (sqrt (2) * erfcinv (3/2));
%   smad = c * M_d;
%   tsmad = 3 * smad;
%   av = (abs (FF-mk)>= tsmad);
%  end