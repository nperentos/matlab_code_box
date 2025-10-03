% Description : 
% This function takes care of the details of adding matrices
% Features : 
% * Adding matrix with empty matrix (useful for initializations in for
% loops when you don't know the exact elements.
% * Adding different sized matrices
% Algorithm : 
%
% Input :  
%
% Output : 
%
% Author : Nikolas Karalis
% Date : 07/06/2013
%
% Dependencies : none
%
% Updates : 
%
%
% Copyright (C) 2013  Nikolas Karalis
% 
% ********************************************************************
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.
%
% ********************************************************************
%
% 
%
%
% To do : 
% Write part for 0-padding smaller matrix
% Extend to more than 2 dimensions
% Extend it for other element wise operations.

function S=add_matrix(a,b,pad)
if nargin<3; pad = 0; end;

if length(size(a))~=length(size(b));
    return
elseif size(a)==size(b); 
    S = a+b;
elseif isempty(a); 
    S = b; 
elseif isempty(b);
    S = a;    
elseif sum(size(a)==size(b))~=length(size(a));
    if pad==0;
        min_size = min([size(a); size(b)],[],1);
        S = a(1:min_size(1),1:min_size(2)) + b(1:min_size(1),1:min_size(2));
    else
        % To write
    end
end;
