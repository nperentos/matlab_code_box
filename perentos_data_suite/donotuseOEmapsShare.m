function oemaps = OEmapsShare

% To get the full map apply the connector-to-headstage map to the 
% sites-to-headstage map. Acute probes often require one more map.
%
% Example1: To get the map for a 32 channels probe with two shanks and 
% linear profile (A2x16), one has to run:
%      map = oemaps.h32(oemaps.a2x16)
% Example2: If the probe was acute, it would be:
%      map = oemaps.o32(oemaps.a32(oemaps.a2x16))
%
% When recording from more than one probe, just concatenate the map
% remembering to add to the probes after the first one the number of
% channels the preceding probes are taking care of:
%
% Example3: The probe of the other examples, followed in the same recording
% by a linear probe with 32 channels. Note the "32" added to the second
% probe.
%       map =  = [oemaps.h32(oemaps.a2x16) 32+oemaps.h32(oemaps.edge32)];
%
% maps generated this way can be used either with openephys2dat (Nikolas
% function to create .dat files from OpenEphys raw data):
%      openephys2dat(pwd, 'mapping', map)
% (another useful optional argument of the same function is 'outpath')
% and with makeOEmapFile, to create a file with the mapping that is 
% readable by Open Ephys:
%       makeOEmapFile(map, filename)

%% CONNECTOR TO Open Ephys HEADSTAGE MAPS:
oemaps.h16 = [9 11 12 16 13 14 15 10 7 2 3 4 1 5 6 8];
oemaps.h32 = [17 18 19 21 22 23 32 31 30 28 27 26 25 29 24 20 13 9 4 8 7 6 5 3 2 1 10 11 12 14 15 16];
oemaps.h32invert = [1 2 3 5 6 7 16 15 14 12 11 10 9 13 8 4 29 25 20 24 23 22 21 19 18 17 26 27 28 30 31 32];
oemaps.o32 = [20 29 21 28 22 27 23 26 24 25 17 32 19 30 18 31 15 2 14 3 16 1 9 8 10 7 11 6 12 5 13 4];
oemaps.H2x32 = [40 41 39 42 38 43 37 44 36 45 35 46 34 47 33 48 17 18 19 21 22 23 25 26 27 29 30 31 32 28 24 20 13 9 5 1 2 3 4 6 7 8 10 11 12 14 15 16 49 64 50 63 51 62 52 61 53 60 54 59 55 58 56 57];

% This is inserting the the other way round:
oemaps.H2x32LP = [8 9 7 10 6 11 5 12 4 13 3 14 2 15 1 16 49 64 50 51 62 52 53 60 54 55 58 56 57 59 61 63 34 36 38 40 41 39 42 43 37 44 45 35 46 47 33 48 17 32 18 31 19 30 20 29 21 28 22 27 23 26 24 25];
oemaps.H64LP = [50 49 52 51 54 53 56 55 58 57 60 59 62 61 64 63 33 34 35 37 38 39 41 42 43 45 46 47 48 44 40 36 30 26 22 18 17 20 19 21 24 23 25 28 27 29 32 31 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16];
oemaps.H64LPinvert = [18 17 20 19 22 21 24 23 26 25 28 27 30 29 32 31 1 2 3 5 6 7 9 10 11 13 14 15 16 12 8 4 62 58 54 50 49 52 51 53 56 55 57 60 59 61 64 63 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48];
% oemaps.H64oldhighconnector =[36 37 38 39 35 40 41 42 34 43 44 45 33 46 47 48 17 18 19 32 20 21 22 32 23 24 25 30 26 27 28 29];
% oemaps.H64oldlowconnector =[15 13 11 9 7 5 3 1 2 4 6 8 10 12 14 16 49 51 53 55 57 59 61 63 64 62 60 58 56 54 52 50];
% oemaps.H64oldconnector =[oemaps.H64oldhighconnector oemaps.H64oldlowconnector]


%% ACUTE CONNECTOR MAP (goes between the other two maps)
oemaps.a32 = [16 6 5 15 4 7 3 8 2 9 1 10 14 13 12 11 22 21 20 19 31 23 25 24 18 26 17 27 29 28 30 32];

