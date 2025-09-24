function PlotUnitSummary(pth)

cd(pth)
load([CurrentFileBase '.NeuronQualityKilosort.mat'])
load([CurrentFileBase '.SplitClustersIntoBursts.mat'])

%%

for i = 1:length(burst.cids)
    
    Clu = burst.cids(i);
    
    nqIndex = find(nq.cids==Clu);
    
    acg = GetACG(nqIndex-1, CurrentFileBase);
    acg.CCG(26)=0; % Manually set the central bin to 0
    
    
    % Plot figure
    fig = figure;
    subplot(2,2,1)      % Waveshape
    plot(nq.AvSpk{nqIndex});
    title('Average waveshape');
    
    
    h2 = subplot(2, 2, 2);
    set(gca,'XColor', 'none','YColor','none')
    text(0, 0, sprintf(' %s\n \n %s \n %s \n \n %s \n \n \n \n \n', ...
        ['Cluster ID: ' num2str(Clu)], ...
        ['Isolation Distance: ' num2str(nq.eDist(nqIndex))],...
        ['ISI Violations: ' num2str(nq.Refrac(nqIndex))], ...
        ['Average Firing Rate: ' num2str(nq.FirRate(nqIndex))]), ...
        'Parent', h2);

    subplot(2,2,3)      % Autocorrelogram
    bar(acg.tbin,acg.CCG);
    xlim([-50 50])
    
    
    %subplot(2,2,4)      % First PC or Amplitude vs. time

    
    
    
    %Save Figure
    FileOut = sprintf(['%s.%s.%d.jpg'], CurrentFileBase, mfilename,Clu);
    fprintf(['Saving figure into a figure %s ...'], FileOut)
    mkdir2(['figures/' mfilename '/']);
    FileOut = ['figures/' mfilename '/' FileOut]
    saveas(fig, FileOut);

    fprintf('DONE\n')

    
    
end

%%

end