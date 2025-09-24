function PlotClusterSummary(pth)

cd(pth)
load([CurrentFileBase '.CellQualitySummary.mat'])

%%

figure
hold on

subplot(2,2,1)
xlabel('Firing rate') 
ylabel('Fraction of single spikes vs. bursts') 

subplot(2,2,2)
xlabel('Firing rate') 
ylabel('SpkWidthR') 

subplot(2,2,3)
xlabel('Firing rate') 
ylabel('SpkWidthL') 

subplot(2,2,4)
xlabel('eDist') 
ylabel('Refrac') 

for i = 1:length(quality)
    
    if quality(i).Refrac < 0.1;
        
        subplot(2,2,1)
        hold on
        scatter(quality(i).FirRate, quality(i).sFraction);
        text(quality(i).FirRate, quality(i).sFraction,num2str(quality(i).cids))
        
        subplot(2,2,2)
        hold on
        scatter(quality(i).FirRate, quality(i).SpkWidthR);
        text(quality(i).FirRate, quality(i).SpkWidthR,num2str(quality(i).cids))
        
        subplot(2,2,3)
        hold on
        scatter(quality(i).FirRate, quality(i).SpkWidthL);
        text(quality(i).FirRate, quality(i).SpkWidthL,num2str(quality(i).cids))
        
        subplot(2,2,4)
        hold on
        scatter(quality(i).eDist, quality(i).Refrac);
        text(quality(i).eDist, quality(i).Refrac,num2str(quality(i).cids))
        
    end
    
end

%%

end