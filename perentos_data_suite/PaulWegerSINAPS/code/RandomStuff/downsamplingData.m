% Downsampel remaining dendrites to have fewer data


x_dendrite_resample = cell(1, length(x_dendrite));
y_dendrite_resample = cell(1, length(y_dendrite));
z_ampl_resample = cell(1,length(y_dendrite));
z_time_resample = cell(1, length(y_dendrite));

for i = 1:length(x_dendrite)
    selectedXValues = [];
    selectedYValues = [];
    zA = [];
    zT = [];
    selectedXValues(1) = x_dendrite{i}(1);
    selectedYValues(1) = y_dendrite{i}(1);
    zA(1) = z_ampl_dendrite{i}(1);
    zT(1) = z_time_dendrite{i}(1);
    lengthTemp = length(x_dendrite{i}) / 22 +1;
    if lengthTemp >= 2
        selectedXValues(2:lengthTemp) = x_dendrite{i}(22:22:end);
        selectedYValues(2:lengthTemp) = y_dendrite{i}(22:22:end);
        zA(2:lengthTemp) = z_ampl_dendrite{i}(22:22:end);
        zT(2:lengthTemp) = z_time_dendrite{i}(22:22:end);
    end
    x_dendrite_resample{i} = selectedXValues;
    y_dendrite_resample{i} = selectedYValues;
    z_ampl_resample{i} = zA;
    z_time_resample{i} = zT;

end

x = x_dendrite_resample;
y = y_dendrite_resample;
time = z_time_resample;
amplitude = z_ampl_resample;
idGood = id_good;
features = feat;
featuresNorm = featNorm;
featureNames = featureNameNice;

save('extractedData.mat','x','y','time','amplitude','idGood','features','featuresNorm','featureNames');