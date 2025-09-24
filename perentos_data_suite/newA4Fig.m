function h = newFig(varargin);

options = {'orientation','portrait','size','A4'};
options = inputparser(varargin,options);
if strcmp(options,'error'); return; end;

if strcmp(options.orientation, 'landscape') & strcmp(options.size, 'A4')
    h = figure('pos',[100, 100, 297*6, 210*6]); % we will divide this figure in two
elseif strcmp(options.orientation, 'portrait') & strcmp(options.size, 'A4')
    h = figure('pos',[100, 100, 210*6, 297*6]); % we will divide this figure in two
elseif  strcmp(options.orientation, 'landscape') & strcmp(options.size, 'halfA4')
    h = figure('pos',[100, 100, 210*6, 296*3]); 
elseif  strcmp(options.orientation, 'portrait') & strcmp(options.size, 'halfA4')
    h = figure('pos',[100, 100, 210*3, 296*6]); 
else
    error('inputs to newFigA4 not recognised');
end