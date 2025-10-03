% Description : 
% This function resolves the problem of floating point arithmetic
% Where two essentialy equal numbers are represented as different
% For example : >> 0.3 - 0.2 - 0.1
%
% Algorithm : 
%
% Input :  number to be compared (a,b) and the tolerance to be used
% (optional). If not provided, the default 10^(-10) is used.
%
% Output : 1 (equal) or 0 (not equal)
%
% Author : Nikolas Karalis
% Date : 01/06/2013
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

function equal = are_equal(a,b,tolerance)
if nargin<3; tolerance = 10^(-10); end;

equal = abs(a-b) < tolerance;
    