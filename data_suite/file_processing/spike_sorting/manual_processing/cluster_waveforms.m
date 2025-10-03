function units=cluster_waveforms(waveforms,scores,method)

if strcmp(method, 'kmeans')
    no_clusters = 2;
    no_components = 10;
    clusters=kmeans(scores(:,1:no_components),no_clusters,'display','final','replicates',5, 'distance','correlation');
    units={};
    colors = ['k' 'b' 'r' 'g' 'c' 'm' 'y' 'b' 'r' 'g' 'c' 'm' 'y' 'b'];
    for c=1:no_clusters
        units{c}=waveforms(clusters==c,:);
        %plot(scores(clusters==c,1),scores(clusters==c,2),[colors(c) '+']);
        %scatter3(scores(clusters==c,1),scores(clusters==c,2),scores(clusters==c,3),[colors(c) '+']);
        %hold on;
    end;
    for c=1:no_clusters
        plot(mean(units{c}),colors(c));
        hold on;
    end;
%     plot all units
%     for c=1:no_clusters
%         figure;
%         for k=1:length(units{c})
%             plot(units{c}(k,:));
%             hold on;
%         end;
%     end;
end;

if strcmp(method, 'gaussian')
    no_clusters = 2;
    no_components = 3;
    gm = gmdistribution.fit(scores(:,1:no_components),no_clusters);
    clusters = cluster(gm,scores(:,1:no_components));
    units={};
    colors = ['k' 'b' 'r' 'g' 'c' 'm' 'y' 'b' 'r' 'g' 'c' 'm' 'y' 'b'];
    for c=1:no_clusters
        units{c}=waveforms(clusters==c,:);
        plot(scores(clusters==c,1),scores(clusters==c,2),[colors(c) '+']);
        %scatter3(scores(clusters==c,1),scores(clusters==c,2),scores(clusters==c,3),[colors(c) '+']);
        hold on;
    end;
    figure;
    for c=1:no_clusters
        plot(mean(units{c}),colors(c));
        hold on;
    end;
end;