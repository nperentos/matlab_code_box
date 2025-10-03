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
% 26/11/2016: Completely re-wrote and simplified.
% Basic features: 
% * Works only with defaults (you should always have default values in the
% functions anyway)
% * Now works with cell arrays as well.
% * Provides a list of user specified options (as opposed to defaults) 
% * You can provide a struct instead of cell
% * If an argument is not part of the default list, it returns an error
%
% 21/06/2015: Modified to accept only options, without defaults (in this
% case the default values are inside the options cell).
% 06/11/2014: Added the help option. The basic limitation is that you cannot 
% provide a cell array as an input. 
% For that you can go around by using a struct or a delimited
% string which then you parse in your function.

function out = inputparser(options, defaults)

if iscell(defaults)
    if mod(length(defaults),2)~=0;
        error('Please provide the correct number of default arguments.');
    end
    out = cell2struct(defaults(2:2:end)',defaults(1:2:end));    
end

if length(options)==1 & isstruct(options{1})    
    options = options{1};
elseif length(options)==1 & strcmp(options,'help');
    disp('Available options');
    disp('');
    disp(out);
    out = 'help';
    return;
% elseif mod(length(options),2)~=0;
%     error('Please provide the correct number of argument pairs.');
elseif isempty(options)
    options = out;
else %% its a cell therefore...
    
    if iscell(options{1}) % is it a cell in a cell? then unwrap it
        options = options{1};
    end
    options = cell2struct(options(2:2:end)',options(1:2:end));
end;

%if ~isempty(options)
    ff = fieldnames(options);
    for c=1:length(ff)
        if ~isfield(out,ff{c});
            s = sprintf('Field %s is not valid.',ff{c});
            error(s);
        end
        out.(ff{c}) = options.(ff{c});
    end
%end