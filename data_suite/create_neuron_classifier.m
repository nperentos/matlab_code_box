function create_neuron_classifier(unit_spikes,unit_templates)

[properties,T] = neuron_characterization(unit_spikes,unit_templates);
SVMModel = fitcsvm(properties(:,1:2),T,'Standardize',true,'KernelFunction','RBF','KernelScale','auto','OptimizeHyperparameters','auto', 'HyperparameterOptimizationOptions',struct('AcquisitionFunctionName','expected-improvement-plus'));
save('neuron_classifier.mat','SVMModel')