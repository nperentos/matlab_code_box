function [] = plotFeatureSpace(featNorm,j, id_show, path_output, featureNames)
% Show feature space of a neuron. Whole distribution shown in blue and
% particular unit of interest shown in orange

fig = figure;
    for i = 1:size(featNorm,1)
        subplot(3, 3, i);
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
        hold off;
    end
    sgtitle(string(['Unit #', num2str(id_show),' normalized features']));
    
    % Export figure as png
    folderPath = fullfile(path_output, 'FeatureSpace'); % Update folder path
    fileName = fullfile(folderPath, ['unit', num2str(id_show), '_features.png']);
    if ~exist(folderPath, 'dir')
        mkdir(folderPath);
    end
    saveas(gcf, fileName);
    clf;
    close(fig);
end

