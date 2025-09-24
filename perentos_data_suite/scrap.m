% temporary scrap

%% run a function over natalias sub-database
importPupilDLC

%% RUN ANY FUNCTION ACROSS ALL OF NATALIAS SESSIONS
clear;close all;
i_Sessions =  [ 2 6 7 12 16 17 18 29 30 33 36 38 41 44 ...
    46 47 51 56 57 59 62 70 73 83 87 99 101 109 112 115 132 ...
    134 137 139 147 155 161 163 165 168 177 190 197 200 203 206 ];
i_Sessions = sort(i_Sessions);
excluded = [1 3 123];

%i_Sessions =  i_Sessions_all(1:23);
% i_Sessions =  i_Sessions_all(24:end);


T = getCarouselDataBase;        
allFileBases = [T.session(i_Sessions)];
clear ErrorLog exception msgText;
set(0,'DefaultFigureVisible','on');
for i = 1:length(i_Sessions)%:-1:35
    close all;  
    fileBase = T.session{i_Sessions(i)};
    try         
        display(['processing ',num2str(i), ' out of ', num2str(length(i_Sessions)), '  : ',fileBase]);
%         if strcmp(fileBase, 'NP39_2019-11-21_11-44-59')
%             continue;
%         end        
        % importDLC(fileBase);  % reran on Oct 2 for i_Sessions
        % getVidVars(fileBase); % reran on Oct 2 for i_Sessions
        % generateAuxVars(fileBase);      
        % combineVidAuxVars(fileBase);
        %updateSession(fileBase);
        %getBehTrialMatrices(fileBase);
        displayFrames(fileBase);
        %importPupilDLC(fileBase);
    catch exception
        ErrorLog{i,1} = T.session{i_Sessions(i)};
        ErrorLog{i,2} = getReport(exception);
        warning('a file was skipped due to an error - check ErrorLog');
        disp(ErrorLog{i,2})        
    end       
    fprintf('\n\n\n');
end
close;








%%
fldrs = {'NP26_2019-04-13_18-37-56','NP26_2019-04-13_19-48-39',...
         'NP26_2019-04-13_20-19-36','NP26_2019-04-13_21-19-36'};
     
     
     
cd('/storage2/perentos/data/recordings/NP26/NP26_2019-04-13_18-37-56');   
fle = '100_ADC1.continuous';

cd('/storage2/perentos/data/recordings/NP4/NP4_2018-03-02_16-26-27');
fle = '100_CH23.continuous';

