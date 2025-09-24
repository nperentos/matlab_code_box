function [] = polarwitherrorbar(ax, angle,avg,error,clr)
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The first two input variables ('angle' and 'avg') are same as the input 
% variables for a standard polar plot. The last input variable is the error
% value. Note that the length of the error-bar is twice the error value we
% feed to this function.
% NP: modified to show one sided error bar
% NP: added a clr input variable to define the color of the plotted line so
% that one can plot multple plots on the same axes using different colors
% In order to make sure that the scale of the plot is big enough to
% accommodate all the error bars, i used a 'fake' polar plot and made it
% invisible. It is just a cheap trick. 
% The 'if loop' is for making sure that we dont have negative values  when
% an error value is substrated from its corresponding average value. 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
n_data = length(angle);
%fake = polarplot(angle,max(avg+error)*ones(1,n_data)); set(fake,'Visible','off'); hold on; 
h = polarplot(ax,angle,avg); h.LineWidth = 2; h.Color = clr;
for ni = 1 : n_data
        h = polarplot(ax,angle(ni)*ones(1,2),[avg(ni), avg(ni)+error(ni)],'-r'); h.LineWidth = 2; h.Color = [clr, 0.5];
end
hold on











%%%%%%%%ORIGINAL%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% n_data = length(angle);
% fake = polar(angle,max(avg+error)*ones(1,n_data)); set(fake,'Visible','off'); hold on; 
% h = polar(angle,avg,'b'); h.LineWidth = 2;
% for ni = 1 : n_data
%     if (avg(ni)-error(ni)) < 0
%         h = polar(angle(ni)*ones(1,3),[0, avg(ni), avg(ni)+error(ni)],'-r');  h.LineWidth = 2;
%     else
%         h = polar(angle(ni)*ones(1,3),[avg(ni)-error(ni), avg(ni), avg(ni)+error(ni)],'-r'); h.LineWidth = 2;
%     end
% end
% hold off