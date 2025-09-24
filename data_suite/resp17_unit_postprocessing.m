%% Find files to sort
tosort={};
k = 1;
for c=1:length(files); 
    data = load_data(files{c});    
    if ~isfield(data,'units');
        disp(files{c});
        tosort{k} = files{c};
        k=k+1;
        %break
    end
end;

%% Find files with multiple unit files and re-extract them

problem = [];
for c=1:length(files)
    fn = list_files(files{c},'*.units1');
    if ~isempty(fn)
        c
        problem = cat(1,problem,c);
        fn = list_files(files{c},'*.units*');
        fn = fn(2:end);
        for k=1:length(fn);
            read_mountainsort(files{c},k);
        end
        merge_units(files{c});
    end
end

%% Re-set main channel
for c=1:length(files);
    disp(c)
    unit_manual_channel_setting(files{c});
end

%% Fix waveform (if missing)
for c=1:length(files);
    data = load_data(files{c});
    if isempty(data.units); continue; end;
    tmp = cellfun(@(x) size(x,1),data.units.waveform);
    tmp = find(tmp==0);
    if ~isempty(tmp);
        disp(c);
        add_unit_template(files{c})
    end;
end;

%% Add template to units
for c=1:length(files);
    data = load_data(files{c});
    if isempty(data.units); continue; end;
    %if ~any(strcmp(fieldnames(data.units),'template'));
        disp(c);
        add_unit_template(files{c});
    %end;
end;

%% Clean up units
%k=0;
for c=1:length(files);
    data = load_data(files{c});
    if isempty(data.units); continue; end;
    if any(strcmp(fieldnames(data.units),'template')) & sum(strcmp(data.units.type,'good') | strcmp(data.units.type,'ok') | strcmp(data.units.type,'mua') | strcmp(data.units.type,'delete'))==0;
        disp(c); unit_manual_cleanup(files{c});
        %disp([c size(data.units,1)])        
    end;
    %k = k + sum(strcmp(data.units.type,'good'));
end;

%% Add properties
accidx = (501-100):(501+100);
for c=1:length(files);
    disp(c)
    unitsfn = get_lfp_filename(files{c},'units');
    load(unitsfn,'units','-mat');
    if ~isempty(units); try; units.properties = []; catch; end; end;
    for k=1:size(units,1);
        units.properties(k) = spike_properties(units.spikes{k},units.waveform{k},1);
        units.autocorr{k} = units.properties(k).autocorr(accidx);        
    end
    save(unitsfn,'units');
    %units
end

%% Test unit-merging
for c=2%:length(files);
    unitsfn = get_lfp_filename(files{c},'units');
    load(unitsfn,'units','-mat');
    for k=1%:size(units,1);
        ch = units.channel(c);
        raster_plot(units.spikes(find(units.channel>=ch-2 & units.channel<=ch+2)))
    end
end

%% Combine all units
files =  [files_laminar(:) ; files_depth(:) ; files_others(:) ; files_hpc(:)];
files = unique(files);
files = fn_from_fn(files);

unitsall = table();
datasetid = [];
for f=1:length(files);
    unitsfn = get_lfp_filename(files{f},'units');
    units = load(unitsfn,'units','-mat');
    units = units.units;
    
    if isempty(units);
        continue;
    end
    
    if any(strcmp(fieldnames(units),'channel_phy'));
        units.channel_phy = [];
        units.metrics = cell(size(units,1),1);
    end;
    if any(strcmp(fieldnames(units),'acc'));
        units.acc = [];
    end;
    
    unitsall = cat(1,unitsall,units);
    datasetid = cat(1,datasetid,f*ones(size(units,1),1));
end

%% Characterize all units
unitsall = unitsall_thalamus;
hw = [unitsall.properties.halfwidth]'; 
asymmetry = [unitsall.properties.asymmetry]'; 
t2p = [unitsall.properties.t2p]'; 
freq = log([unitsall.properties.freq])';
wfsign = [unitsall.properties.sign]';
idx  = ~(strcmp(unitsall.type,'delete') | strcmp(unitsall.type,'mua') | wfsign>0);

T = kmeans([t2p asymmetry],2,'Replicates',200,'start','cluster');

if trimean(t2p(T==1))<trimean(t2p(T==2))
    T(T==1)=10;
    T(T==2)=1;
    T(T==10)=2;
end

disp('T == 1 are the Pyramidal Neurons')
disp('T == 2 are the Interneurons')
disp(['There are ' num2str(sum(T==1)) ' Pyr (' num2str(sum(T==1)/length(T)*100) '%)'] )
disp(['There are ' num2str(sum(T==2)) ' IN (' num2str(sum(T==2)/length(T)*100) '%)'] )