MakeEvt(cand(1,:)',[fle,'_rpl.evt'],Labels,SampleRate,Overwrite)
str='rpl';Labels = repmat({str},1,length(cand)); 


     d=0:10:350;
     D=[];
     V=[];
     for i=1:length(d)
       n=d(i)/10;
       D=[D ones(1,n)*d(i)];
       V=[V 1:n];
     end

     figure
     wind_rose(D,V)

     figure
     wind_rose(D,V,'iflip',1)

     figure
     wind_rose(D,V,'ri',0.9); % 'ci',[1 2 7],'dtype','meteo',

     
     
     
     % make sure your KS directory lives inside the processed folder of the
     % session
     filebase = 'NP26_2019-04-13_18-37-56';
     KSD = 

     
     %% overlay carousel location with speed
     % need to remove stationary periods at start point for place cell
     % analysis (I think) - maybe not needed as all PCs will appear to have
     % some bump around the start point 
     figure('pos',[53 28 3040 603]);
     ax(1) = subplot(211);
     plot(tScale,location,'linewidth',2); ylabel('location');axis tight;
     ax(2) = subplot(212);
     plot(tScale,carouselSpeed,'linewidth',2); ylabel('carousel speed'); axis tight;    
     linkaxes(ax,'x'); 

    % looks like spikes are in seconds and diiso is tScale and so is location
    % grab one example cluster - pick one that looks stripy to start with
    % e.g. 22
    clear spikeTimes;clf;
    spikeTimes = sp.st(sp.clu==28);
    
    binnedSpikes = histc(spikeTimes,tScale)';
    locEdges = linspace(0,max(location),360/5); % 5 degree dbins or 2*pi*25/(360/5)=2cm
    positionInd = discretize(location,locEdges);
    cellTuning = accumarray(positionInd',binnedSpikes,[numel(locEdges)-1,1],@mean)*1000;
    %subplot(p(1),p(2),i)
    plot(locEdges(1:end-1),cellTuning,'color',[.7 .7 .7]); hold on;
    plot(locEdges(1:end-1),smooth(cellTuning,3),'r'); axis tight;
    plot([1450 1450],ylim,'-b'); plot([2900 2900],ylim,'-b'); box off;%title(int2str(i));
    
    % check sniffing spectrum at the left and right locations - female vs
    % empty
    
    
    
    %% try to get changing direction location
    if size(ch,1) > size(ch,2); ch = ch'; end       
            % [pks,idxn]=findpeaks(ch,'MinPeakProminence',3000);
    idxl = ch>3e3;
    idx = [idxl(2:end),0];
    idxn = idx-idxl; 
    idxn(idxn==-1)=0;
    location = idxn;
    location(location == 0) = nan;
    
    % plot the location against time and the trigger points
    
    
    %% triggered spectrogram for licking around TTLs
    lickLP = eegfilt(licks,1000,0,50);
    clear options;
    options.defaults = 'theta';
    out = specmt(lickLP,options);
    figure;
    for j = 1:3
        tp = 13;% number of spectral time points to include        
        if j == 1; ev = rewards.atStart; end
        if j == 2; ev = rewards.atCW; end
        if j == 3; ev = rewards.atACW; end
        trigSp = zeros(length(ev),tp,size(out.Sxy,2));
        ev = tScale(ev);
        tSeg = out.t(1:tp)-out.t(round(tp/2));
        for i = 1:length(ev)        
            ts = knnsearch(out.t,ev(i));
            trigSp(i,:,:) = out.Sxy(ts-floor(tp/2):ts+floor(tp/2),:);
        end
        sp(j) = subplot(3,1,j);
        imagesc(tSeg,out.f,squeeze(mean(trigSp(:,:,:),1))');
        colorbar;
    end
    
  
    % post hoc position during TTL points
    location(rewards.atCW)
    
    % session spectrogram for pyr channel
    clear options;
    options.defaults = 'theta';
    mu = mean(data(2:16,:),1);
    out = specmt(data(3,:)-mu,options);
    figure; 
    %LFP
    sp(1) = subplot(311);
    imagesc(out.t',out.f',log(out.Sxy)');
    set(gca,'tickdir','out');set(gca,'ticklength',[0.005 , 0.005]);
    % caxis([0 7000]);
    % plot([xlim],[6 6],'-.w');
    ylabel('frequency (Hz)');
    %ACh
    sp(2) = subplot(312);
    addpath(genpath('/storage/ricardo/code/'))
    FACh = FNormalize(ACh_ratiometric.ACh,5,1);
    yyaxis left
    plot(tScale,runSpeed);axis tight; ylabel('speed (cm/s)');    
    %ylim([-1 1]);
    yyaxis right;
    plot(ACh_ratiometric.tnorm, FACh);ylabel('ACh (\DeltaF/F_0)');
    ylim([-1 1]);
    set(gca,'tickdir','out');set(gca,'ticklength',[0.005 , 0.005]);
    sp(3) = subplot(313);
    tPupil = tScale(vidPulses == 1);
    tPupil(end-1:end) = [];
    plot(tPupil,res(:,1));
    axis tight;
    linkaxes(sp,'x');
    xlabel('time (s)'); ylabel('pupil size (pixels)');
    
    
    
    
cd('/storage2/perentos/data/recordings');    
% Get a list of all files and folders in this folder.
files = dir('NP*');
% Get a logical vector that tells which is a directory.
dirFlags = [files.isdir]
% Extract only those that are directories.
subFolders = files(dirFlags)
% mAnually remove 89 99 since they are not relevant
subFolders(end-1:end) = [];
% Print folder names to command window.
fldrs = [];
for i = 1 : length(subFolders)
    cd('/storage2/perentos/data/recordings');
    cd(subFolders(i).name);
    tmp =  dir('NP*');
    fldrs = [fldrs; tmp];        
end



%% there is a special case for NP25 on the 2nd of June (and probably others around
% the same data where one direction had double pulse at the position of the
% single pulse. Thankfully this double pulse was actually different
% qualitatively to the true double pulse at the start. It haad its first
% pulse double the duration and the second normal duration. Despite this we
% can simply detect consecutive double pulses and rebaptise the second pair
% as a single pulse. 
newRe = [2*ones(1,length(rewards.atStart)), 1*ones(1,length(rewards.atACW)), 3*ones(1,length(rewards.atCW))];
tmp = [rewards.atStart;rewards.atACW;rewards.atCW];
newRe = [newRe;tmp'];
[~,idx] = sort(newRe(2,:));% get indices of events sorted in time
newRe = newRe(:,idx);% sort in time
% find consecutive 2s where the second one is supposed to be one
twos = find(newRe(1,:)==2);% ind of twos
ch = 1+find(diff(twos) == 1);% ind of indices to change to 
newRe(1,twos(ch))= 1;

rewards.atStart = newRe(2,newRe(1,:)==2)'; % two pulses - arrive at start point
rewards.atCW = newRe(2,newRe(1,:)==3)';    % three pulses - at RHS (aka CW rotation) 
rewards.atACW = newRe(2,newRe(1,:)==1)';  % one pulse - at LHS (aka ACW rotation)


% plot speeds and location
figure; 
h(1) = subplot(311); plot(tScale,location);title('location');
h(2)=subplot(312); plot(tScale,runSpeed);title('run speed');
h(3)=subplot(313); plot(tScale,carouselSpeed);title('carousel speed');
linkaxes(h,'x');



% another special case is where this recording is interrupted without
% forcing the animal to run back to the start. When the files are joint
% together the location counter does not reset back to zero. Therefore we
% need to do this manually for this particular case... In the future, make
% sure you force the animal to run to the start location before
% interrupting the recording by pressing 'q'.
% assuming location has been computed and is in workspace
% I manually identified the interval where the error occurs
%location(1108+4009251 : 10562+4009251) = location(1108+4009251 : 10562+4009251)-location(1108+4009251);
location(1108+4009251 : 4019415) = location(1108+4009251 : 4019415)-location(1108+4009251);

% with corrected location as per above, we now also need to account for the
% direction of rotation. We already have a function for that but it will
% probably break because of the special case midway due to joining of
% files. MUST AVOID SPLIT FILES AT ALL COSTS!!!!
%nan(1,length(location));
% find the center points that are preceeded by a single pulse.
newRe = [2*ones(1,length(rewards.atStart)), 1*ones(1,length(rewards.atACW)), 3*ones(1,length(rewards.atCW))];
tmp = [rewards.atStart;rewards.atACW;rewards.atCW];
newRe = [newRe;tmp'];
[~,idx] = sort(newRe(2,:));% get indices of events sorted in time
newRe = newRe(:,idx);% sort in time
cpts = find(newRe(1,:) == 2);% find centerpoints
% cycle through centerpoints to find CW and ACW and change the values 
direction = location;
for i = 1:length(cpts)
    if newRe(1,cpts(i)-1) == 1 % ACW movement passing through LHS first
        if i == 1
            direction(1:newRe(2,cpts(i))) = location(1:newRe(2,cpts(i)))*(-1);
        else
            direction(newRe(2,cpts(i-1)):newRe(2,cpts(i))+3) = location(newRe(2,cpts(i-1)):(newRe(2,cpts(i))+3))*(-1);
        end
    end
end
figure; h(1) = subplot(211);plot(location); hold on; 
        h(2) = subplot(212);plot(direction);
        linkaxes(h,'x');
xlim([2780409.63205095          2780579.76355648]);
% cptsPrev = cpts - 1;
% ACW = find(newRe(1,cptsPrev) == 1);
% CW =  find(newRe(1,cptsPrev) == 3);


% extract the datenum from the OE string
tt = 'NP48_2019-12-14_18-02-56'
%discover the starting poiint of the data by finding the first underscore
o = strfind(tt,'_'); o = o(1)+1;
dtn = datenum(tt(o:end),'yyyy-mm-dd_HH-MM-SS')


%% CREATE A MAP FOR EACH SESSION AND CONVERT TO DAT 
%   Note: It looks like when there is 2 probes the EEGs were in the middle
%   65-95 whereas if a single probe was used it looks like EEG was always 1-32
%   The following should take care of this but better to always visualise
%   the data after conversion because there might be exceptions!!!!!!!!!
%   we account for two HS order scenarios   P1+EEG+P2  or  EEG+P1
% 
% read mappings from excel for conversion purposes
%T = readtable('/storage2/perentos/data/recordings/animals_and_recording_session_particulars.xlsx','Sheet','AnalysisVars');
T = readtable('/storage2/perentos/data/recordings/GOODCOPY_animals_and_recording_session_particulars.xlsx','Sheet','AnalysisVars');

for i = [121 130 128]%70%1:height(T)
    display(['processing ',num2str(i), ' out of ', num2str(height(T))])
    
% ADC channel numbers % ADC is not needed as it defaults to the end of the file
    str = T.ADC{i};
    del = strfind(str,'-'); 
    if del ~= 1
        fr = str2num(str(1:del-1));
        to = str2num(str(del+1:end)); 
        ADC = fr:to;
    else
        display('there is  no ADC in this recording session');
        ADC = []; 
    end
        
% P1 channels assuming Probe 1 is at 1-64
    if sum(strcmp(fields(oemaps),T.Probe1{i}))
        P1 = oemaps.(T.Probe1{i})+0;
        display(['probe 1 is: ', T.Probe1{i}]); 
    else
        display('probe 1 is: NONE');
        P1 = [];
    end
    
% P2 channels assuming Probe 2 is at 97-160
    if sum(strcmp(fields(oemaps),T.Probe2{i}))
        P2 = oemaps.(T.Probe2{i})+32+64;
        display(['probe 2 is: ', T.Probe2{i}]); 
        EEGofs = 64; % if two probes, EEG was on second HS (preceded by 64)
    else
        display('probe 2 is: NONE');
        P2 = [];
        EEGofs = 0; % if single probe, EEG was on first HS (1-32)
    end

% EEG channel numbers
    str = T.EEG{i};
    del = strfind(str,'-'); 
    if del ~= 1
        fr = str2num(str(1:del-1));
        to = str2num(str(del+1:end)); 
        EEG = [fr:to]+EEGofs;
    else
        display('there is  no EEG in this recording session');
        EEG = [];
    end     
    
% FINAL MAP
if isempty(P2) 
    % only one probe was used - expectation then is that P1 is at 33-96 so that one can use 
    % the PI microdrive. But perhaps also the cable was swapped so then P1
    % would be at 1-64
    map = [P1+32 EEG]; 
else
    map = [P1 P2 EEG]; 
end

% convert data
    convertData(T.Session{i},map);
    clear map
end


%% write contents of the xlsx file to a text file for DLC to use
fid = fopen('/storage2/perentos/data/recordings/DLCpaths.txt','w');
for jj = 1 : height(T)
    fprintf(num2str(jj));
    fle = dir(fullfile(getFullPath(T.Session{jj}),'video/top*.avi'));
    if length(fle) == 1
        %fprintf( fid, '%s\n', ['''',fullfile(fle.folder,fle.name),'''']);
        fprintf( fid, '%s\n', fullfile(fle.folder,fle.name));
    end    
    if jj<10; fprintf('\b'); else; fprintf('\b\b'); end
    %pause(0.2);
end
fclose(fid); fprintf('\n');


%% spike sort the database - MUST RUN ON SPIKESORTER!
%T = readtable('/storage2/perentos/data/recordings/animals_and_recording_session_particulars.xlsx','Sheet','AnalysisVars');
T = getCarouselDataBase; 
display(['processing ',num2str(i), ' out of ', num2str(height(T)), '. fileBase is: ', T.session{i}]);
for i = 51 
    cont = 1;
    cd(getfullpath(T.session{i}));
    if ~isempty(str2num(char(T.KS_good(i)))) || exist(fullfile(pwd,'rez2.mat'))        
        display('YOU ALREADY RAN KILOSORT ON THIS SESSION!!!!!');
        prompt = 'Do you really want to rerun? Y/N [Y]: ';
        str = input(prompt,'s');
        if strcmp(str,'Y') ||  strcmp(str,'y')
            cont = 1;                        
            delete('amplitudes.npy','channel_map.npy','channel_positions.npy','cluster_Amplitude.tsv','cluster_ContamPct.tsv','cluster_group.tsv','cluster_info.tsv','cluster_KSLabel.tsv','params.py','pc_feature_ind.npy',...
            'pc_features.npy','phy.log','rez2.mat','rez.mat','similar_templates.npy','spike_clusters.npy','spike_templates.npy','spike_times.npy','template_feature_ind.npy','template_features.npy','templates_ind.npy',...
            'templates.npy','whitening_mat_inv.npy','whitening_mat.npy');
        else 
            cont = 0;
        end
    end
    % now run kilosort
    if cont
        % in case already sorted and are about to resort delete files...
        master_kilosort(T.session{i});
        load(fullfile(getfullpath(T.session{i}),'rez2.mat'));
        %T.KS_good(i) = sum(rez.good);
        disp([int2str(sum(rez.good)),' putatively good clusters identified for session ',T.session{i}]);
        %writetable(T,'/storage2/perentos/data/recordings/animals_and_recording_session_particulars.xlsx','Sheet','AnalysisVars')
    end
end
                                                                                                

%% lets do something messy: go through database and move KS folder contents into the processed folder and  delete KS folder
T = readtable('/storage2/perentos/data/recordings/animals_and_recording_session_particulars.xlsx','Sheet','AnalysisVars');
display('moving KS folder contents into processed folder and delete KS folder...');
for i = 3:height(T)
    display(['processing ',num2str(i), ' out of ', num2str(height(T)), '. fileBase is: ', T.Session{i}])
    contents = dir(fullfile(getfullpath(T.Session{i}),'KS'));
    if length(contents) > 2
        for j = 3:length(contents)
            if strcmp(contents(j).name, [T.Session{i},'.dat'])
                display(['deleting link to dat file: ',T.Session{i},'.dat'])
                %waitforbuttonpress
                delete(fullfile(contents(j).folder,contents(j).name))
            else
                display(['moving: ',contents(j).name, ' to processed folder'])
                movefile(fullfile(contents(j).folder,contents(j).name),...
                    fullfile(getfullpath(T.Session{i}),contents(j).name));
            end
        end
        rmdir(fullfile(getfullpath(T.Session{i}),'KS'));
    end
end



%% 
fileList = {'NP46_2019-12-04_12-21-28','NP46_2019-12-04_13-26-11'};
fileList = {'NP50_2020-07-01_18-37-04','NP50_2020-07-01_19-07-38'};

mergeDatFiles(fileList)


%% some code to merge datasets from the database
clear List;
T = readtable('/storage2/perentos/data/recordings/animals_and_recording_session_particulars.xlsx','Sheet','AnalysisVars');
% loop through the database's merge variable and find ones
j = 1; k = 1;
for i = 1:height(T)
   if T.merge(i) == 1 
       List(j).files(1) = T.Session(i);       
       flag = 1;
       while flag % keep incrementing until you find another zero
           try
               if T.merge(i+k) == k+1
                   List(j).files(k+1) = T.Session(i+k)
                   k = k + 1;
               else
                   flag = 0; k = 1; j = j + 1;
               end
           catch
               display(['reached the end ', num2str(k+i)]);
               flag = 0;
           end               
       end
   end
end
% now merge according to the lists generated    
for i = 1: length(List)
    mergeDatFiles(List(i).files)
end
       
       
%% use this for batch initialisation of video analysis
%T = readtable('/storage2/perentos/data/recordings/animals_and_recording_session_particulars.xlsx','Sheet','AnalysisVars');
T = readtable('/storage2/perentos/data/recordings/GOODCOPY_animals_and_recording_session_particulars.xlsx','Sheet','AnalysisVars');
for i = 106%1:height(T)
    if strcmp('merged',T.Session{i}(end-5:end))
        display('skipping merged folder since it doesnt have videos');
        continue;
    end
    fileBase = T.Session{i};
    display(['processing ',num2str(i), ' out of ', num2str(height(T)), '. fileBase is: ', T.Session{i}])
    trackPupilMorpho(fileBase,1,0); % initialise pupil detection
    frameDiffROIs(fileBase,1,0);    % initialise face ROIs
end
       
       
       
%% visualise speed and stopping split by trial
fileBase = 'NP46_2019-12-02_18-47-02';
cd(getfullpath(fileBase))
load peripheralsPP.mat;
% lets manually correct the speed so that no negative values are there
ppp(2,ppp(2,:)<0)=0;
ppp(2,ppp(3,:)<0)=0;

clrVar = {'run speed (cm/s)', 'carousel speed (cm/s)', 'pupilDiam', 'licking', 'respiration rate'};
varIdx = [2 3 6 7 8 11 14 15];
idxTrials = ppp(17,:);

close all;
for j = 1:numel(varIdx)    
    x = ppp(varIdx(j),:);
    l = 0;
    for i = 1:max(idxTrials)
        tmp = x(find(idxTrials == i));
        if length(tmp) < 2*60*1000
            xi{i} = tmp;
            l = max([l,length(tmp)]);
        end
    end
    [M, TF] = padcat(xi{:});
    t = linspace(0,length(M)/1000,length(M));
    subplotfit(j,numel(varIdx));
    imAlpha=ones(size(M));
    imAlpha(isnan(M))=0;
    imagesc(t,[],M,'AlphaData',imAlpha); axis xy;
    caxis([prctile(M(:),1) prctile(M(:),99)]);
    %imagesc(t,[],M); axis xy;
    clb=colorbar;xlabel(clb,pppNames(varIdx(j)));
    xlabel('time (s)'); ylabel('trial (#)');
    set(gca,'color',0.5*[1 1 1]);
end

% correlate the running speed with the carousel speed (for movement
% periods)
CC = corrcoef(ppp(2,ppp(17,:)>0),ppp(3,ppp(17,:)>0)); CC = CC(1,2);
figure;
scatter(ppp(2,ppp(17,:)>0),ppp(3,ppp(17,:)>0),1,'.k');
xlabel('run speed'); ylabel('carousel speed');
x = ppp(2,ppp(17,:)>0);
y = ppp(3,ppp(17,:)>0);

% we cal also define manually a period where the two are coupled but not
% necessarily restricting the data to carousel movement periods only. That
% is to say to include zero speed  in the mix as well as low speed for
% running just before engaging the carousel due to delay with software and
% motor inertial
figure; 
%plot(carouselSpeed)
scatter(ppp(2,6.593e5:1.393e6),ppp(3,6.593e5:1.393e6),1,'.k');
x = ppp(2,6.593e5:1.393e6); y = ppp(3,6.593e5:1.393e6);
clf; 
xbins = [0:1:80];
ybins = [0:1:20];
[Out, XBins, YBins, Pos] = hist2([x;y]',xbins,ybins);
Data = Out'./sum(Out(:));
figure; imagesc(XBins,YBins,Data); axis xy;
clb = colorbar; xlabel(clb,'probability');
caxis([0 prctile(Data(:),99.7)]);
xlabel('run speed'); ylabel('carousel speed');

% run and carousel speed crosscorrelations
[r,lags] = xcorr((ppp(2,6.9e5:1.5e6)),(ppp(3,6.9e5:1.5e6)),1000);
[r,lags] = xcorr(normalize_array1(ppp(2,6.9e5:1.5e6)),normalize_array1(ppp(3,6.9e5:1.5e6)),1000);

%plot(HFStates.t,HFStates.varsNormalised(:,[2 4]));legend('run speed','carousel speed');
figure; plot(ppp(2,:)); hold on; plot(ppp(3,:));
figure; plot(normalize_array1(ppp(2,6.9e5:1.5e6))); hold on; plot(normalize_array1(ppp(3,6.9e5:1.5e6)));

%% Fit: 'untitled fit 1'.
[xData, yData] = prepareCurveData( x, y );

% Set up fittype and options.
ft = fittype( 'exp2' );
opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
opts.Display = 'Off';
opts.StartPoint = [22.1757379993439 -0.0025595636204211 -22.2372996109875 -0.0420712958899869];

% Fit model to data.
[fitresult, gof] = fit( xData, yData, ft, opts );

% Plot fit with data.
figure( 'Name', 'untitled fit 1' );
h = plot( fitresult, xData, yData );
legend( h, 'y vs. x', 'untitled fit 1', 'Location', 'NorthEast' );
% Label axes
xlabel x
ylabel y
grid on


%% this will use tun (place tuning) structure to generate the population place activity sorted by position

% pick good cells FR>1, SSI>0.2, CC > 0.5
fileBase = 'NP46_2019-12-02_18-47-02';
cd(getfullpath(fileBase));
load([fileBase,'.tun.mat']);%load place_cell_tunings.mat;
figure('pos',[10 10 1000 400]);
subplot(131); histogram([tun(:).SSI]);      title('SSI'); axis tight;
subplot(132); histogram([tun(:).meanFR]);   title('firing rate'); axis tight;
subplot(133); histogram([tun(:).CC]);       title('trial cross correlation'); axis tight;
mtit('population characteristics - all putative units');
idx = find(([tun(:).SSI] > 0.2 &...
            [tun(:).meanFR] > 1.0 &...
            [tun(:).muCC] > 0.5) == 1);

M = [tun.cellTuningSm];
M = reshape(M,[size(tun(1).cellTunings,1),size(tun(1).cellTunings,2),length(M)/size(tun(1).cellTunings,2)]);        
M = M(:,:,idx);
C = M; % this will be the noise matrix (residuals)
% loop through selected cells and quickly vis
figure;
clm = flipud(colormap('gray'));
colormap(clm);
for i = 1:size(M,3)
    imagesc(M(:,:,i)')    
    axis xy;
    drawnow;pause(0.1);
end

M = squeeze(mean(M,2)); % average across trials
[~,I] = max(M,[],1); % find max position of each place field
[~,II] = sort(I); % get sorting order (early to late place field positions)
M = M-norm(M); % l2 norm of place fields (can also do z-score instead)
M=M(:,II); % sort by position
figure; 
imagesc(M')  

% between cell correlations of the residuals of the cells activities
whos mC

% lets start by keeping the first 50 trials b/c behavior was consistent
C = C(:,1:50,:);
% position-resolved mean of each putative cell
mC = squeeze(mean(C,2));
% remove mean responses from the individual trials
resC = C - permute(repmat(mC,[1,1,size(C,2)]),[1 3 2]);


%% the below is a clustering of a single neuron's trial-by-trial residuals correlation coefficient
% this works nicely. You can identify the clusters and then simlply go into
% the behavioral domain or other dynamics domain in the brain and ask if
% this form of clustering is reflected there. We will do this later, but
% first we should expand this type of analysis to the population.
CC = corrcoef(resC(:,:,15));
CC = CC-diag(diag(CC));

clus = clusterdata(CC,1);
[~,cluIdx] = sort(clus);

figure('pos',[2767 825 800 1218]); 
subplot(2,20,1); imagesc(clus);
subplot(2,20,[2:20]); imagesc(CC); axis square;
subplot(2,20,21); imagesc(clus(cluIdx));
subplot(2,20,[22:40]);  imagesc(CC(cluIdx,cluIdx)); axis square;

%% so, lets expand the above block (
whos resC

imagesc(reshape(permute(resC,[3 1 2]),size(resC,2)*size(resC,3),size(resC,1))'); xlim([0 119]);
imagesc(reshape(permute(C,[2 3 1]),size(C,2)*size(C,3),size(C,1))); ylim([119 240]); % correct apparently
imagesc(reshape(permute(C,[1 3 2]),size(C,1)*size(C,3),size(C,2))'); %xlim([119*49 119*50]); % also correct apparently

flatbread = reshape(permute(resC,[1 3 2]),size(resC,1)*size(resC,3),size(resC,2))'; 
figure; imagesc(flatbread);
flatbreadCor = corrcoef(flatbread);
flatbreadCor = flatbreadCor - diag(diag(flatbreadCor));
figure; imagesc(flatbreadCor);
clus = clusterdata(triu(flatbreadCor),2);
[~,cluIdx] = sort(clus);
figure('pos',[2767 825 800 1218]); subplot(2,20,1); imagesc(clus);
subplot(2,20,[2:20]); imagesc(flatbreadCor); axis square;
subplot(2,20,21); imagesc(clus(cluIdx));
subplot(2,20,[22:40]);  imagesc(flatbreadCor(cluIdx,cluIdx)); axis square;

colorbar
%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% BELOW REPEATS THE ABOVE BUT CHANGING VARIABLES TO BE MORE MEANINGFUL AND TIDIES UP VARIOUS THINGS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% select subset of 'good' place cells
    % close all;
    fileBase = 'NP46_2019-12-02_18-47-02';
    cd(getfullpath(fileBase));
    load place_cell_tunings.mat;
    figure('pos',[10 10 1000 400]);
    subplot(131); histogram([tun(:).SSI]);      title('SSI'); axis tight;
    subplot(132); histogram([tun(:).meanFR]);   title('firing rate'); axis tight;
    subplot(133); histogram([tun(:).CC]);       title('trial cross correlation'); axis tight;
    mtit('population characteristics - all pputative units');
    % lims
    SSI_lim = 0.1; meanFR_lim = 0.1; muCC_lim = 0.1; tpe = [2];
    idx = find(([tun(:).SSI]    > SSI_lim &...
                [tun(:).muFR] > 0.2 & ... % [tun(:).meanFR] < 5 &
                [tun(:).cellType] > 1 & ... 
                [tun(:).muCC]   > muCC_lim) == 1);
    idx_cluIDs = [tun(idx).cellID];
    % use nq structure to get the shank number for each cluster
    load([fileBase,'.nq.mat']);
    
    
    fprintf('\nA subset of %0.0f units were selected\n',length(idx));

    M = [tun.cellTuningSm];
    allM = reshape(M,[size(tun(1).cellTunings,1),size(tun(1).cellTunings,2),length(M)/size(tun(1).cellTunings,2)]);        
    subM = allM(:,:,idx); 
    % eliminate last trial since it is empty - is this general?    
    subM = subM(:,1:end-1,:); 
    
    
    % trim to first half of experiment
    nTrKeep = 1:119; subM = subM(:,nTrKeep,:);         
    clear M;
    
    % visualise your subselection of cells
    [shnk,shnk_srt] = sort(nq.cluAnatGroup(find(ismember(nq.cids,idx_cluIDs))));
    if 1 == 1
        figure; clm = flipud(colormap('gray')); colormap(clm);        
        for i = 1:size(subM,3)
            subplotfit(i,size(subM,3));
            imagesc(subM(:,:,shnk_srt(i))'); hold on;
            %plot([xlim],[40 40],'r');
            plot([xlim],[60 60],'r');
            axis xy;axis tight; %axis off;
            text(10,10,[num2str(shnk(i)),'-', num2str(tun(shnk_srt(i)).cellID)],'color','r','fontsize',18,'FontWeight','bold');
        end
    end

    
%% sub population resolved by position (shows place cells coverage)

    pop_coverage = squeeze(mean(subM,2)); % average across trials [position x cell]
    [~,I] = max(pop_coverage,[],1); % find max position of each place field
    [~,II] = sort(I); % get sorting order (early to late place field positions)    
    pop_coverage = pop_coverage; % ./max(pop_coverage,[],1)
    pop_coverage = pop_coverage(:,II); % sort by position
    figure('pos',[2767 1425 1139 1250]);
    %
    subplot(211);
    imagesc(linspace(0,360,size(pop_coverage,1)),[],pop_coverage'); clb = colorbar; xlabel(clb,'activity (Hz)','fontsize',14);
    ylabel('putative unit (#)'); xlabel('carousel angular position (^o)');
    %
    subplot(212);
    imagesc(linspace(0,360,size(pop_coverage,1)),[],(pop_coverage./max(pop_coverage,[],1))'); clb = colorbar; xlabel(clb,'activity (normalised)','fontsize',14);
    ylabel('putative unit (#)'); xlabel('carousel angular position (^o)');
    
    mtit(['(sub)population coverage with SSI>', num2str(SSI_lim,'%0.2f'), ...
           ' FR>',num2str(meanFR_lim,'%0.2f'),...
           ' mean trial-by-trial correlation>', num2str(muCC_lim, '%0.2f')]);

       
%% lets cluster single neuron responses across trials (examples to help explain the procedure)
%close all;
    C = subM;
    
    % position-resolved mean of each putative cell
    mC = squeeze(mean(C,2));
    % remove mean responses from the individual trials
    noise = C - permute(repmat(mC,[1,1,size(C,2)]),[1 3 2]);
    
    cl = [16,48,54]; incr = 1; row = 3; col = 5;
    % example cells
    figure('pos',[1767        1128        2424         948]); 
    for i = 1:numel(cl)
    %cell response
        subplot(row,col,incr); 
        imagesc(C(:,:,cl(i))');  incr = incr + 1;
        title('cell response'); ylabel('putative unit (#)'); xlabel('carousel angular position (^o)');
    %cell noise respose
        subplot(row,col,incr); imagesc(noise(:,:,cl(i))'); incr = incr + 1;
        title('cell ''noise'' (x_i-E(x))'); ylabel('putative unit (#)'); xlabel('carousel angular position (^o)');

        CC = corrcoef(noise(:,:,cl(i)));
        CC = CC-diag(diag(CC));
        clus = clusterdata(CC,4); uclu = unique(clus); tmp = histc(clus,uclu); [~,tmp2] = sort(tmp);
        [~,cluIdx] = sort(clus);
    %trial by trial crosscorrelation of noise matrix
        subplot(row,col,incr); imagesc(CC);  axis square; incr = incr + 1;
        title('NoiseCor_{(trX,trY)}'); ylabel('trial (#)'); xlabel('trial (#)');
    %cluster ID
        lbls = [repmat(clus,1,3), nan(length(clus),3), repmat(clus(cluIdx),1,3)];
        imAlpha=ones(size(lbls));
        imAlpha(isnan(lbls))=0;
        h = subplot(row,col,incr); im = imagesc(lbls,'AlphaData',imAlpha); 
        axis 'tight'; box off;      incr = incr + 1; %axis 'equal';
        ylabel('clu ID'); set(gca,'xticklabel',[],'yticklabel',[]);
        
    %trial by trial crosscorelation of noise matrix sorter by cluster ID
        subplot(row,col,incr); imagesc(CC(cluIdx,cluIdx));  axis square; incr = incr + 1;
        title('clustered NoiseCor_{(trX,trY)}'); ylabel('trial (#)'); xlabel('trial (#)');
    end
    axes('pos',[0 0 1 1]);
    text(0.02,.8,['cell #1']); 
    text(0.02,.5,['cell #2']); 
    text(0.02,.2,['cell #3']); set(gca,'visible','off');

    figure; 
    subplot(211); imagesc(zscore(noise(:,:,cl(1)))'); h1 = gca; colorbar; cx = caxis;
    subplot(212); imagesc(zscore(noise(:,:,cl(2)))'); h2 = gca; colorbar; cx = max([cx;caxis],[],1);
    caxis(h1,cx); caxis(h2,cx);
        
    % test = corrcoef(zscore(noise(:,:,cl(1)))',zscore(noise(:,:,cl(2)))');
    % figure; imagesc(test); colorbar

    A = subM(:,:,cl(1));Az = zscore(A); AzT = zscore(A');
    B = subM(:,:,cl(3));Bz = zscore(B); BzT = zscore(B');
    figure;
    subplot(321); imagesc(A'); title('raw');colorbar; subplot(323);imagesc(Az');title('zscore each trial'); colorbar; subplot(325);imagesc(AzT);title('zscore each position bin'); colorbar
    subplot(322); imagesc(B'); title('raw');colorbar; subplot(324);imagesc(Bz');title('zscore each trial'); colorbar; subplot(326);imagesc(BzT);title('zscore each position bin');colorbar
    figure;
    subplot(121); imagesc(noise(:,:,cl(1))'); colorbar;
    subplot(122); imagesc(noise(:,:,cl(3))'); colorbar;
  
%% cluster the population noise responses flatten position with cell
    % lets concatenate all cells into the second dimension so that the second 
    % dimension then becomes position by cell multiplexed across cells
    noiseZ = zeros(size(noise));
    for i = 1:size(noiseZ,3)
        noiseZ(:,:,i) = zscore(noise(:,:,i));
    end
    % flatNoise = reshape(permute(noise,[1 3 2]),size(noise,1)*size(noise,3),size(noise,2))'; 
    flatNoise = reshape(permute(noiseZ,[1 3 2]),size(noiseZ,1)*size(noiseZ,3),size(noiseZ,2))'; 
    figure; imagesc(flatNoise); 
    xlabel('position by cell (concatenated cells)');
    ylabel('trial (#)');

    % lets take the first 50 trials since there is some transition at 60

    figure; imagesc(flatNoise);

    flatNoiseCor = corrcoef(flatNoise');
    flatNoiseCor = flatNoiseCor - diag(diag(flatNoiseCor));
    clus = clusterdata(flatNoiseCor,3);
    
    [~,cluIdx] = sort(clus);
    figure('pos',[2767 825 800 1218]); subplot(2,20,1); imagesc(clus);
    subplot(2,20,[2:20]); imagesc(flatNoiseCor); xlabel('trial (#)'); ylabel('trial (#)');axis square; colorbar;
    subplot(2,20,21); imagesc(clus(cluIdx));
    subplot(2,20,[22:40]);  imagesc(flatNoiseCor(cluIdx,cluIdx)); axis square; xlabel('trial (#)'); ylabel('trial (#)'); colorbar;
    mtit('noise correlation - position and cell dimensions collapsed');
    
%% lets try to use indivisual steps instead of using the clusterdata
    % function
    figure; 
    flatNoiseCor = corrcoef(flatNoise');
    tmp = flatNoiseCor - diag(diag(flatNoiseCor));
    subplot(221); imagesc(tmp);title('noiseCor'); colorbar;    
    corrMat = flatNoiseCor - eye(size(flatNoiseCor));
    % EYE(X) IS THE SAME AS DIAG(DIAG(X))
    subplot(222); imagesc(corrMat);title('eye corrected');colorbar;
    %Y = pdist(corrMat);
    Z = linkage(corrMat,'complete','cityblock'); %'correlation',    
    %c = cophenet(Z,Y);
    %I = inconsistent(Z); figure; imagesc(I);title('inconsistent')
    % cutoff = median([Z(end-2,3) Z(end-1,3)]); cutoff = 30; dendrogram(Z,0,'colorthreshold',cutoff);
    subplot(223);  
    nClu = 3;
    c = cluster(Z,'Maxclust',nClu); %  ,'cutoff',cutoff
    clr = Z(end-nClu+2,3)-eps;
    dendrogram(Z,0,'colorthreshold',clr);
    [~,cluIdxc] = sort(c);
    subplot(224); imagesc(corrMat(cluIdxc,cluIdxc)); hold on; 
    % find transitions
    [a,~] = find(diff(c(cluIdxc)) ~= 0);
    plot([a(i) a(i)],[ylim],'--k','LineWidth',3);
    plot(repmat(a,1,2)',repmat(ylim,2,1)','--k','LineWidth',3);
    plot(repmat(ylim,2,1)',repmat(a,1,2)','--k','LineWidth',3);
    colorbar;
    
%% cluster the population noise responses (take mean across position for each cell)
    % lets average the noise across the position dimension
    %flatNoise = squeeze(std(noise,[],1));
    flatNoise = squeeze(mean(noiseZ,1));

    % lets take the first 50 trials since there is some transition at 60

    figure; imagesc(flatNoise);
    xlabel('cell (#)');
    ylabel('trial (#)');

    flatNoiseCor = corrcoef(flatNoise');
    flatNoiseCor = flatNoiseCor - diag(diag(flatNoiseCor));

    clus = clusterdata(flatNoiseCor,4);
    [~,cluIdx] = sort(clus);
    figure('pos',[2767 825 800 1218]); subplot(2,20,1); imagesc(clus);
    subplot(2,20,[2:20]); imagesc(flatNoiseCor); axis square; colorbar;
    subplot(2,20,21); imagesc(clus(cluIdx));
    subplot(2,20,[22:40]);  imagesc(flatNoiseCor(cluIdx,cluIdx)); axis square; colorbar;
    mtit('noise correlation - position dimension anveraged for each cell');

%% noise correlation as a function of position ???




% WHEN YOU GLANCE AT THE RESIDUAL CORRELATION MATRICES WHAT YOU SEE IS THAT
% THERE IS A TIME RELATIONSHIPS IN THAT THE CLUSTERS THAT ARE GENERATE ARE
% SIMPLY SPLITS OF THE DATA DOWN THE MIDDLE SOMEWHERE
% SO IT LOOKS LIKE THIS METHOD OF LOOKING AT THE RESIDUALS DOES NOT LEAD TO
% SOME MEANINGFUL CLUSTERING OF THE TRIALS. THEREFORE IT DOESNT LOOK LIKE
% THERE IS SOME KIND OF GLOBAL EFFECT CONTROLLING SIMULTANEOUSLY ALL THE
% CELLS SO THAT THEY ALL SWITCH TOGETHER IN TRIALS.. More likely it looks
% like a drift of the representation

% PERHAPS WE NEED TO GO BACK TO INDIVIDUAL CELLS AND THERE WE SHOULD
% GENERATE CLUSTER LABELS FOR EACH CELL. THEN WE CAN CORRELATE THESE LABELS
% ACROSS CELLS? BU WE WILL NEED TO MATCH THE CLUSTER IDS FOR THIS TO WORK?


% notes from discussion with anton after showing him the above analysis
% the first main point is that due to the sparse activity of the place
% cells (although interneurons are the exception) if one takes the naive
% approach of computing noise correlations across the whole tuning curve
% you are including in there all the data that has zero spikes in it. But
% this is a very noise estimate(e.g. 2-3 spikes in 100 trials) because in 
% essence one can compute reliable statistics outside the place place field
% itself. If for example there is
% one spike in one trials, will that influence the analysis eventhough its
% essentially nothing statistically notable? But this is a secondary issue
% and further thought needs to go into it. The other more pressing issue is
% the fact that cells seem to come in and out of the representation so as a
% first step perhaps it is more important to identfy joint changes in the
% population signal (not noise) so that we can subdivide trials into
% groups. This could be realised using NMF followed by tSNE or other clustering
% method? 
% One can also bootstrap the data and repeat the NMF to find the significant 
% fields??
% another thing suggested is to go back to the spikes and plot the average
% waveforms on a per trial basis including the break periods. This might
% give us a sense of whether w are dealing with drift or something else?
% Another thing that's important to do is to present clusters according to
% their shank. Are the cells that remap belonging to a specific (subset) of
% shanks or one probe versus the other?





% below redoes the very first step of the above process but with a
% different indexing procedure which does not require making submatrices
% not sure if it will work better - LETS SEE!!
%% select subset of 'good' place cells
    clear;
    close all;
    fileBase = 'NP46_2019-12-02_18-47-02';
    cd(getfullpath(fileBase));
    load NP46_2019-12-02_18-47-02.tun.mat; % place_cell_tunings.mat;
    figure('pos',[10 10 1000 400]);
    subplot(131); histogram([tun(:).SSI]);      title('SSI'); axis tight;
    subplot(132); histogram([tun(:).muFR]);   title('firing rate'); axis tight;
    subplot(133); histogram([tun(:).CC]);       title('trial cross correlation'); axis tight;
    mtit('population characteristics - all putative units');
    % lims
    SSI_lim = 0.1; meanFR_lim = 0.05; muCC_lim = 0.4;
    idx = find(([tun(:).SSI]    > SSI_lim &...
                [tun(:).muFR] > 0.2 & ... % [tun(:).meanFR] < 5 &
                [tun(:).cellType] == 2 & ... % [tun(:).meanFR] < 5 &
                [tun(:).muCC]   > muCC_lim) == 1);
    idx_cluIDs = [tun(idx).cids];% was .cellID
    % use nq structure to get the shank number for each cluster
    load([fileBase,'.nq.mat']);
    
    nq_tmp = [nq.cids,nq.cluAnatGroup];
    
    fprintf('\nA subset of %0.0f units were selected\n',length(idx));

    M = [tun.tuningSm];% was cellTuningSm
    allM = reshape(M,[size(tun(1).tuning,1),size(tun(1).tuning,2),length(M)/size(tun(1).tuning,2)]);
    subM = allM(:,:,idx); 
    % eliminate last trial since it is empty - is this general?    
    subM = subM(:,1:end-1,:); 
    
    
    % trim to first half of experiment
    nTrKeep = 1:119; subM = subM(:,nTrKeep,:);         
    clear M;
    
%     % visualise your subselection of cells
%     % this works well with shank displayed correctly
%     % but its not ordered by shank which is desirable
%     %[shnk,shnk_srt] = sort(nq.cluAnatGroup(find(ismember(nq.cids,idx_cluIDs))));
%     if 1 == 1
%         figure; clm = flipud(colormap('gray')); colormap(clm);        
%         for i = 1:size(subM,3)
%             subplotfit(i,size(subM,3));
%             imagesc(subM(:,:,i)'); hold on;
%             %plot([xlim],[40 40],'r');
%             plot([xlim],[60 60],'r');
%             axis xy;axis tight; %axis off;
%             ii = find(nq_tmp(:,1) == idx_cluIDs(i));
%             text(10,10,['\color{red}',num2str(nq_tmp(ii,2)),'\color{black} ID',num2str(idx_cluIDs(i))],'color','r','fontsize',18,'FontWeight','bold');
%             
%         end
%     end
    
    % visualise your subselection of cells - SHANK ORDERED
    % this works well with shank displayed correctly
    load([fileBase,'.nq.mat']);
    nq_tmp = [nq.cids,nq.cluAnatGroup];
    cells = find(ismember(nq.cids,idx_cluIDs)); % the clusters of interest
    cellProp = nq_tmp(cells,:);
    [ii,iii] =  sort(cellProp(:,2));
    clr = distinguishable_colors(length(unique(cellProp(:,2))),[1 1 1; 0 0 0]);
    if 1 == 1
        figure; clm = flipud(colormap('gray')); colormap(clm);        
        for i = 1:size(subM,3)
            ax = subplotfit(i,size(subM,3));
            imagesc(subM(:,:,iii(i))'); hold on;
            %plot([xlim],[60 60],'r');
            axis xy;axis tight; %axis off;
            set(gca,'ycolor',clr(cellProp(iii(i),2),:),'xcolor',clr(cellProp(iii(i),2),:));
            ii = find(nq_tmp(:,1) == idx_cluIDs(i));
            text(90,20,[num2str(cellProp(iii(i),1))],'color','k','fontsize',12,'FontWeight','bold');
            %text(10,20,[num2str(cellProp(iii(i),2))],'color',clr(cellProp(iii(i),2),:),'FontWeight','bold','fontsize',18);                        
        end
    end
    
    
    
%% get smoothed firing rates 
ratestest = getFiringRates(fileBase,{'win',0.05,'units',idx_cluIDs});

% how about a simple PCA on the rates
r = ratestest; clear ratestest;
whos r
edit PCAvsNMF_place_field_decomposition.m


rmpath(genpath('/storage2/perentos/code/thirdParty/drtoolbox/techniques'))
[coeff, score, latent] = pca(r.r,'centered','off');
opt = statset('MaxIter',100,'Display','iter');
[W,H] = nnmf(r.r,4,'options',opt);

% lets plot the trials in PCA space
tS_start = 600; tS_stop = 1600;
[~,idx] = find(r.t>tS_start & r.t<tS_stop);

%% PCA traj
data = reshape(smooth(score(idx,1:3),6),size(data,1),size(data,2));
close all;plotTraj(data(:,1:3));

%% NMF traj
%data = normalize_array1(W(idx,:));
data = (W(idx,:));
data = reshape(smooth(data,8),size(data,1),size(data,2));

%% probabilistic pca?
tS_start = 600; tS_stop = 1600;
[~,idx] = find(r.t>tS_start & r.t<tS_stop);
rates = r.r(idx,:);
addpath(genpath('/storage2/perentos/code/thirdParty/drtoolbox/techniques'))
[mapped_data, mapping] = compute_mapping(rates, 'ProbPCA', 3);
plotTraj(mapped_data)

options = {'clr_var',colVar(idx),'style', 1};
plotTraj(mapped_data,options)

%%
close all;plotTraj(data(:,1:3));
%%
%spd = carouselGetVar(fileBase,{'runSpeed'},ppp,pppNames);
spd = carouselGetVar(fileBase,{'runSpeed'});
trialID = carouselGetVar(fileBase,{'idxTrials'});
tScale = carouselGetVar(fileBase,{'tScale'});
pos = carouselGetVar(fileBase,{'posDiscr'});

close all; figure;

% time
    ax(1) = subplot(221); 
    options = {'clr_var',[],'style', 1, 'ax',ax(1)};
    plotTraj(zscore(data(:,[1 2 3])),options);
    title('color is speed');
    
% speed
    subplot(222); colVar = interp1(tScale,spd,r.t);
    options = {'clr_var',colVar,'style', 1, 'ax',ax(1)};
    ax(2) = plotTraj(zscore(data(:,[1 2 3])),colVar(idx));
    title('color is position');
    
% trialID
    subplot(223); colVar = interp1(tScale,trialID,r.t);
    options = {'clr_var',colVar,'style', 1, 'ax',ax(1)};
    ax(3) = plotTraj(zscore(data(:,[1 2 3])),colVar(idx));
    title('color is trial ID');
    
% position
    subplot(224); colVar = interp1(tScale,pos,r.t);
    options = {'clr_var',colVar,'style', 1, 'ax',ax(1)};
    ax(3) = plotTraj(zscore(data(:,[1 2 3])),colVar(idx));
    title('position');

    
% to rotate stuff....
    for i = -360:5:360
        view(ax(1),70,i)
        view(ax(2),70,i)
        view(ax(3),70,i)
        view(ax(4),70,i)
        drawnow;
    end
% to rotate stuff....
    for i = 0:2:360
        view(i,36)
%         view(ax(2),70,i)
%         view(ax(3),70,i)
%         view(ax(4),70,i)
        drawnow;
    end







%% take responses of one cell and cluster them using kmeans
close all;figure;
test = subM(:,1:118,50)';
%imagesc(test);

% hierarchical clustering (not so good)
    subplot(321); imagesc(test); colorbar;
    cluD = clusterdata(test,2); [~,I] = sort(cluD);
    hold on; plot(cluD*10,[1:size(test,1)],'linewidth',2,'color','r');
    subplot(322); imagesc(test(I,:)); colorbar;
    

% kmeans clustering (better)
    subplot(323); imagesc(test); colorbar;
    cluK = kmeans(test,2); [~,I] = sort(cluK);
    hold on; plot(cluK*10,[1:size(test,1)],'linewidth',2,'color','r');
% flip the cluster IDs? (minimize norm)
    nrm1 = norm(vc([1:size(test,1)])-vc(I));
    % now flip the labels and try again
    cluK_n(cluK == 1)=2;
    cluK_n(cluK == 2)=1;
    [~,I] = sort(cluK_n);
    nrm2 = norm(vc([1:size(test,1)])-vc(I));
    if nrm2<nrm1
        cluK = cluK_n;
    end
    [~,I] = sort(cluK);
    subplot(324); imagesc(test(I,:)); colorbar;
    


% gaussian mixture on the nnmf-reduced matrix
    subplot(325);
    [W,H] = nnmf(test,4,'options',opt);
    test2 = W;
    imagesc(W*H); colorbar;
    gmfit = fitgmdist(test2,2,'CovarianceType','full','RegularizationValue',0.01);
    cluG = cluster(gmfit,test2);[~,I] = sort(cluG);
        hold on; plot(cluG*10,[1:size(test,1)],'linewidth',2,'color','r');

    nrm1 = norm(vc([1:size(test2,1)])-vc(I));
    cluG_n(cluG == 1)=2;
    cluG_n(cluG == 2)=1;
    [~,I] = sort(cluG_n);
    nrm2 = norm(vc([1:size(test2,1)])-vc(I));
    if nrm2<nrm1
        cluG = cluG_n;
    end
    [~,I] = sort(cluG); tmp = W*H;
    subplot(326); imagesc(tmp(I,:)); colorbar;
    %imagesc(test2(I,:)); colorbar;

    figure;
for i = 1:size(subM,3)
    imagesc(subM(:,:,i)');
    title(num2str(i));
    pause
end
    




%% this is for Christine
close all;figure;
ix = find([tun.cellID] == 514);
subplot(311); imagesc(tun(ix).cellTunings');
subplot(312); imagesc(tun(ix).cellTuningSm');
subplot(313); imagesc(tun(1).allTun(:,:,ix)');


%% shuffle correction for the spatial selectivity index
close all;
fileBase = 'NP46_2019-12-02_18-47-02';
cd(getfullpath(fileBase));
load place_cell_tunings.mat;

%HH=cell2mat(arrayfun(@(k) circshift(d(:,k),k),1:size(d,2),'uni',0));
shiftVar = randi(size(d,1),1,size(d,2));
HH=cell2mat(arrayfun(@(k) circshift(d(:,k),shiftVar),shiftVar,'uni',0));
subplot(211); imagesc(d');subplot(212); imagesc(HH');


%% 
clf;
d2 = d(:,[1:3]);
shiftVar = randi(size(d2,1),1,3);
HH=cell2mat(arrayfun(@(k) circshift(d2(:,k),shiftVar(k)),shiftVar,'uni',0));
clf; subplot(211); imagesc(d2');subplot(212); imagesc(HH');

d=d';
id=randi(size(d,2),1,size(d,1));
out=cell2mat(arrayfun(@(x) circshift(d(x,:),[1 id(x)]),(1:numel(id))','un',0));
clf; subplot(211); imagesc(d);subplot(212); imagesc(out);




%% blink loop?
fprintf('...');
for i = 1:1000
    pause(0.5);
    fprintf('\b');
    pause(0.5);
    fprintf('.');
end





%%
figure;
subplot(231); histogram(nq.centerMax); xlabel('nq.centerMax'); axis tight;
subplot(232); histogram(nq.spkWidthC); xlabel('nq.spkWidthC'); axis tight;
subplot(233); histogram(nq.spkWidthL); xlabel('nq.spkWidthL'); axis tight;
subplot(234); histogram(nq.spkWidthR); xlabel('nq.spkWidthR');axis tight;
subplot(235); histogram(nq.troughTime); xlabel('nq.troughTime');  axis tight;




%% cycle through the nq structure to visualise the fields since we are confused about the units 
% with regards to the spike width on the right side of the negative peak
close all;
        str = {'MUA','SUA'};
        for i = 2 % MUA and SUA
            figure;
            cells = find(nq.cgs == i);
            for j = 1:length(cells)
                %subplotfit(j,length(cells));
                shift = nq.troughTime(cells(j));%*SpkSamples/2*Sample2Msec;
                wv_tmp   = resample(nq.avSpk(cells(j),:),nq.ResCoef,1);
                wv_tmpSD = resample(nq.sdSpk(cells(j),:),nq.ResCoef,1);
                if nq.isPositive(cells(j)); cl = 'b'; ml = -1; display('ha!!'); else ml = 1;cl = 'k'; end
                shadedErrorBar(([1:nq.SpkSamples*nq.ResCoef]-shift)*nq.Sample2Msec,ml*wv_tmp(1:520),wv_tmpSD(1:520),cl);
                axis tight
                hold on
                Lines(0,[],'g');%trough line
                %Lines(halfAmpTimes*Sample2Msec-shift,amphalf,'r');
                plot((nq.halfAmpTimes(cells(j),:)-shift)*nq.Sample2Msec,repmat([0.5*nq.centerMax(cells(j))],1,2),'or');
                Lines(nq.spkWidthR(cells(j)),[],'r');
                Lines(-nq.spkWidthL(cells(j)),[],'r');
                %Lines([-SpkWidthL SpkWidthR], troughamp,'r');
                mystr1 = sprintf(['clu%d, sh%d'],nq.cids(cells(j)),nq.cluAnatGroup(cells(j)));
                mystr2 = sprintf(['%0.1fHz, spkWidthR%0.2fms'], nq.fr(cells(j)), nq.spkWidthR(cells(j))); % -nq.troughTime(cells(j))
                mystr3 = sprintf(['%0.1fms, spkWidthC%0.2fms'], nq.troughTime(cells(j)), nq.spkWidthC(cells(j)));
                %title(mystr);
                text(max(xlim)/2,.3*max(ylim),mystr1,'HorizontalAlignment','right');
                text(max(xlim)/2,.6*max(ylim),mystr2,'HorizontalAlignment','right');
                text(max(xlim)/2,.9*max(ylim),mystr3,'HorizontalAlignment','right');
                %set(gcf,'units','normalized','outerposition',[0 0 1 1]);      
                mtit(str{i}); drawnow;
                waitforbuttonpress;% pause;
                clf;
            end

            %print(gcf,[str{i},'_waveforms_all.jpg'],'-djpeg','-r300'); 
            
            
%             
% % track the pupil
% T = getCarouselDataBase;
% for i = 51
%      display(['processing ',num2str(i), ' out of ', num2str(height(T))])
%     fileBase = T.Session{i};
% disp('extracting pupil size and position...');
% trackPupilMorpho(fileBase,0,1);
% end
        end
        
        
        
        
        



%% pick a cell and resort its trials as a function of the activity of a behavioral variable
% import the peripherals and the tun1 structure
close all; clear all;
fileBase = 'NP46_2019-12-02_18-47-02';
cd(getfullpath(fileBase));
load peripheralsPP.mat
load ([fileBase,'.tun1.mat']); tun = tun1;
% lets start with the pupil
%carouselSpeed = carouselGetVar(fileBase,{'carouselSpeed'},ppp,pppNames);
%location = carouselGetVar(fileBase,{'posDiscr'},ppp,pppNames); %3degree bins...
idxMov = carouselGetVar(fileBase,{'idxMov'},ppp,pppNames); %3degree bins...
pos = carouselGetVar(fileBase,{'posDiscr'},ppp,pppNames); %3degree bins...
trialI = carouselGetVar(fileBase,{'idxTrials'},ppp,pppNames); %3degree bins...
%%
clearvars -except binCenters  idxMov posEdges pppNames tun fileBase pos ppp trial tun1;
var = carouselGetVar(fileBase,{'runSpeed'},ppp,pppNames); %3degree bins...
close all; clc;

% lets work with a single good place cell to begin with: e.g. cluster 
% cell 998 is a pretty stable place cell with a a single place field
ii = find(tun.cids == 924); % 924

% the nmf components of this place field:
nmfComp = sq(tun.PFStability(1).nmfW(ii,:,:));
% lets reject trials 1 60 and 120


% figure; imagesc(sq(tun.tuningSm(ii,:,trialSet))');
% hold on;
% plot(nmfComp*length(tun.PFStability(1).trials)/max(nmfComp(:)),'-.w','linewidth',2);
zNmfComp = zscore(nmfComp);
% lets manualy define an extent to the left and the right of the main place
[~, pk] = max(nmfComp(:,1));
extents = [pk-10:pk+10];
%spBins = [pk];
% crude way: average across these spatial bins ignoring dynamics and
% discontinuities
act = sq(tun.tuningSm(ii,extents,:));

trialSet = [1:120]; %trialSet([1 60 120])=[];
excl = [120];
trialSet(excl)=[];
act(:,excl) = [];



muAct = mean(act,1);
mxAct = max(act,[],1);
sdAct = std(act);


% now lets get the same thing for e.g. pupil size
for i = 1:length(trialSet)%length(unique(trial))-1
    %idx = intersect(find(trial == i), find(idxMov == 1));
    idx = intersect(find(trialI == trialSet(i)), find(idxMov == 1));
    tmpBins = find(pos >= extents(1) & pos <= extents(end));
    idx = intersect(idx, tmpBins); % the indices of trial 1 spent inside the spatial position around spatial position 41
    pupAct{i} = var(idx);
    sz(i) = length(pupAct{i});
    muPup(i)= mean(pupAct{i});
    sdPup(i)= std(pupAct{i});
    mxPup(i)= max(pupAct{i});
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% sort according to a chosen regressor
regr = mxPup;
[~,I] = sort(regr);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% contrast the field activity sorted vs unsorted just visually
figure('pos',[ 616         561         978        1416]);
subplot(511); imagesc(act); title('field activity');%axis square;
subplot(512); plot(mxAct); title('max field activity ');axis tight;

subplot(513); imagesc(act(:,I)); title('field activity (sorted by beh. variable)'); %axis square;
subplot(514); 
plot(mxAct(:,I)); hold on;
plot(muAct(:,I));
plot(sdAct(:,I));
legend('max','mean','sd');
title('field activity (sorted)'); %axis square;

subplot(515); title('regressor activity (sorted)'); hold on;%axis square;
plot(mxPup(:,I)); 
plot(muPup(:,I));
plot(sdPup(:,I));

set(findall(gcf, 'Type', 'Line'),'LineWidth',2);
%set(all_subplots(gcf),'linewidth',2, 'box','off','tickdir','out')


% or contrast the full map sorted by trial number or by pupil diameter
figure; 
subplot(211);
imagesc(sq(tun.tuningSm(ii,:,:))'); sc = caxis;
subplot(212);
imagesc(sq(tun.tuningSm(ii,:,I))'); caxis(sc);
figure('pos',[10 10 2284 456]); 
LM = fitlm(regr,mxAct)
subplot(131);plot(LM);title('max');
LM = fitlm(regr,muAct)
subplot(132);plot(LM);title('mean');
LM = fitlm(regr,sdAct)
subplot(133);plot(LM);title('sd');

%%






%% quick vis of frame difffs???????????//
fileBase = 'NP46_2019-12-02_18-47-02';
obj = VideoReader('/storage2/perentos/data/recordings/NP46/NP46_2019-12-02_18-47-02/video/side_cam_1_date_2019_12_02_time_18_46_54_v001.avi');
obj.CurrentTime = 30*11*60;
load frameDiffSide.mat
fr1 = rgb2gray(im2double(obj.readFrame));
tic;
disp('computing frame diff for all requested ROIs');
figure('pos',[ 6           9        1678         898]);
mxVal = prctile(out.diffWhole,99);
while hasFrame(obj) 
    fr2 = rgb2gray(im2double(obj.readFrame));
    i = obj.CurrentTime*obj.FrameRate;
    % subframes
    tmp = abs(fr2-fr1);
    subplot(132); bar(out.diffWhole(i));ylim([0 mxVal])
    subplot(131); imshow(fr2);
    subplot(133); imagesc(tmp); caxis([0 1]); axis equal; axis off;
    fr1 = fr2;
    drawnow; %pause(0.1);
end


%% lasso example
rng default % For reproducibility
X = randn(100,5);
weights = [0;2;0;-3;0]; % Only two nonzero coefficients
y = X*weights + randn(100,1)*0.1; % Small added noise



%% playing with ellipsoid and PCA to extract angle of a trajectory that lies on the circumference of the ellipse
clf;
angles = linspace(0, 2*pi, 360); % 720 is the total number of points
radius1 = 20;
radius2 = 10;
xCenter = 50;
yCenter = 40;
x = radius1 * cos(angles) + xCenter; 
y = radius2 * sin(angles) + yCenter;

zx = zscore(x);
zy = zscore(y);
scatter(zx, zy, 'b');
hold on;
scatter(x, y, 'b');

hold on;

rx = -2 + (2+2)*rand(1,length(x))
x =x + rx;
ry = -2 + (2+2)*rand(1,length(y))
y =y + ry;
% Plot circle.
scatter(x, y, '.r');
axis equal;

data = [x;y]';
whos data
[coeff, score, latent] = pca(data);
scatter(score(:,1), score(:,2), '.k');

[theta,rho]=cart2pol(score(:,1),score(:,2));





%% All video processing steps 
subFrameSVD(fileBase,varargin);   % subframe energies and SVD decomp
wholeFrameSVD(fileBase,varargin); % whole frame SVD
% track the nose
trackPupilMorpho(fileBase,init,track,frams)% track the pupil



%% image fft
fileBase = 'NP46_2019-12-02_18-47-02';
obj = VideoReader('/storage2/perentos/data/recordings/NP46/NP46_2019-12-02_18-47-02/video/top_cam_0_date_2019_12_02_time_18_46_55_v001.avi');
obj.CurrentTime = 30*11*60;
img = rgb2gray(im2double(obj.readFrame));
figure(1); imshow(img);
imgfftred = fftshift(fft2(img));
figure(5); surf(abs(imgfftred));
view(0,0);
shading interp;
imgfftgrey = fftshift(fft2(dgrey));
figure(6); surf(abs(imgfftgrey));
view(0,0);
shading interp;



%% how i started to build the gabor whisker tracking
% relevant links
% https://ch.mathworks.com/matlabcentral/answers/96963-what-functions-are-available-to-do-pattern-recognition-in-matlab
% not used here but still: https://ch.mathworks.com/help/images/registering-an-image-using-normalized-cross-correlation.html
% https://ch.mathworks.com/help/images/texture-segmentation-using-gabor-filters.html
% A = imread('kobi.png');
% A = imresize(A,0.25);
% Agray = rgb2gray(A);

fileBase = 'NP46_2019-12-02_18-47-02';
obj = VideoReader('/storage2/perentos/data/recordings/NP46/NP46_2019-12-02_18-47-02/video/top_cam_0_date_2019_12_02_time_18_46_55_v001.avi');
obj.CurrentTime = 30*11.5*60;
for i = 1:1000
    obj.CurrentTime = obj.CurrentTime + 10;
    A = rgb2gray(im2double(obj.readFrame));
    close all;
    %h=figure('pos',[900          54         477        1191]);
    a=[106 96 194 182];


    A = imcrop(A,a);
    Agray = A;%rgb2gray(A);
    %subplot(311);
    %imshow(A)



    imageSize = size(A);
    numRows = imageSize(1);
    numCols = imageSize(2);

    % wavelengthMin = 2;%4/sqrt(2);
    % wavelengthMax = hypot(numRows,numCols);
    % %n = floor(log2((wavelengthMax)/wavelengthMin));
    % n = floor(log2((wavelengthMax/20)/wavelengthMin));
    % wavelength = 2.^(0:(n-2)) * wavelengthMin;
    % 
    % deltaTheta = 45;
    % orientation = 0:deltaTheta:(180-deltaTheta);

    % hard coded values for understanding what is going on
    wavelength = [5]; orientation = [30:-15:-55];

    g = gabor(wavelength,orientation);


    gabormag = imgaborfilt(Agray,g);



    for i = 1:length(g)
        sigma = 0.5*g(i).Wavelength;
        K = 1;
        gabormag(:,:,i) = imgaussfilt(gabormag(:,:,i),K*sigma); 
    end


    % visualise gabor mags
    figure; cx = [0,0];
    for i = 1:size(gabormag,3)
     %   subplotfit(i,size(gabormag,3));
     %   imagesc(gabormag(:,:,i)); cx = [cx;caxis];
        sm(i) = sum(vc(gabormag(:,:,i)));
      %  title(['sum:', num2str(sm(i)),', wvl:',num2str(g(i).Wavelength), ', oirent', num2str(g(i).Orientation)],'fontsize',10);
    end
    cx = max(cx);
    %set(all_subplots(gcf),'CLim',cx);
    %figure; 
    [~,sm] = max(sm,[],2);
    %imagesc(gabormag(:,:,sm));


    X = 1:numCols;
    Y = 1:numRows;
    [X,Y] = meshgrid(X,Y);
    featureSet = cat(3,gabormag,X);
    featureSet = cat(3,featureSet,Y);

    numPoints = numRows*numCols;
    X = reshape(featureSet,numRows*numCols,[]);



    X = bsxfun(@minus, X, mean(X));
    X = bsxfun(@rdivide,X,std(X));



    coeff = pca(X);
    feature2DImage = reshape(X*coeff(:,1),numRows,numCols);
    %figure(h);subplot(312);
    %imshow(feature2DImage,[])

    L = kmeans(X,2,'Replicates',5);



    L = reshape(L,[numRows numCols]);
    %figure(h);subplot(313);
    %imshow(label2rgb(L))


    % visualise the gabor filters
%     figure;
%     for p = 1:length(g)
%         subplotfit(p,length(g));
%         imshow(real(g(p).SpatialKernel),[]);
%         lambda = g(p).Wavelength;
%         theta  = g(p).Orientation;
%         title(sprintf('Re[h(x,y)], \\lambda = %d, \\theta = %d',lambda,theta),'fontsize',10);
%     end
% pause(0.1);
%     commandwindow
%     commandwindow
    %input('Press ENTER to continue');
    
    % the most informative fig
    figure; subplot(211);
    imshow(real(g(sm).SpatialKernel),[]);
    subplot(212);
    imshow(A,[]);
    
    pause(3);
end

%%
figure; jplot(zdata(:,ii)+repmat([0:4:4*10],length(videoFeatures.data),1));


%% nose dlc something
close all;
nose = importDLC('/storage2/perentos/data/recordings/NP46/NP46_2019-12-02_18-47-02/video/top_cam_0_date_2019_12_02_time_18_46_55_v001DeepCut_resnet50_NoseDLCDec2shuffle1_950000.csv');
t = (1:max(size(T.P)))'; % time index

To = T; % the original positions and probabilities
P = min(T.P,[],1); % retain minimum probability per point set (timepoint)
otl = find(P<=0.99); % excluding based on DLC label probability 
% define additional outliers based on the center of mass
cx = median(vc(T.X)); cy = median(vc(T.Y)); % COM
cxi = mean(T.X,1); cyi = mean(T.Y,1); % COM per timepoint
toofar = find(abs(cxi-cx)>20 |abs(cyi-cy)>30);
otl = union(otl,toofar);



figure; subplot(211);
jplot(To.X(1,:),'linewidth',2);
hold on; 
T.X(1,otl) = nan;
T.X(2,otl) = nan;
T.X(3,otl) = nan;
T.Y(1,otl) = nan;
T.Y(2,otl) = nan;
T.Y(3,otl) = nan;
jplot(t,T.X(1,:),'-','linewidth',1.5);
%axis tight;
%xlim([22604 23667]);ylim([160 245]);
%
subplot(212);
jplot(To.Y(1,:),'linewidth',2);
hold on; 
T.X(1,otl) = nan;
jplot(t,T.Y(1,:),'-','linewidth',1.5);
%axis tight;
%xlim([22604 23667]);ylim([160 245]);
linkaxes(get(gcf,'children'),'x')

%% nose dlc something
opts.frames = [21856-20:21856+20];
opts.frames = [79651-20:79651+20];
opts.flag = 'frames';
plotNoseTracking(fileBase,opts);
close all;



%% thetaprops 
% for normal lfp channel
thetaProps(fileBase, {'channel',str2num(searchMasterSpreadsheet(fileBase,'thetaCh')),'dataType','raw'});

% for ICA reconstructed data
thetaProps(fileBase, {'dataType','ICA','channel',str2num(searchMasterSpreadsheet(fileBase,'thetaCh'))});%,'dataType','ICA'


figure; 
subplot(311);jplot(thetaProps.thPh);
subplot(312);jplot(thetaProps.thAmp);
subplot(313);jplot(thetaProps.thFr);

th_raw = load('thetaProps_raw_ch8.mat');
th_ica = load('thetaProps_ica_ch8.mat');

ddd = [ respRaw.props.thPh'; respIca.props.thPh' ];
eegplot(ddd,'srate',1000,'color','on');

figure;
clf;
subplot(311);
    ddd = [ th_raw.thetaProps.thFr'; th_ica.thetaProps.thFr' ];
    XBins = linspace(min(ddd(:)),prctile(ddd(:),100),100); YBins = XBins;
    hist2(ddd',XBins,YBins); axis square; hold on;    
    plot([XBins(1) XBins(end)],[YBins(1) YBins(end)],'--w','linewidth',2);
    xlabel('raw theta frequency (Hz)');
    ylabel('ICA corrected theta frequency (Hz)');
    %[Out, XBins, YBins, Pos] = hist2(ddd');
subplot(312);
    ddd = [ th_raw.thetaProps.thAmp'; th_ica.thetaProps.thAmp' ];
    XBins = linspace(0,prctile(ddd(:),99),100); YBins = XBins;
    hist2(ddd',XBins,YBins); axis square; hold on;
    plot([XBins(1) XBins(end)],[YBins(1) YBins(end)],'--w','linewidth',2);
    xlabel('raw theta amplitude (/muV)');
    ylabel('ICA corrected theta amplitude (/muV)');
subplot(313);
    ddd = [ th_raw.thetaProps.thPh'; th_ica.thetaProps.thPh' ];
    hist2(ddd',100,100); axis square; hold on;
    plot([-pi pi],[-pi pi],'--w','linewidth',2);
    xlabel('raw theta phase (rad)');
    ylabel('ICA corrected theta phase (rad)');
    
ForAllSubplots('set(gca,''fontsize'',16)');    


%% similarly we can repeat the above for the respiration
oscillationProps(fileBase, {'channel',str2num(searchMasterSpreadsheet(fileBase,'respCh')),'dataType','raw','freqRange',[1 7],'channelName','respCh'});
% for ICA reconstructed data
oscillationProps(fileBase, {'channel',str2num(searchMasterSpreadsheet(fileBase,'respCh')),'dataType','ICA','freqRange',[1 7],'channelName','respCh'});%,'dataType','ICA'




%%
T = getCarouselDataBase;
for i = [47]
    fileBase = T.session{i};
    display(['processing ',num2str(i), ' out of ', num2str(height(T)), ', fileBase: ',fileBase]);    
    initialiseVideoAnalysis(fileBase);
end




%% run a video analysis function across many session efficiently
% this example is whisker which needs ROI (re)definitions
T= getCarouselDataBase;
for i = [74 84 88]-1
    fileBase = T.session{i};
    cd(getfullpath(fileBase));
    delete('whiskerROIs.mat');
    trackWhiskersGabor(fileBase);
end
    
T= getCarouselDataBase;
for i = [74 84 88]-1
    fileBase = T.session{i};
    cd(getfullpath(fileBase));
    trackWhiskersGabor(fileBase,{'init',0,'track',1});
end  




%% how to load the behavior data which is going to be a few Gb...
% we use the matfile method as long as the data is saved in a mat file in
% plain varibles and not in structures tus making it straightforward to
% load partially. 
% the other option is to not upsample the videos to the lfop rate! Its
% convenienty but wasteful....

m =matfile('behavior.mat');

tomato.m = matfile('behavior.mat');
tomato.can = 'red'

%% box plot
load carsmall MPG 
figure;
MPG(:,2)=MPG(:,1).*2;
MPG(:,3)=MPG(:,1).*3;
MPG(:,4)=MPG(:,1).*4;
pos = [0.9 1.1 1.9 2.2]
boxplot(MPG,'positions',pos); 
hold on;
x=repmat(pos,length(MPG),1);
gscatter(x(:),MPG(:),'filled','MarkerFaceAlpha',0.6','jitter','on','jitterAmount',0.015);

%nosePC1 = smooth(nose.PCs.score(:,1),5);
nosePC1 = nose.PCs.score(:,1);
speed = diff(nosePC1); speed = [0;speed];
accel = diff(speed); accel = [0;accel];
jerk = diff(accel); jerk = [0;jerk];
close all; figure; 
%jplot([nosePC1./max(nosePC1),speed,accel,jerk]);
subplot(211);jplot(nosePC1);
subplot(212);jplot(jerk);
linkaxes(get(gcf,'children'),'x');
legend('nosePC1','speed','accel','jerk');


noseCOM1 = smooth(mean(nose.dataRaw(:,4:6),2),15);
close all; figure;
subplot(311);jplot(noseCOM1);
subplot(312);jplot([0;diff(noseCOM1)]);
subplot(313);jplot([0;0;diff(diff(noseCOM1))]);
linkaxes(get(gcf,'children'),'x');
xlim([19352.587353193          20110.7274385447]);

%% 
i_Sessions =  [1 2 6 18 30 38 44 51 57 59 73 83 87 101 112 123 132 139 147 155 163 168 177 190 197 200 203 3 7 17 29 36 47 56 70 99 109 134 161 206 12 16 33 41 46 62 115 137 165];
% Natalia? whats up with sessions in red? 
i_Sessions = sort(i_Sessions);
T = getCarouselDataBase;
% lets loop through all the sessions and rerun so as to correct respiration
% filter settings, add nose angle and magnitude. There might be more...
clear ErrorLog;
for i = 21:length(i_Sessions) 
    close all;
    try 
        fileBase = T.session{i_Sessions(i)};
        display(['processing ',num2str(i), ' out of ', num2str(length(i_Sessions)), '  : ',fileBase]);

    % rerun import DLC
        %importDLC(fileBase);  % reran on Oct 2 for i_Sessions
    % rerun getVidVars
        %getVidVars(fileBase); % reran on Oct 2 for i_Sessions
    % rerun generateAuxVars
        if strcmp(fileBase, 'NP39_2019-11-21_11-44-59')
            continue;
        end
        generateAuxVars(fileBase);

        
    %rerun combineVidAuxVars
        
    catch exception
        ErrorLog{i,1} = T.session{i_Sessions(i)};
        ErrorLog{i,2} = getReport(exception);
    end
end

%% pupil detection in deeplabcut using cropped avis (ffmpeg)
% NOTE THAT THIS WAS MOVED TO INITIALSEvIDEOaNALYSIS SO BEST TO CHECK THERE
% but also 8 points to define the pupil as well as a point for the IR
% reflection.
% first we generate pupil cropped videos and store them intheir respective
% video folders
% e.g.ffmpeg -i side_cam_1_date_2019_12_11_time_16_08_17_v001.avi -filter:v "crop=180:160:250:200" -c:a copy pupil.avi
error('this block should be run step by step not all in once. Study it first');
clear;close all;
i_Sessions =  [ 2 3 6 7 12 16 17 18 29 30 33 36 38 41 44 ...
    46 47 51 56 57 59 62 70 73 83 87 99 101 109 112 115 132 ...
    134 137 139 147 155 161 163 165 168 177 190 197 200 203 206 ];
excluded = [1 123];
i_Sessions = sort(i_Sessions);
T = getCarouselDataBase;        
allFileBases = [T.session(i_Sessions)];
% cropped videos and save as fileBase_pupil.avi
for i = 1:length(i_Sessions)
    goto(allFileBases{i});    
    load faceROIs.mat; % obviousy only works if previous ROIs were defined using subFrameSVD.m
    roi = ROI.pts(find(strcmp(ROI.names,'eye')),:);
    cd ../video
    d=dir('side*.avi');
    if length(d) == 1        
        phrase = ['ffmpeg -i ', fullfile(d.folder,d.name), ' -filter:v "crop=',num2str(roi(3)),':',...
            num2str(roi(4)),':',num2str(roi(1)),':',num2str(roi(2)),'" -c:a copy ',fullfile(d.folder,[allFileBases{i},'_pupil.avi'])];
        system([phrase]);
    end
end

% then we move onto spikesorter and setup a new project
% ssh -Y perentos@spikesorter
% cd /opt/py36
% source bin/activate
% cd /storage2/perentos/data
% python -m deeplabcut
% make the project through the interface

% add videos for user labelling and training
project_path = '/storage2/perentos/data/pupil3-NP-2020-10-16/';    
fid = fopen([project_path,'/training_vids.txt'],'w'); %write paths here
%sideVidPaths = sideVidPaths(sort(unique([2,randperm(length(sideVidPaths),10)])),1);
training_set = sort(randperm(length(allFileBases),10))
% add videos known to have gummy eye
training_set = unique([training_set, [12, 21, 30, 38]]);% the last ones are known gummy eyes
for i = 1:length(training_set)
    goto(allFileBases{training_set(i)});
    cd ../video    
    % FULL PATHS TO SIDE VIDEO FOR DLC USE
    d=dir('*pupil.avi');
    if length(d) == 1
        % print 
        sideVidPaths{i,1} = ['  ',d.folder,'/', d.name,':'];
        %         sideVidPaths{i,2} = ['    crop: ',num2str(roi(1)),', ',...
        %                             num2str(roi(2)),', ',....
        %                             num2str(roi(1)+roi(3)),', ',...
        %                             num2str(roi(2)+roi(4))];
        sideVidPaths{i,2} = ['    crop: 0,720, 0, 540'];                    
        fprintf(fid,[sideVidPaths{i,1},'\n']);
        fprintf(fid,[sideVidPaths{i,2},'\n']);
        
        % link in project folder to training videos
        training_vid_list = [project_path,'/videos/'];
        str = ['!ln -s ', d.folder,'/', d.name,' ',training_vid_list, d.name];
        eval(str);
        % training video folders for extracted frames. DLC needs this
        mkdir([project_path,'labeled-data/',d.name(1:end-4)]);
    else
        error('something wrong with file names');
    end
    
end
fclose(fid); 

% generate paths to vids to be processed
clear;close all;
fid = fopen('/storage2/perentos/data/pupil3-NP-2020-10-16/paths_to_analysis_vids.txt','w');
i_Sessions =  [ 2 3 6 7 12 16 17 18 29 30 33 36 38 41 44 ...
    46 47 51 56 57 59 62 70 73 83 87 99 101 109 112 115 132 ...
    134 137 139 147 155 161 163 165 168 177 190 197 200 203 206 ];
excluded = [1 123];
i_Sessions = sort(i_Sessions);
T = getCarouselDataBase;        
allFileBases = [T.session(i_Sessions)];
% create paths to all pupil videos to be analysed
for i = 1:length(i_Sessions)
    goto(allFileBases{i});
    cd ../video
    d=dir('*pupil.avi');
    if length(d) == 1        
        fprintf( fid, '%s\n', fullfile(d.folder,d.name));
    end
end
fclose(fid); 
 
% train the network on the spikesorter (use GUI)
% once 250k or 300k iterations are reach, then the training can be
% interrupted

% Final step is to label all the videos. This is most likely best achieved
% automatically though the following script
% /storage2/perentos/data/pupil3-NP-2020-10-16/pupil_DLC_batch_process.py      
figure; 
hold on;
for i = 1:length(tmpP{1,1})
    plot(xax{1,1}{i});
end


%% fix rejTrials
clear;close all;
i_Sessions =  [ 2 3 6 7 12 16 17 18 29 30 33 36 38 41 44 ...
    46 47 51 56 57 59 62 70 73 83 87 99 101 109 112 115 132 ...
    134 137 139 147 155 161 163 165 168 177 190 197 200 203 206 ];
excluded = [1 123];
i_Sessions = sort(i_Sessions);
T = getCarouselDataBase;        
allFileBases = [T.session(i_Sessions)];
for i = 38:length(allFileBases) % skip the first since its a special case with missing pulses etc
% GET SACCADES    
%     goto(allFileBases{i});
%     if ~exist(fullfile(pwd,'saccades.mat'))
%         getSaccades(allFileBases{i});    
%     end
% FIX session.info.rejTrials VARIABLE FOR ALL SESSIONS
%     [session,behavior] = loadSession(allFileBases{i});
%     session.info.rejTrials = str2num(T.rejTrials{i_Sessions(i)});
%     goto(allFileBases{i});
%     save(fullfile(pwd,'session.mat'),'session','-append','-v7.3');
% CHECK THE session.info.rejTrials FOR ALL SESSIONS
%     [session,behavior] = loadSession(allFileBases{i});
%     if isfield(session.info,'rejTrials')
%         display([allFileBases{i},' : rejTr: ', num2str(session.info.rejTrials)]);
%     else
%         display([allFileBases{i},' : rejTr: none']);
%     end
% INCORPORATE SACCADES INTO THE VIDEO FEATURES AND THE SESSION VARIABLE
%     goto(allFileBases{i});
%     getVidVars(allFileBases{i})
%     load('all_video_results.mat');
%     videoFeatures.name{end}
    combineVidAuxVars(allFileBases{i});
    close all;
end
% options.verbose = 1;
% [Total, List] = GoThroughDb('getSaccades',allFileBases, 0, 0, 0, options);


%% examine the lengths of video vars at the different stages of processing
behavior_interim = load('behavior_interim.mat');
display(['behavior_interim: ',num2str(size(behavior_interim.behavior.data,2))]);

behavior = load('behavior_interim.mat');
display(['behavior: ',num2str(size(behavior.behavior.data,2))]);

fileBase = 'NP45_2019-11-15_15-05-50';

lst = unique(sp.clu)
for i = 1:length(sp.cgs)
    nSp(i,1) = length(find(sp.clu == sp.cids(i)));% number of spikes
    nSp(i,2) = sp.cgs(i);% group
end



% browse natalias functions

cd '/storage2/natalia/code/matlab/'
edit Fet2RateCorrelation





%%
i_Sessions =  [ 6 7 12 16 17 38 41 44 ...
    46 47 51 70 87 99 101 129 132 ...
    134 137 139 147 155 ];
T = getCarouselDataBase;  
myDB = T.session(i_Sessions);
close all;
for i = 1:length(myDB)
    goto(myDB{i});
    fff = imread('place_cell_coverage.jpg');
    figure;
    imshow(fff,'InitialMagnification',100);
end


%% search for fileBase.tun.mat availability
i_Sessions =  [ 6 7 12 16 17 38 41 44 ...
    46 47 51 70 87 99 101 129 132 ...
    134 137 139 147 155 ];
T = getCarouselDataBase;  
myDB = T.session(i_Sessions);
clc
for i = 1:length(myDB)
    i
    fileBase = myDB{i};
    goto(fileBase);
    if ~exist('behTrialsMatrices.mat')
        dsplay(fileBase)
    end
%     [session,behavior]=loadSession(fileBase);    
%     
%     if isempty(find(strcmp(behavior.name,'saccadesX'))) | isempty(find(strcmp(behavior.name,'pupilDLC_area'))) %
%         display([fileBase,'----pupDLC missing from behavior so computing']);
%         getVidVars(fileBase);
%         combineVidAuxVars(fileBase);
%     end

%     getClusterProperties(fileBase);
%     getTuningCurves(fileBase);
%     evalc('goto(fileBase)');
%     if exist(['tun1.mat'])%exist([fileBase,'.tun.mat'])
%         fprintf('1\n')
%     else
%         fprintf('0\n')
%     end

end



%% really need to build the full pipeline
set(0,'DefaultFigureVisible','off');
GoThroughDb('placeCellCoverage',myDB, 0, 0, 0);


%     goto(allFileBases{i});

%% export open figs into a ppt
i_Sessions =  [ 6 7 12 16 17 38 41 44 ...
    46 47 51 70 87 99 101 129 132 ...
    134 137 139 147 155 ];
T = getCarouselDataBase;  
myDB = T.session(i_Sessions);
close all;
for i = 1:length(myDB)
    goto(myDB{i});
    fff = imread('place_cell_coverage.jpg');
    figure;
    imshow(fff,'InitialMagnification',100);
end

pptx    = exportToPPTX('', ...
    'Dimensions',[12 6], ...
    'Title','Example Presentation', ...
    'Author','MATLAB', ...
    'Subject','Automatically generated PPTX file', ...
    'Comments','This file has been automatically generated by exportToPPTX');
% Another way of setting some properties
pptx.title          = 'Demonstration Presentation';
pptx.author         = 'exportToPPTX Example';
pptx.subject        = 'Demonstration of various exportToPPTX commands';
pptx.description    = 'Description goes in here';
% Additionally background color for all slides can be set as follows:
% exportToPPTX('new','BackgroundColor',[0.5 0.5 0.5]);
% Add some slides
%figH = figure('Renderer','zbuffer'); mesh(peaks); view(0,0);
hdl = findall(groot,'Type','figure')

for islide=1:length(hdl),
    slideId = pptx.addSlide();
    fprintf('Added slide %d\n',slideId);
    pptx.addPicture(hdl(i));
    %pptx.addTextbox(sprintf('Slide Number %d',slideId));
    %pptx.addNote(sprintf('Notes data: slide number %d',slideId));
    
    % Rotate mesh on each slide
%     view(18*islide,18*islide);
end
close(hdl);
% Check current presentation
fprintf('Presentation size: %f x %f\n',pptx.dimensions);
fprintf('Number of slides: %d\n',pptx.numSlides);
% Save presentation and close presentation -- overwrite file if it already exists
% Filename automatically checked for proper extension
newFile     = pptx.save('/storage2/perentos/data/recordings/place_cell_coverage_all_sessions');


%% an example of how to paass data to decode_bayesian_poisson from Kloosterman
ratemaps = [ 1  2 3 4 5 6 7 8 7 6 5 4 3 2 1;
             8  7 6 5 4 3 2 1 1 1 1 1 1 1 1; 
             10 12 8 3 2 2 2 2 2 2 1 1 0 1 10; 
             0  0 0 0 0 0 0 0 0 0 1 2 3 4 0;
              0 3 4 5 0 0 1 0 0 0 6 7 7 5 5 ];
          
spikecounts = [1 8 10 0 1;
    3 6 8 0 2
    5 5 3 4 0;
    8 1 2 0 0
    5 1 1 1 6
    0 0 10 1 4;
    0 7 10 0 0]';
E=decode_bayesian_poisson(ratemaps',spikecounts,'bins',3);size(E)
figure; plot(zscore(E)); title('bins=3');legend('1','2','3','4','5','6','7')

% therefore ratemaps tuning curves should be position by neuron e.g. 360 degrees by 15 neurons
% and spikecounts which is the data to decode should be neuron x new time bisn e.g. 15 neurons by 10 new time bins for whcih we need to decode the position
% in the example above its only 3 new time bins with each having the 5 neurons(matching the amount of neurons in ratemaps)

% there is also Justins function that might be useful

%% gather smoothed firing rate as well as tuning curves of a subset of neurons
% to use in a bayesian decoder
[kept_IDs, tCurves] = placeCellCoverage(fileBase); % get IDs of selected cells for coverage
out = getFiringRates(fileBase,'win',0.05,'units',kept_IDs); % take note that the smoothing of rates matches that of the tuning curves!
load([fileBase,'.tun1.mat']); % tuning curves
idx = find(ismember(tun1.cids,kept_IDs)); % indices into tun1 of kept_IDs
tunCurves = mean(tun1.tuningSm(idx,:,:),3);

find(out.t>618,1,'first')

FR = out.r(61800:150000,:); % a subsample
figure; imagesc(FR')

E=decode_bayesian_poisson(tunCurves',FR','bins',3);
size(E)





%% 
for i = 1:length(myDB)
    fileBase = myDB{i};
    [session,~] = loadSession(fileBase);
    min((diff(find(diff(session.helper.idxTrials) ~= 0))./session.info.SR_LFP)')
end



%% carousel bayes decode

% 1. compute tuning curves at 20 degree resolution but revisit the code with
% which they are generated/smoothed - maybe the smoothing needs to be
% revisited or at least convince of correctness. 1 degree bins is too many
% bins!! perhaps thats why the decoding didnt (seemingly) work
% we choose 20 degree bins since for the fastest running case of full
% circle in 3 seconds (unlikely fast running) we get 166ms to traverse a 20
% degree arc. Therefore the 50ms decoding interval is within limits
close all;
fileBase = myDB{5};
goto(fileBase);
load([fileBase,'.tun1.mat']);
[session, behavior] = loadSession(fileBase);
arc = 20; % resolution of carousel position in degrees
deg = [0:arc:360-1]

% we will usetun1.tuningSm derived using smooth_gaus with sd=2 and window
% of 6. Can revisit this in getFiringRates if unhappy with it
%close all;
[kept_cids, tCurves,II] = placeCellCoverage(fileBase);
nIDs = kept_cids.subselectedSUA;
tCs = mean(tCurves.subselectedSUA,3);
figure; subplot(311); imagesc(tCs); colorbar;%(II,:)
rs = resample(tCs',1,arc);%(II,:)
subplot(312); imagesc(rs'); colorbar;

% 2. Compute smooth firing rates at 50 ms resolution
FR = getFiringRates(fileBase,'units',nIDs);

from = 2340;
to = 2722;
rn = find(FR.t>from & FR.t<=to);
figure; imagesc(FR.t(rn),[],FR.r(rn,:)');

realPos = behavior.data.data(:,find(strcmp(behavior.name, 'position')));
prior = histc(realPos,deg)./sum(prior);

realPos = downsample(realPos,50);

E=decode_bayesian_poisson(rs,FR.r(rn,:)','bins',1,'prior',prior);
% E=decode_bayesian_poisson(rs,FR.r(rn,:)','bins',1);
[~,decoded_pos] = max(E,[],1);
figure('pos',[307 511 2203 537]); 
plot(FR.t(rn),(decoded_pos.*arc)-arc); hold on;


% what is the actual position

ttemp = [50:50:length(realPos)*50]./1e3;
plot(ttemp,realPos); xlim([from to]);

% figure;
% for i = 1:5
%     plot(FR.r(:,i))
%     hold on;
%     waitforbuttonpress
% end

   
%% for each session in myDB, compute firing rates for each block and plot
    % make three violin plots collapsing units acroos animals for each of the
    % three conditions of bsl, fem and NO.
    clearvars -except myDB
    clrs = get(gca,'colororder'); close all; grp = {}; rateCh = [];
    for i = 1:length(myDB)
        fileBase = myDB{i};
        goto(fileBase);
        load([fileBase,'.tun1.mat']);
        [session, behavior] = loadSession(fileBase);
        tmp = {session.info.conditions{2}};

        [kept_cids, tCurves,II] = placeCellCoverage(fileBase); close
        nIDs = kept_cids.subselectedSUA;

        idx = find(ismember(tun1.cids,nIDs));

        % collect maxima of selected trial resolved tuning curves
        tun = squeeze(max(tun1.tuningSm(idx,:,:),[],2)); 
        % split by blocks
        tr1 = [1:session.info.trialsPerBlock(1)];
        tr2 = [session.info.trialsPerBlock(1)+1:sum(session.info.trialsPerBlock)];
        Bl1{i} = mean(tun(:,tr1),2);
        Bl2{i} = mean(tun(:,tr2),2);
        grp = [grp;repmat(tmp,length(Bl1{i}),1)];
    end
    
    rateCh = [];
    for i = 1:length(Bl1)
        rateCh = [rateCh; ((Bl2{i} + eps)./ (Bl1{i} + eps))];
        
    end
    
    figure;  
    priors = [sum(strcmp(grp,'bsl')); sum(strcmp(grp,'NO')); sum(strcmp(grp,'fem'))];
    
    % how many cells change their firing rate by a factor greater than 2
    [I] = find(rateCh >= 2);
    rn = [sum(strcmp(grp(I), 'bsl')); sum(strcmp(grp(I), 'NO')); sum(strcmp(grp(I), 'fem'))];
    
    otl = rn(:)./priors(:);
     
    violinplot(rateCh(setdiff(1:end,I)),grp(setdiff(1:end,I)));
    hold on; 
    text(0.75,0.25,[num2str(otl(1))],'color','r');
    text(1.75,0.25,[num2str(otl(2))],'color','r');
    text(2.75,0.25,[num2str(otl(3))],'color','r');

    
    %% compute preferred theta phase of each cell
    clearvars -except myD*
    fileBase = myDB{6};
    goto(fileBase);
    load([fileBase,'.tun1.mat']);
    [session, behavior] = loadSession(fileBase);
    [kept_cids, tCurves,II] = placeCellCoverage(fileBase);
    ids = kept_cids.subselectedSUA;
    load([fileBase,'.tun1.mat']);   
        
    sp = loadKSdir(pwd);   
    clear thph
    thph{1} = behavior.data.data(:,find(strcmp(behavior.name,'theta_ica_phase')));
    thph{2} = behavior.data.data(:,find(strcmp(behavior.name,'theta_raw_phase')));
    thph{3} = behavior.data.data(:,find(strcmp(behavior.name,'resp_ica_phase')));
    thph{4} = behavior.data.data(:,find(strcmp(behavior.name,'resp_raw_phase')));    
    
    phnm = {'theta_ica_phase','theta_raw_phase','resp_ica_phase','resp_raw_phase'};
    
    %%load spikes into normal Res/Clu for all clusters
    % cids_id =ismember(sp.clu,sp.cids);
    Res = round(sp.st.*session.info.SR_LFP); % from seconds to LFP sample numbers
    [uClu, ~,Clu] = unique(sp.clu);%  % Clu is the spike cluster number for each spike and uClu the list of cluster numbers
    nClu= length(uClu); % number of unique clusters contained

    % for each cluster ids, plot histogram of its spike phases
    close all; figure;
    for i = 1:length(ids)%nClu
        ii = ids(i);%uClu(i)
        for j = 1:4
            x = linspace(-pi,pi,40);
            y = thph{j}(intersect(Res(Clu == ii), find(session.helper.idxMov == 1)));
            % a more elegant way to get the indices
            %myRes= Res(Clu==c );
            %my_inMv = idxMv(myRes);
            %myRes = myRes(my_inMv);
            n = histc(y, x);
            subplot(2,2,j);        
            b = bar(x,n);
            set(b,'FaceColor', 0.7*[1 1 1]);
            axis tight
            set(gca, 'xlim', [-pi pi], 'xtick', [-pi 0 pi], 'xticklabel', {'-pi','0','pi'})
            xlabel('Theta phase, (rad)')
            ylabel('Spike count')
            title(sprintf('cluster-%d',ii))
            clear b x n
        end
        pause(0.3);%
        %waitforbuttonpress;
        clf
    end
    
 %%    
for i = 1:length(myDBBehOnly)    
    i
    close;goto(myDBBehOnly{i});
    cd ../video
    %ls
    %!ls *pupil.avi
    !ls *.csv
    %ddd = dir('*pupil.avi');
    %if exist(myDBBehOnly{i},'_pupil.avi')%length(ddd) == 1
    %    display([myDBBehOnly{i},'   ---OK'])
    %else
    %    display([myDBBehOnly{i},'   ---NOT!!!'])
    %end
    %pause
    %findCommonMode(myDBBehOnly{i})
end
    
% for i = 1:length(myDBBehOnly)
%     j(i) = find(strcmp(T.session,myDBBehOnly{i}));
% end

%% generate pupil video that feeds into deeplabcut
for i = 1:length(myDBBehOnly)
    goto(myDBBehOnly{i});    
    load faceROIs.mat; % obviousy only works if previous ROIs were defined using subFrameSVD.m
    roi = ROI.pts(find(strcmp(ROI.names,'eye')),:);
    cd ../video
    d=dir('side*.avi')
    if length(d) == 1        
        phrase = ['ffmpeg -i ', fullfile(d.folder,d.name), ' -filter:v "crop=',num2str(roi(3)),':',...
            num2str(roi(4)),':',num2str(roi(1)),':',num2str(roi(2)),'" -c:a copy ',fullfile(d.folder,[myDBBehOnly{i},'_pupil.avi'])];
        system([phrase]);
    else
        error('more than one files?')
    end
end   
        
%% delete pupil videos
clc;
for i = 1:length(myDBBehOnly)
    goto(myDBBehOnly{i}); 
    pwd
    %cd ../video
    !ls
    display('*********************************************************');
%     ddd = dir('*pupil.avi');
%     for j = 1:length(ddd)
%         delete(fullfile(ddd.folder,ddd.name))
%     end
pause
end        


%% GoThroughDB
GoThroughDb('runVideoAnalysis',myDBBehOnly(8:22), 0, 0, 0);

%% generate a list of sessions fulffillng some criteria from the database
is_bsl = strcmp('baseline',T.manipulation); 
is_fem = strcmp('female',T.manipulation); 
is_NO  = strcmp('novel_object',T.manipulation); 
is_puf = strcmp('air_puff',T.manipulation); 
is_WM  = strcmp('water_remap',T.manipulation);
is_rpl = strcmp('ripples',T.manipulation);
is_gain= strcmp('gain_change',T.manipulation);
is_controlled = strcmp('controlled',T.taskType);

ix = find(is_controlled & is_bsl); % ,1,'first'


%% write to file
a = [5 6];
fID = fopen('debug.txt','w');
fprintf(fID, '%6.2f\n', a);
fclose(fID);



%%
