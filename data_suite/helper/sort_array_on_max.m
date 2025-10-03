% Description : 
%
% Algorithm : 
%
% Input :  
%
% Output : 
%
% Author : Nikolas Karalis
% Date : April 2013
%
% Dependencies : 
%
% Updates : 
%

% Sort the rows of an array based on the column of occurence of the maximum
% value. Returns the sorted matrix and the permutation used.
function [s,p] = sort_array_on_max(x)
[m,idx] = max(x,[],2); %  calculate indexes of maximum values (idx).
[s,p] = sort(idx); % create a permutation array (p) that sorts the maximum values
s=x(p,:); % permute the original array with the same way.