function plot_all_units(units,window,time)
% Find time
if nargin<2; window = 1; end;
if nargin<3 || isempty(time);
    time(1) = 0;
    time(2) = 0;
    for c=1:size(units,1)
        time(2) = max(time(2),max(units{c,2}));        
    end;
end;

time = linspace(time(1),time(2),length(0:window:time(2)));
figure;
hold on;

for c=1:size(units,1)
    h=histc(units{c,2}, 0:window:max(time));
    h=rescale_values(h,0,1);
    bar(time,h+c,'k','BaseValue',c);    
end;
set(gca,'YTick',1.5:1:size(units,1)+0.5,'YTickLabel',{units{:,1}},'TickDir','out')
xlim([min(time),max(time)])
box off;
hold off;    