fig; scatter3(t2p(T==1),asymmetry(T==1),freq(T==1),'.b'); hold on; scatter3(t2p(T==2),asymmetry(T==2),freq(T==2),'.r'); 
xlabel('Trough to peak (ms)'); ylabel('Asymmetry'); zlabel('Frequency (log(Hz))' );
textbp(['n = ' num2str(length(T))])

%% Characterize all units - no t2p
unitsall = unitsall_mpfc;
hw = [unitsall.properties.halfwidth]'; 
asymmetry = [unitsall.properties.asymmetry]'; 
t2p = [unitsall.properties.t2p]'; 
freq = log([unitsall.properties.freq])';
wfsign = [unitsall.properties.sign]';
idx  = ~(strcmp(unitsall.type,'delete') | strcmp(unitsall.type,'mua') | wfsign>0);

T = kmeans([hw asymmetry freq],2,'Replicates',200,'start','cluster');

if trimean(t2p(T==1))<trimean(t2p(T==2))
    T(T==1)=10;
    T(T==2)=1;
    T(T==10)=2;
end

disp('T == 1 are the Pyramidal Neurons')
disp('T == 2 are the Interneurons')
disp(['There are ' num2str(sum(T==1)) ' Pyr (' num2str(sum(T==1)/length(T)*100) '%)'] )
disp(['There are ' num2str(sum(T==2)) ' IN (' num2str(sum(T==2)/length(T)*100) '%)'] )

fig; scatter3(hw(T==1),asymmetry(T==1),freq(T==1),'.b'); hold on; scatter3(hw(T==2),asymmetry(T==2),freq(T==2),'.r'); 
xlabel('Trough to peak (ms)'); ylabel('Asymmetry'); zlabel('Frequency (log(Hz))' );
textbp(['n = ' num2str(length(T))])

%%
fixfig([resultspath 'neuron_classification1'],'transparency',1);

%% Make classifier
SVMModel = fitcsvm([t2p asymmetry],T,'Standardize',true,'KernelFunction','RBF','KernelScale','auto','OptimizeHyperparameters','auto', 'HyperparameterOptimizationOptions',struct('AcquisitionFunctionName','expected-improvement-plus'));
save('neuron_classifier.mat','SVMModel')
fixfig([resultspath 'neuron_classifier_SVM_training'],'transparency',1);

%% Recalc properties
tic;
unitsall.properties = [];
for c=1:size(unitsall);
    if mod(c,100); disp(c); end;
    unitsall.properties(c) = spike_properties(unitsall.spikes{c},unitsall.waveform{c},1);
end
toc;

%% Add unit characterization to all units
% Load pre-trained classifier
load('neuron_classifier.mat','SVMModel')

for c=1:length(files);
    disp(c)
    unitsfn = get_lfp_filename(files{c},'units');
    load(unitsfn,'units','-mat');
    if isempty(units); continue; end;   
    asymmetry = [units.properties.asymmetry]'; 
    
    t2p = [units.properties.t2p]'; 
    
    T1 = predict(SVMModel,[t2p asymmetry]);
    units.class = T1;
    save(unitsfn,'units');
    %units
end

%% Create unit-backup
backup_location = '/storage2/nikolas/results/Respiration2017/unit_backup/';
for c=1:length(files);
    disp(c)
    unitsfn = get_lfp_filename(files{c},'units');
    copyfile(unitsfn,backup_location);
end

%% Find all pairs
% from same dataset, different channel
datasets = unique(datasetid);

xcall = {};
xcallstats = {};
for d=1:10%:length(datasets);
    d
    idx1 = (datasetid==datasets(d));
    idx2  = ~(strcmp(unitsall.type,'delete') | strcmp(unitsall.type,'mua'));
    idx = find(idx1 & idx2);
    unitstmp = unitsall(idx,:);
    pairs = combnk(1:length(idx),2);
    
    for p=1:size(pairs,1);
        xcallstats{d}{p} = [];
        xcall{d}{p} = [];
        if unitstmp.channel(pairs(p,1)) == unitstmp.channel(pairs(p,2));
            continue;
        else
            xcc=run_ccg(unitstmp.spikes{pairs(p,1)},unitstmp.spikes{pairs(p,2)},0.001, 0.05, 30000, 'count');
            xcall{d}{p} = xcc;
            %thr1 = prctile(xcc(1:40,1,2),99.9);
            %thr2 = prctile(xcc(1:40,1,2),0.1);
            thr1 = 2*trimean(xcc(1:40,1,2));
            thr2 = 0.5*trimean(xcc(1:40,1,2));
            if any(xcc(52:54,1,2)>thr1);
                xcallstats{d}{p} = 1;
            end
            if sum(xcc(52:54,1,2)<thr2)>2;
                xcallstats{d}{p} = -1;
            end
            %thr1 = prctile(xcc(1:40,2,1),99.9);
            %thr2 = prctile(xcc(1:40,2,1),0.1);
            thr1 = 2*trimean(xcc(1:40,2,1));
            thr2 = 0.5*trimean(xcc(1:40,2,1));
            if any(xcc(52:54,2,1)>thr1);
                xcallstats{d}{p} = 2;
            end
            if sum(xcc(52:54,2,1)<thr2)>2;
                xcallstats{d}{p} = -2;
            end
            
        end
    end
