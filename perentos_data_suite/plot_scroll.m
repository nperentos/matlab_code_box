function [fig,Axes] = plot_scroll(varargin)
%% plot_scroll
% draw multiple plots with subplot function with scroll bar
% Input parameters
% - PlotFunction : default = @plot. 
% Output parameters
% - fig : figure handle
% - Axes : axes handle


%% Constants
Options.NumAxis = 2;
Options.PlotFunction = @plot;

%% Fixed Constants
SLIDER_SIZE = 20;
CONST.length = 0.8;
CONST.hmargin = 0.1;

%% Dependent Constants
CONST.height = 1/Options.NumAxis - 2 * CONST.hmargin;
CONST.lmargin = (1 - CONST.length)/2;

%% Parse varargin
numArgin = length(varargin);
if numArgin == 1 % data only
    if ~isnumeric(varargin{1})
        error('Only numeric 2d numeric data can be plotted');
    end
    if numel(size(varargin)) >= 3
        error('Data dimension must be 2');
    end
    data = cell2mat(varargin);
elseif rem(numArgin,2) == 1 % n*pairs + data == odd number
    if ~isnumeric(varargin{1})
        error('Only numeric 2d numeric data can be plotted');
    end
    if numel(size(varargin)) >= 3
        error('Data dimension must be 2');
    end
    data = cell2mat(varargin(1));
    for pair = reshape(varargin(2:end),2,[])
        pname = pair{1};
        if any(strcmp(pname,fieldnames(Options)))
            Options.(pname) = pair{2};
        else
            error('%s is not a recognized parameter name',pname);
        end 
    end
else
    error('Please check propertyName/propertyValue pairs');
end

if numel(size(data)) ~= 2
    error('Dimension of the data should be 2.');
end

%% Create Figure
fig = figure;
clf;

%% Create Axes
axis_col = size(data,2);
Axes = cell(1,axis_col);
for a = 1 : axis_col
    Axes{a} = axes;
    Axes{a}.Position = [...
        CONST.lmargin,...
        CONST.hmargin + (Options.NumAxis-a) * (2*CONST.hmargin + CONST.height),...
        CONST.length,...
        CONST.height];
    Options.PlotFunction(Axes{a},data(:,a));
    title(Axes{a},strcat('Data : ', num2str(a)));
end

%% Create Slider
FigurePosition = fig.Position;
SliderPositionX = FigurePosition(3)-SLIDER_SIZE;
Slider = uicontrol(...
    'Style','slider',...
    'Position',[SliderPositionX,0,SLIDER_SIZE,FigurePosition(4)],...
    'Min',0,...
    'Max',(axis_col - Options.NumAxis) * (2*CONST.hmargin + CONST.height),...
    'Value',(axis_col - Options.NumAxis) * (2*CONST.hmargin + CONST.height),...
    'Callback',{@slidermove,Axes, axis_col, Options.NumAxis, CONST});
fig.SizeChangedFcn = {@refreshSlider,Slider,SLIDER_SIZE};

%% Figure Size Change Callback function
function refreshSlider(source, ~,Slider,SLIDER_SIZE)
    FigurePosition_ = source.Position;
    SliderPositionX_ = FigurePosition_(3)-SLIDER_SIZE;
    Slider.Position = [SliderPositionX_,0,SLIDER_SIZE,FigurePosition_(4)];
end    
%% Slider Move Callback function
function slidermove(source, ~, Axes, axis_col, NumAxis, CONST)
    slidervalue = (axis_col - NumAxis) * (2*CONST.hmargin + CONST.height) - source.Value;
    for ax = 1 : numel(Axes)
        Axes{ax}.Position = [...
            CONST.lmargin,...
            CONST.hmargin + (NumAxis-ax) * (2*CONST.hmargin + CONST.height) + slidervalue,...
            CONST.length,...
            CONST.height];
    end
end
end