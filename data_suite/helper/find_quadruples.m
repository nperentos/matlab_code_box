% Description : This function finds quadruples of non zero elements in a matrix.
%
% Algorithm : 
%
% Input :  
%
% Output : 
%
% Author : Nikolas Karalis
% Date : 06/06/2013
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

function quads = find_quadruples(M,threshold)

if nargin<2; threshold = 0; end; % Option for getting elements bigger than some arbitrary threshold.

x = find(M>threshold); % Finds indexes of elements larger than 0

quads=[];
k=1; % counter of quadruples found
for c=1:length(x)
    if any(x==x(c)+1) && any(x==x(c)+size(M,1)) && any(x==x(c)+size(M,1)+1); % find elements that follow the pattern
        quads(k)=x(c); % save quadruple index
        k=k+1; % counter increase
    end;
end;

% This is just converting the linear indices to row and column coordinates
% and is displaying them.
for c=1:length(quads)
    [r,c]= ind2sub(size(M), quads(c));
    disp([num2str(r) ' - ' num2str(c)])
end;