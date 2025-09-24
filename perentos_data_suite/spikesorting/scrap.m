% lets try and spike sorton spike sorter
% note: dont worry about deleting the temp_wh.dat file
tic;fileBase = 'NP34_2019-09-25_15-12-11';
fileBase = 'NP34_2019-09-25_13-41-59';
mapFile = 'NP34_H3+EEG+M2.mat';
master_kilosort(fileBase,mapFile);
toc


% or on my own PC
% 1. copy dat file into KSSolution

% 2. Run algo 

% 3. Delete the dat file 

% 4. Copy all files to appropriate folder on storage2

% 5. 

mapToday = [38,40,42,45,43,49,34,36,48,35,33,44,46,41,39,37,63,61,60,58,56,54,52,50,47,51,53,55,57,59,62,64,1,3,6,8,10,12,14,16,17,13,11,9,7,5,4,2,28,26,24,19,21,15,32,30,18,29,31,22,20,23,25,27,134,136,138,141,139,145,130,132,144,131,129,140,142,137,135,133,159,157,156,154,152,150,148,146,143,147,149,151,153,155,158,160,98,100,101,103,105,107,109,113,112,110,108,106,104,102,99,97,123,121,119,116,118,127,125,114,126,128,111,117,115,120,122,124];

fle = 'NP34_2019-09-04_15-00-11';

convertData(fle,mapToday)