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

% When using show_progress, remember to use the following before and after
% the for loop.
% Before : fprintf(1,'Progress :  ')
% After : fprintf('\n')

function show_progress(n)
for k = 1:ceil(log10(n+1))
    fprintf(1,'\b'); 
end
fprintf(1,'%d',n);