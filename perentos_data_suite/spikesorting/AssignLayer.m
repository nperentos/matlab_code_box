function AssignLayer(FileBase)

load([FileBase '.CellQualitySummary.mat']);
[AnatLayerTitle, AnatLayerChan] = LoadAnatLayers2([CurrentFileBase '.AnatLayers']);

for j = 1:length(quality)
    
    foundLayer = 0;
    
    for i = 1:length(AnatLayerChan)
        inLayer = ismember(quality(j).cluCh,AnatLayerChan{i});
        
        if inLayer
            quality(j).Layer = AnatLayerTitle{i};
            foundLayer = 1;
        end
        
    end
    
    if ~foundLayer
        quality(j).Layer = 'Unknown';
    end
    
end

save([FileBase '.CellQualitySummary.mat'],'quality');

end