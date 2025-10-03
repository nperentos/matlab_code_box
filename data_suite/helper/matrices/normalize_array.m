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

% Normalize each column of the array to it's max
% Watch out when having negative values

function y = normalize_array(x, column_flag)
if nargin<2; column_flag=0; end;
if column_flag;
	y=bsxfun(@rdivide, x,max(x,[],2));
else
	y=bsxfun(@rdivide, x,max(x,[],1));
end;
