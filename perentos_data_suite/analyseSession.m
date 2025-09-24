function analyseSession(fileBase)
% analyseSession runs all pipeline steps that can be run automatically.
% There are however some prerequisites:
% 1. Data was converted from OE format to .dat, bad channels marked in neuroscope, theta, resp channels identified
% 2. online spreadsheet populated with the session's relevant info (see relevant spreadsheet for needed entries)
% 3. deeplabcut has been run for nose detection
% 4. deeplabcut has been run for pupil detection
% 5. kilosort was run (most likely on spike sorter)
% 6. manual curation in phy was concluded (spikesorter on Nikolas' desktop PC

% in fact a better strategy would be to do batch processing in indivdual
% analysis steps one by one rather than running everything at once for each
% session. Maybe try both and see how it goes. 


%% LFP AND BEHAVIOR
convertDataCarousel(fileBase);
initialiseVideoAnalysis(fileBase); % requirres user input
runVideoAnalysis(fileBase);
getVidVars(fileBase);
getGoodChannels(fileBase);
findCommonMode(fileBase);
generateAuxVars(fileBase);
combineVidAuxVars(fileBase);
updateSession(fileBase);
getBehTrialMatrices(fileBase);
downsampleBehTrialMatrices(fileBase); % tris is yet to be implemented properly

%% SPIKES
master_kilosort(fileBase);
% manual curation goes here
unitProcessing(fileBase);


(fileBase);
(fileBase);
(fileBase);
 