end

%% Count units
for c=1:length(files);
    data = load_data(files{c});
    disp([c size(data.units,1)])
end

%% All file definitions
files_hpc = {
    'op04_homecage_resp',...
    'hf01_L1_V1',...
    'hf01_L1_vCA1',...
    'hf03_P4_ca1_1500_P9_mpfc_1500',...
    'hf03_P4_ca1_2500_P9_mpfc_1500',...
    'hf03_P4_ca1_2500_P9_mpfc_2500',...
    'hf03_P4_ca1_2500_P9_NAc_4500',...
    'hf03_P4_mpfc_2500_P2_ca1_1300',...
    'hf03_P4_mpfc_2500_P2_V1_1000',...
    'hf03_P4_nac_4000_P2_ca1_1300',...
    'hf03_P4_v1_ca1_1500_M12_mPFC_2000',...
    'hf03_P4_v1_ca1_2450_M12_mPFC_2000',...
    'hf04_P4_ca11_2500_M12_mpfc_2000',...
    'hf04_P4_mpfc_2500_crossdiag_B8_ca1_1850',...
    'hf04_P4_mpfc_2500_L1_ca1_2500',...
    'hf04_P4_mpfc_2900_L1_ca1_3100',...
    'hf04_P4_mpfc_3000_crossdiag_B8_ca1_1850',...
    'hf04_P4_v1_1500_M12_mpfc_1500',...
    'hf04_P4_v1_ca1_1600_M12_mpfc_1600',...
    'hf04_P4_v1_ca1_2300_M12_mpfc_2000',...
    'hf05_P4_ca1_1500_B8_mpfc_1100',...
    'hf05_P4_ca1_2500_B8_mpfc_1900',...
    'hf05_P4_ca1_2500_B8_mpfc_2100',...
    'hf05_P4_ca1_2500_B8_NAcCore_3000',...
    'hf05_P4_ca1_2500_B8_NAcCore_3500',...
    'hf05_P4_ca1_2500_B8_NAcCore_4000',...
    'hf05_P4_ca1_2500_B8_NAcCore_4200',...
    'hf05_P4_ca11_1500_M12_mpfc_1500',...
    'hf05_P4_ca11_2500_M12_mpfc_2500',...
    'hf05_P4_v1_ca1_2000_M12_mpfc_1500',...
    'hf05_P4_v1_ca1_2000_M12_mpfc_1800',...
    'hf05_P4_v1_ca1_2000_M12_mpfc_2150',...
    'hfh01_L3_vca1',...
    'hfh01_L5_dCA1_2_5mm',...
    'hfh01_P4_dCA1_2_0mm',...
    'hfh01_P4_dCA1_2_8mm',...
    'hfh01_P4_way_bla_3mm',...
    'hfh02_P4_ca1_2_6mm',...
    'hfh03_B8_iCA1_1200_P9_mPFC_2000',...
    'hfh03_B8_iCA1_1600_P9_mPFC_2000',...
    'hfh03_P4_dca1_1_3mm_M11_mpfc_1_6mm',...
    'hfh03_P4_dca1_2_2mm_M11_mpfc_1_9mm',...
    'hfh03_P4_dca1_2_2mm_M11_mpfc_1_9mm2',...
    'hfh03_P7_P9_dca1_1_9mm_mpfc_2_2mm',...
    'hfh03_P9_CA1_M8_mPFC',...
    'hfh03_P9_V1_M8_mPFC',...
    'hfh04_P4_CA1_2400',...
    'hfh04_P4_HPC_2300',...
    'hfh04_P4_ica1_1800_P9_mpfc_2100'
    };