%% SITES TO CONNECTOR MAP
oemaps.linear16 = [9 8 10 7 11 6 12 5 13 4 14 3 15 2 16 1];
oemaps.linear32 = [17 16 18 15 19 14 20 13 21 12 22 11 23 10 24 9 25 8 26 7 27 6 28 5 29 4 30 3 31 2 32 1];
oemaps.edge32 = [32 31 30 29 28 27 26 25 24 23 22 21 20 19 18 17 16 15 14 13 12 11 10  9  8  7  6  5  4  3  2  1];
oemaps.buzsaki32 = [1 8 2 7 3 6 4 5 9 16 10 15 11 14 12 13 17 24 18 23 19 22 20 21 25 32 26 31 27 30 28 29];
oemaps.buzsaki64 = [1 8 2 7 3 6 4 5 9 16 10 15 11 14 12 13 17 24 18 23 19 22 20 21 25 32 26 31 27 30 28 29 33 40 34 39 35 38 36 37 41 48 42 47 43 46 44 45 49 56 50 55 51 54 52 53 57 64 58 63 59 62 60 61];
oemaps.a4x8 = [5 4 6 3 7 2 8 1 13 12 14 11 15 10 16 9 21 20 22 19 23 18 24 17 29 28 30 27 31 26 32 25];
oemaps.a8x8 = [5 4 6 3 7 2 8 1 13 12 14 11 15 10 16 9 21 20 22 19 23 18 24 17 29 28 30 27 31 26 32 25 37 36 38 35 39 34 40 33 45 44 46 43 47 42 48 41 53 52 54 51 55 50 56 49 61 60 62 59 63 58 64 57];
oemaps.poly2a32 = [23 10 24 9 25 8 26 7 27 6 28 5 29 4 30 3 31 2 32 1 22 11 21 12 20 13 19 14 18 15 17 16];
oemaps.a2x16 = [9 8 10 7 11 6 12 5 13 4 14 3 15 2 16 1 25 24 26 23 27 22 28 21 29 20 30 19 31 18 32 17] ;
oemaps.polya64 = [27 37 26 38 25 39 24 40 23 41 22 42 21 43 20 44 19 45 18 46 17 47 16 48 15 49 14 50 13 51 12 52 11 53 10 54 9 55 8 56 7 57 6 58 5 59 4 60 3 61 2 62 1 63 28 64 29 36 30 35 31 34 32 33];

oemaps.plain64 = [1:64]; 
oemaps.eog_eeg = [3 12 11 10 13 4 7 6 5 2 8 1 16 9 15 14]; %only first 9 are signal

%% Specific maps for some of our animals
oemaps.tc01 = oemaps.h32(oemaps.a2x16);
oemaps.tc02 = [oemaps.h32(oemaps.a2x16) 32+oemaps.h32(oemaps.edge32)];
oemaps.op01 =  oemaps.h32(oemaps.edge32);
oemaps.op04 = oemaps.H2x32LP(oemaps.polya64);
oemaps.ei01 = [oemaps.o32(oemaps.a32(oemaps.poly2a32))];
oemaps.ei01HC = [oemaps.o32(oemaps.a32(oemaps.poly2a32)) (32+oemaps.o32(oemaps.a32(oemaps.linear32)))];
oemaps.ei01ObLec = [oemaps.o32(oemaps.a32(oemaps.poly2a32)) (32+oemaps.o32(oemaps.a32(oemaps.a4x8)))];

oemaps.jm11 = [oemaps.h32(oemaps.linear32) 32+oemaps.h32(oemaps.a4x8) 64+oemaps.H64LP(oemaps.polya64) 128+oemaps.h16(oemaps.eog_eeg)]; 
oemaps.jm11_2 = [oemaps.h32invert(oemaps.a4x8) 32+oemaps.h32(oemaps.linear32) 64+oemaps.H64LPinvert(oemaps.polya64) 128+oemaps.h16(oemaps.eog_eeg)]; 
oemaps.jm11_3 = [oemaps.h32(oemaps.linear32) 32+oemaps.h32(oemaps.a4x8) 64+oemaps.H64LPinvert(oemaps.polya64) 128+oemaps.h16(oemaps.eog_eeg)]; 
oemaps.jm11_4 = [oemaps.h32(oemaps.linear32) 32+oemaps.h32invert(oemaps.a4x8) 64+oemaps.H64LPinvert(oemaps.polya64) 128+oemaps.h16(oemaps.eog_eeg)]; 
oemaps.jm11_5 = [oemaps.h32(oemaps.linear32) 32+oemaps.h32(oemaps.a4x8) 64+oemaps.H64LP(oemaps.polya64) 128+oemaps.h16(oemaps.eog_eeg)]; 
oemaps.poly64 = [oemaps.H64LP(oemaps.polya64)];


oemaps.jm15   = [oemaps.h32(oemaps.linear32) 32+oemaps.H64LPinvert(oemaps.a8x8) 96+oemaps.H64LP(oemaps.polya64) 160+oemaps.h16(oemaps.eog_eeg)];

% JM07:
% oemaps.jm07 =[oemaps.H64(oemaps.plain64) length(oemaps.H64)+oemaps.h32(oemaps.edge32) length(oemaps.h32)+length(oemaps.H64)+oemaps.h32(oemaps.a4x8)];
% oemaps.jm07 =[oemaps.H64oldconnector(oemaps.buzsaki64) length(oemaps.H64oldconnector)+oemaps.h32(oemaps.linear32) length(oemaps.h32)+length(oemaps.H64oldconnector)+oemaps.h32(oemaps.a4x8)]

 


% map = oemaps.jm07;
% map = oemaps.tc02;
% map = oemaps.op01; 
% openephys2dat(pwd, 'mapping', map, 'outpath', ['/storage/ephel/data/processed/' GetAnimalName(GetFileBase(pwd)) '/'])
% openephys2dat(pwd, 'mapping', oemaps.H64LP(oemaps.polya64), 'outpath', ['/storage/ephel/data/processed/' GetAnimalName(GetFileBase(pwd)) '/'])
% openephys2dat(pwd, 'mapping', oemaps.h32(oemaps.a2x16), 'outpath', ['/storage/ephel/data/processed/' GetAnimalName(GetFileBase(pwd)) '/'])