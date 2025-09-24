load("xyzfeatures.mat");

a = feat(3,:);
b = feat(4,:);
d = feat(6,:);

aFS = a(d<0.42);
aRS = a(d>= 0.42);
bFS = b(d<0.42);
bRS = b(d>=0.42);

figure
subplot(2,3,[1,2,4,5]);
hold on;
scatter(aRS,bRS, 15, [0.8500 0.3250 0.0980],'filled','DisplayName','RS');
scatter(aFS,bFS,20,[0 0.4470 0.7410], 'filled','DisplayName','FS');
%legend('Location','best');
title("Scatter of inverse propagation velocity");

xlabel("1/v_{above} (ms/mm)");
ylabel("1/v_{below} (ms/mm)");

ylim([-8, 8]);
xlim([-8, 8]);

xlimit = get(gca,'XLim');
ylimit = get(gca,'YLim');
plot(xlim, [0 0], '--k','HandleVisibility','off');
plot([0 0], ylim, '--k','HandleVisibility','off'); 


subplot(2,3,3);
pieData = [length(aRS), length(aFS)];
pieLabels = {'Regular Spiking','Fast Spiking'};
pieColors = [
    0.8500 0.3250 0.0980;
    0 0.4470 0.7410
];
ax = gca();
pie(pieData);
ax.Colormap = pieColors;
legend(pieLabels,'Location','southoutside');

subplot(2,3,6);
h = histogram(feat(6,:),20,'FaceColor',[0.8500 0.3250 0.0980],'FaceAlpha',1);

edges = h.BinEdges;
counts = h.BinCounts;

bin_index = find(edges <= 0.42);

if bin_index == numel(edges)
    bin_index = bin_index - 1;
end

bar_width = diff(edges(1:2));
bar_height = counts(bin_index);
bar_position = edges(bin_index) + bar_width / 2;

for i = 1:length(bin_index)
rectangle('Position', [bar_position(i) - bar_width / 2, 0, bar_width, bar_height(i)], 'FaceColor', [0 0.4470 0.7410]);
end
xlabel("Duration (ms)");
title("Duration distribution");