files_depth = {'pfc02_day1_homecage',...
    'hf01_L3_mPFC',...
    'hf02_P4_mPFC',...
    'hf02_P4_mPFC_left',...
    'hf02_P4_mPFC2',...
    'hfh01_P4_mpfc_2500_right_naris_open',...
    'hfh02_P4_mpfc_2_4mm',...
    'hfh03_P4_P9_dca1_2_8mm_mpfc_2_2mm',...
    'hfh03_P7_P9_dca1_1_9mm_mpfc_2_2mm',...
    'hfh04_P4_mpfc_2500_open',...
    'hf03_P4_mpfc_2500_P2_ca1_1300',...
    'hf04_P4_mpfc_2500_L1_ca1_2500',...
    'hf04_P4_mpfc_2500_P2_bla_3500',...
    'hf04_P4_mpfc_2900_L1_ca1_3100',...
    'hf05_P4_mpfc_2000_B8_thalamus_3400',...
    'hf05_P4_mpfc_2500_B8_thalamus_4200',...
    'hf03_P4_ca1_1500_P9_mpfc_1500',...
    'hf03_P4_ca1_2500_P9_mpfc_2500',...
    'hf03_P4_mpfc_1500_P2_S1_750',...
    'hf03_P4_mpfc_2500_P2_BLA_4100',...
    'hf03_P4_mpfc_2500_P2_V1_1000',...
    'hfh03_B8_iCA1_1200_P9_mPFC_2000',...
    'hfh03_B8_iCA1_1600_P9_mPFC_2000',...
    'hfh04_P4_dca1_1800_P9_mpfc_1800',...
    'hfh04_P4_ica1_1800_P9_mpfc_2100',...
    'hfh04_P7_dca1_2200_P4_mpfc_1800',...
    'ob02_P4_P2_mPFC_dCA1',...
    'ob02_P4_P2_mPFC_S1_dCA1pyr'
    };

files_others = {'pfc01_homecage',...
    'fbr03_homecage',...
    'ecog01_homecage',...
    'chr02_homecage',...
    'hf01_L1_mPFC',...
    'hf02_M5_mPFC_AP_1',...
    'hf02_M5_mPFC_AP_2',...
    'hf02_M5_mPFC_AP_3',...
    'hf02_M5_mPFC_ML',...
    'hf03_P4_v1_ca1_2450_M12_mPFC_2000',...
    'hf04_P4_mpfc_2500_crossdiag_B8_ca1_1850',...
    'hf04_P4_mpfc_3000_crossdiag_B8_ca1_1850',...
    'hf04_P4_v1_1500_M12_mpfc_1500',...
    'hf04_P4_v1_ca1_1600_M12_mpfc_1600',...
    'hf05_P4_v1_ca1_2000_M12_mpfc_1500',...
    'hf05_P4_v1_ca1_2000_M12_mpfc_1800',...
    'hf05_P4_ca11_1500_M12_mpfc_1500',...
    'hfh01_S1_mPFC_2_5mm',...
    'hfh01_S1_mpfc_2_5mm_2',...
    'hfh03_P4_dca1_1_3mm_M11_mpfc_1_6mm',...
    'hfh03_P4_dca1_2_2mm_M11_mpfc_1_9mm2',...
    'hfh03_P9_CA1_M8_mPFC',...
    'hfh03_P9_V1_M8_mPFC',...
    'ob01_P7_mpfc_photometry_1600',...
    'ob01_P7_mpfc_photometry_1600a',...
    'hf05_P4_ca1_1500_B8_mpfc_1100',...
    'hf05_P4_ca1_2500_B8_mpfc_1900',...
    'hf05_P4_ca1_2500_B8_mpfc_2100',...
    };

files_laminar = {'pfc01_sleep1',...
    
'pfc02_day1_homecage',...

'hfh01_M11_mpfc_1_5mm',...

%'hfh03_P4_dca1_1_3mm_M11_mpfc_1_6mm',...
'hfh03_P4_dca1_2_2mm_M11_mpfc_1_9mm',...
%'hfh03_P4_dca1_2_2mm_M11_mpfc_1_9mm2',...

%'hfh03_P9_CA1_M8_mPFC',...
%'hfh03_P9_V1_M8_mPFC',...

'hf03_P4_v1_ca1_1500_M12_mPFC_2000',...
%'hf03_P4_v1_ca1_2450_M12_mPFC_2000',...

'hf04_P4_ca11_2500_M12_mpfc_2000',...
%'hf04_P4_v1_1500_M12_mpfc_1500',...

%'hf04_P4_v1_ca1_1600_M12_mpfc_1600',...
'hf04_P4_v1_ca1_2300_M12_mpfc_2000',...

'hf05_P4_v1_ca1_2000_M12_mpfc_2150',...
%'hf05_P4_v1_ca1_2000_M12_mpfc_1500',...
%'hf05_P4_v1_ca1_2000_M12_mpfc_1800',...

%'hf05_P4_ca11_1500_M12_mpfc_1500',...
'hf05_P4_ca11_2500_M12_mpfc_2500'
};

%% Files
files = setdiff([files_depth(:) ; files_others(:)],files_hpc);
files = fn_from_fn(files);

files =  [files_laminar(:) ; files_depth(:) ; files_others(:) ; files_hpc(:)];
files = unique(files);
files = fn_from_fn(files);
