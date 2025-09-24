function [] = plotFeatureSpace(featNorm,j, id_show, path_output, featureNames, fig)
% Show feature space of a neuron. Whole distribution shown in blue and
% particular unit of interest shown in orange

%fig = figure;
plotPositions = [5, 10, 15, 20, 21, 22, 23, 24, 25];
    for i = 1:size(featNorm,1)
        subplot(5, 5, plotPositions(i));
        h = histogram(featNorm(i, :), 20, 'FaceColor', [0 0.4470 0.7410],'EdgeColor' ,'black');
        hold on;
        sample_value = featNorm(i, j);

        edges = h.BinEdges;
        counts = h.BinCounts;
        %[~, bin_index] = min(abs(edges(1:end-1) + diff(edges)/2 - sample_value));
        bin_index = find(edges <= sample_value, 1, 'last');
        if bin_index == numel(edges)
            bin_index = bin_index - 1;
        end

        bar_width = diff(edges(1:2));
        bar_height = counts(bin_index);
        bar_position = edges(bin_index) + bar_width / 2;
        %rectangle('Position', [bar_position(1), 0, bar_width, bar_height], 'FaceColor', 'red');
        rectangle('Position', [bar_position - bar_width / 2, 0, bar_width, bar_height], 'FaceColor', [0.9500 0.5250 0.2980]);



        title(featureNames(i));
        if i == 1
            xticklabels({'down', 'both', 'up'});
            xtickangle(0);
        end
        if i == 5
            xlabel('Normalized Feature');
            ylabel('Frequency');
        end
        hold off;
    end
    mtit(['Trajectory, Layout and Features of Unit #', num2str(id_show)],'yoff',0.03,'xoff',0);% instead of sgtitle
    %tight_layout;
    
    % Export figure as png
    folderPath = fullfile(path_output); % Update folder path
    fileName = fullfile(folderPath, ['unit', num2str(id_show), '.png']);
    if ~exist(folderPath, 'dir')
        mkdir(folderPath);
    end
    saveas(gcf, fileName);
    clf;
    close(fig);
end

