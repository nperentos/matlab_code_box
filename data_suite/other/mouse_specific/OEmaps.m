% Note on ADC channels:
% ADC1: Opto1 TTL (Stimulator Ch.1 TTL signal)
% ADC2: Opto1 Ref (Stimulator Ch.3 copied signal)
% ADC3: Opto2 TTL (Stimulator Ch.2 TTL signal) - Footshock (Arduino ch: )
% ADC4: Opto2 Ref (Stimulator Ch.4 copied signal)
% ADC5: Sound - Photometry clock (Digital I/O 1)
% ADC6: 
% ADC7: Start TTL (Arduino ch: )
% ADC8: Miniscope frames

% Old (before Nov 19)
%ADC1 —> OptoStim
%ADC2 —> LED waveform
%ADC3 —> Tone
%ADC4 —> 
%ADC5 —> 
%ADC5 —> 
%ADC7 —> Start TTL (Arduino ch: )
%ADC6 —> Miniscope frames

%% Connectors
oemaps.h16 = [9 11 12 16 13 14 15 10 7 2 3 4 1 5 6 8]; 
oemaps.a16om32 = [17 32 18 31 19 30 20 29 13 4 14 3 15 2 16 1]; 

oemaps.h32 = [17 18 19 21 22 23 32 31 30 28 27 26 25 29 24 20 13 9 4 8 7 6 5 3 2 1 10 11 12 14 15 16];
oemaps.h32inv = [1 2 3 5 6 7 16 15 14 12 11 10 9 13 8 4 29 25 20 24 23 22 21 19 18 17 26 27 28 30 31 32]; % If it is plugged inverted
oemaps.h32ecog = [25:32 24:-1:9 1:8];

oemaps.h64 = [50 49 52 51 54 53 56 55 58 57 60 59 62 61 64 63 33 34 35 37 38 39 41 42 43 45 46 47 48 44 40 36 30 26 22 18 17 20 19 21 24 23 25 28 27 29 32 31 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16];
oemaps.h64inv = [18 17 20 19 22 21 24 23 26 25 28 27 30 29 32 31 1 2 3 5 6 7 9 10 11 13 14 15 16 12 8 4 62 58 54 50 49 52 51 53 56 55 57 60 59 61 64 63 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48];  % If it is plugged inverted

oemaps.acute32 = [31 27 22 18 28 23 21 26 29 24 20 25 30 19 32 17 1 16 3 14 9 10 8 2 7 15 11 12 6 13 5 4];
%oemaps.acute64 = [57 61 62 33 34 35 59 38 63 40 36 56 37 54 39 52 55 50 53 48 51 43 49 41 47 45 42 44 46 60 58 64 1 7 5 19 21 23 20 18 24 16 22 14 17 12 15 10 13 26 11 28 9 29 25 2 27 6 30 31 32 3 4 8];
%oemaps.acute64 = [24,23,22,21,20,19,18,17,16,15,14,13,12,11,10,9,25,26,27,28,29,30,31,32,1,2,3,4,5,6,7,8,56,55,54,53,52,51,50,49,48,47,46,45,44,43,42,41,57,58,59,60,61,62,63,64,33,34,35,36,37,38,39,40];
oemaps.acute64 = [[9 10 11 12 14 16 18 20 22 24 23 21 19 17 15 13] ; [20 18 16 14 12 10 9 11 13 15 17 19 21 22 23 24] + 32 ; [8 7 6 5 3 1 31 29 27 25 26 28 30 32 2 4] ; [29 31 1 3 5 7 8 6 4 2 32 30 28 27 26 25] + 32]';
oemaps.acute64 = oemaps.acute64(:)';

oemaps.acute64_to_64polymap = [24 27 22 28 29 20 18 16 14 12 17 19 21 23 25 26 39 40 42 44 46 48 53 51 49 47 45 36 37 43 38 41 10 15 8 13 6 4 9 2 7 1 31 30 3 32 5 11 54 60 33 62 35 34 64 58 63 56 61 59 52 57 50 55];
[~,oemaps.acute64_to_64polymap]=sort(oemaps.acute64_to_64polymap);

% Headstage order: A1 A2 B1 B2 (HS1 chip faces A1, HS2 chip faces B1)
oemaps.matrix128_2x64 = [25,21,17,29,18,22,30,26,27,31,23,19,20,24,28,36,32,45,44,40,41,35,43,46,34,38,39,33,47,42,37,48,7,11,15,3,16,12,4,8,5,1,9,13,14,10,6,62,2,51,54,58,61,53,52,64,60,57,63,49,56,59,55,50,89,85,81,93,82,86,94,90,91,95,87,83,84,88,92,100,96,109,108,104,105,99,107,110,98,102,103,97,111,106,101,112,71,75,79,67,80,76,68,72,69,65,73,77,78,74,70,126,66,115,118,122,125,117,116,128,124,121,127,113,120,123,119,114];

%% Helpers
oemaps.acute_adapter32 = [20 29 21 28 22 27 23 26 24 25 17 32 19 30 18 31 15 2 14 3 16 1 9 8 10 7 11 6 12 5 13 4]; % mating of the acute probe samtec to the adapter samtect
oemaps.acute_probe_to_adapter_samtec_32 = [16 6 5 15 4 7 3 8 2 9 1 10 14 13 12 11 22 21 20 19 23 25 24 18 26 17 27 29 28 31 30 32]; % mapping from acute adapter to open ephys

%% Probes
oemaps.linear16 = [9 8 10 7 11 6 12 5 13 4 14 3 15 2 16 1];
oemaps.linear32 = [17 16 18 15 19 14 20 13 21 12 22 11 23 10 24 9 25 8 26 7 27 6 28 5 29 4 30 3 31 2 32 1];
oemaps.edge32 = [32 31 30 29 28 27 26 25 24 23 22 21 20 19 18 17 16 15 14 13 12 11 10  9  8  7  6  5  4  3  2  1];
oemaps.buzsaki32 = [1 8 2 7 3 6 4 5 9 16 10 15 11 14 12 13 17 24 18 23 19 22 20 21 25 32 26 31 27 30 28 29];
oemaps.buzsaki64 = [1 8 2 7 3 6 4 5 9 16 10 15 11 14 12 13 17 24 18 23 19 22 20 21 25 32 26 31 27 30 28 29 33 40 34 39 35 38 36 37 41 48 42 47 43 46 44 45 49 56 50 55 51 54 52 53 57 64 58 63 59 62 60 61];
oemaps.a4x8 = [5 4 6 3 7 2 8 1 13 12 14 11 15 10 16 9 21 20 22 19 23 18 24 17 29 28 30 27 31 26 32 25];
oemaps.poly2a32 = [23 10 24 9 25 8 26 7 27 6 28 5 29 4 30 3 31 2 32 1 22 11 21 12 20 13 19 14 18 15 17 16];
oemaps.a2x16 = [9 8 10 7 11 6 12 5 13 4 14 3 15 2 16 1 25 24 26 23 27 22 28 21 29 20 30 19 31 18 32 17] ;
oemaps.polya64 = [27 37 26 38 25 39 24 40 23 41 22 42 21 43 20 44 19 45 18 46 17 47 16 48 15 49 14 50 13 51 12 52 11 53 10 54 9 55 8 56 7 57 6 58 5 59 4 60 3 61 2 62 1 63 28 64 29 36 30 35 31 34 32 33];
oemaps.a8x8 = [5 4 6 3 7 2 8 1 13 12 14 11 15 10 16 9 21 20 22 19 23 18 24 17 29 28 30 27 31 26 32 25 37 36 38 35 39 34 40 33 45 44 46 43 47 42 48 41 53 52 54 51 55 50 56 49 61 60 62 59 63 58 64 57];
oemaps.shank16 = [16:-1:1];
oemaps.ecog = [12 13 20 21 5 7 14 19 26 28 4 8 15 18 25 29 3 11 16 17 22 30 2 9 10 23 24 31 1 6 27 32];
oemaps.nz2oe = [28 22 27 21 23 29 26 20 24 31 25 19 30 18 32 17 16 1 15 3 14 13 2 12 4 5 11 10 6 9 7 8]; % Map from NanoZ to Openephys
oemaps.oe2nz = arrayfun(@(x) find(oemaps.nz2oe==x), 1:32); % Map from Openephys to NanoZ
oemaps.poly3_5mm_25s = [17 16 10 23 18 9 24 15 8 25 19 7 26 14 6 27 20 5 28 13 4 29 21 3 30 12 2 31 22 1 32 11];
oemaps.poly2_4x16 = [6 11 5 12 4 13 3 14 2 15 1 16 7 10 8 9 22 27 21 28 20 29 19 30 18 31 17 32 23 26 24 25 38 43 37 44 36 45 35 46 34 47 33 48 39 42 40 41 54 59 53 60 52 61 51 62 50 63 49 64 55 58 56 57];


% Dorsal left --> Ventral right (left - right as we look at the sites)
oemaps.matrix128 = [8 7 6 5 4 3 2 1 17 15 14 13 12 11 10 9 26 21 22 23 18 19 20 16 30 31 32 27 28 29 24 25  ...
  40 39 38 37 36 35 34 33 49 47 46 45 44 43 42 41 58 53 54 55 50 51 52 48 62 63 64 59 60 61 56 57  ...
  72 71 70 69 68 67 66 65 81 79 78 77 76 75 74 73 90 85 86 87 82 83 84 80 94 95 96 91 92 93 88 89 ...
  104 103 102 101 100 99 98 97 113 111 110 109 108 107 106 105 122 117 118 119 114 115 116 112 126 127 128 123 124 125 120 121];

%% Acute probes
oemaps.L1 = [oemaps.acute32(oemaps.linear32)];
oemaps.L2 = [oemaps.acute32(oemaps.linear32)];
oemaps.L3 = [oemaps.acute32(oemaps.linear32)];
oemaps.L5 = [oemaps.h32(oemaps.linear32)];

oemaps.B8 = oemaps.acute64(oemaps.acute64_to_64polymap(oemaps.poly2_4x16));

oemaps.M5 = [oemaps.h64inv(oemaps.a8x8)];
oemaps.M8 = oemaps.a16om32([6 3 1 2 5 4 7 8 9 10 13 12 15 16 14 11]);
oemaps.M11 = [oemaps.h16(oemaps.shank16)];
oemaps.M12 = oemaps.M8;

oemaps.P1 = [oemaps.acute32(oemaps.poly3_5mm_25s)];
oemaps.P2 = [oemaps.acute32(oemaps.poly2a32)];
oemaps.P4 = [oemaps.h64(oemaps.polya64)];
oemaps.P4inv = [oemaps.h64inv(oemaps.polya64)];
oemaps.P7 = [oemaps.acute32(oemaps.poly2a32)];
oemaps.P9 = [oemaps.P4 oemaps.P4+length(oemaps.P4)];

oemaps.S1 = [oemaps.matrix128_2x64(oemaps.matrix128)];

%% Acute probes: position and broken sites
oemaps.pos.L5 = (1:32)*0.1;
oemaps.sites.L5 = setdiff(1:32, [14 18 26 28]);

oemaps.pos.L3 = (1:32)*0.1;
oemaps.sites.L3 = setdiff(1:32, []);

oemaps.pos.L1 = (1:32)*0.05;
oemaps.sites.L1 = setdiff(1:32, [12 32]);


oemaps.pos.P4 = (1:64)*0.023;
oemaps.sites.P4 = setdiff(1:64, [52]);

oemaps.pos.P7 = (1:32)*0.025;
oemaps.sites.P7 = setdiff(1:32, []);

oemaps.pos.P2 = (1:32)*0.025;
oemaps.sites.P2 = setdiff(1:32, [10 18]);

oemaps.pos.M11 = (1:16)*0.050;
oemaps.sites.M11 = setdiff(1:16, []);

oemaps.pos.Lpfc02 = (1:16)*0.100;
oemaps.sites.Lpfc02 = setdiff(1:16, [9]);

%% Mouse specific 
oemaps.cc07 =  [16+oemaps.h16(oemaps.linear16) 1:16];
oemaps.cc07a =  [1:16 16+oemaps.h16(oemaps.linear16)];
oemaps.op01 =  [oemaps.h32(oemaps.edge32)];
oemaps.op04 = [58,41,55,39,54,42,60,43,53,37,52,44,62,45,51,35,50,46,64,47,49,33,16,48,1,17,15,32,2,18,14,31,3,19,13,30,4,20,12,29,5,21,11,28,6,22,10,27,7,23,9,26,8,24,56,25,57,40,59,38,61,36,63,34];
oemaps.la02 = oemaps.h32(oemaps.edge32);
oemaps.drd01 = []; % mpfc: 5:14, dhpc: 15:22, vHPC: 1:4, 27:32, EMG: 23-26 (can detect EKG)
oemaps.drd02 = [oemaps.h32(oemaps.buzsaki32) 33:48];
oemaps.drd03 = [oemaps.h16(oemaps.linear16) (oemaps.h32(oemaps.buzsaki32) + 16)];
oemaps.drd04 = [];  % mpfc: 5:14, dhpc: 15:22, vHPC: 1:4, 27:32, EMG: 23-26
oemaps.chr01 = [11 10 9 1:8 12:16 25 19 21 23 20 29 17 27 18 32 30 22 28 24 26 31];
oemaps.chr02 = [17 18 19 20 22 30 24 31 28 23 21 29 26 32 25 27 3 1 4 11 10 6 7 9 5 8 2 12 13 14 15 16]; % dat file channels: 1-4 is mPFC, 5:16 is dCA1, 17:28 is vCA1, 29 is resp, 31:32 is EMG
oemaps.chr02inv = [18 27 17 19 25 22 23 26 24 21 20 28 29 30 31 32 1 2 3 4 11 5 10 7 15 13 16 9 12 6 8 14]; % dat file channels: 1-4 is mPFC, 5:16 is dCA1, 17:28 is vCA1, 29 is resp, 31:32 is EMG (headstage inverted in few recordings)
%oemaps.ms01 = [6 14 9 9 15 2 11 4 7 13 16 5 8 1];
oemaps.ms01 = [4 14 9 3 16 1 13 6 7 11 15 5 8 2];

oemaps.ras05 = [oemaps.nz2oe([16 14 12, 24 27 31 25 23 20 30 32 28 26 18 29, 2 3 6 11 13 1 7 8 9 5 4]) 13 14 15 16 31 32 oemaps.h16(oemaps.linear16)+32];  % dat file channels: 1:3 right mPFC, 4:15 left mPFC, 16:26 left dCA1, 27:32 empty, 33:48 left vCA1
oemaps.ras06 = oemaps.nz2oe([17 8 12 16 14 19 21 4, 6 15 7 10 11 13 3 1 2, 27 30 29 31 24 20 28 18 25 26 32 23, 5 9 22]); % dat file channels: 1:8 left mPFC, 9:17 left dCA1, 18:29 left vCA1, 30:32 empty
oemaps.ras02 = [];
oemaps.ras04 = [1:23 25:32 24]; % dat file channels: 1:16 HPC, 17:32 mPFC
oemaps.ras07 = [1:23 25:32 24]; % dat file channels: 1:16 HPC, 17:31 mPFC 32: resp
oemaps.ras08 = [1:23 25:32 24]; % dat file channels: 1:16 HPC, 17:31 mPFC 32: resp
oemaps.ras09 = [1:16 33:48 17:23 25:32 24]; % dat file channels: 1:16 left HPC optrode, 17:32 right HPC drive, 33:47 mPFC 48: resp
oemaps.ras10 = [4 2 10 9 13 6 14 12 16 8 15 1 11 7 3 5 17:30 32 31]; % dat file channels: 1:16 HPC, 17:30 mPFC 31: resp 33:48 HPC drive  --> NEED TO RECHECK - MIXUP
oemaps.ras11 = [1 6 7 13 10 3 8 9 11 14 15 16 4 5 2 12 27 29 30 31 28 32 26 17 18 19 20 21 22 24 23 25]; % 1:16: vHPC optrode, (1: 17:23: dHPC electrode, 24:31: mPFC, 32: resp (1:4 must be cortex above HPC)
oemaps.ras12 = [1:23 25:32 24]; % dat file channels: 1:16 HPC, 17:31 mPFC 32: resp % 1:16: vHPC optrode, (1: 17:23: dHPC electrode, 24:31: mPFC, 32: resp

oemaps.fbr01 = [15:18 1:14 19:32]; % dat file channels: 1:4: mPFC, 5:18 vHPC1, 19:32 vHPC2
oemaps.pfc01 = [[oemaps.h16(end:-1:1)]+32 [1:16 18:21 22:25 29:30 31 32 28 17 26 27]]; %  1:16: mPFC probe (from deep --> superficial layers ) [17:32: HPC, 33:36: LEC 37:40 Pir, 41:42: OB, 43:44:  Thermocouple, 45: Epithelium, 46:48: Not connected]

oemaps.pfc02 = [oemaps.h16(oemaps.linear16)+32 oemaps.h16(oemaps.shank16)+48 1:16 [18 21 19 20]  [23 24 28 22 17 27 25 26] 29:30 31:32]; % 1:16 Linear mPFC, 17:32: 16 Shank mPFC, 33:48: vCA1, 49:52: OB, 53:60: LEC 61:62: EMG, 63:64: Epithelium    The 2 last of LEC are bad and probably some more.
% 1st headstage: 32 ch   --    2nd headstage: linear (most frontal connector)     --   3rd headstage: 16 shank (middle connector)

oemaps.pfc02_meth = [oemaps.h16(oemaps.shank16)+32 1:16 [18 21 19 20]  [23 24 28 22 17 27 25 26] 29:30 31:32]; % 1:16 Linear 16 Shank mPFC, 17:32: vCA1, 33:36: OB, 37:44: LEC 45:46: EMG, 47:48: Epithelium    The 2 last of LEC are bad and probably some more.
% 1st headstage: 32 ch   --    2nd headstage: 16 shank (middle connector)


oemaps.ecog01 = [1:9 10:16 oemaps.h32ecog(oemaps.ecog)+16 49:64]; % 1st headstage: electrodes, 2nd headstage: ecog, 3rd headstage: 16 channel HPC
% in dat file: 1:9 mPFC, 10:15: EEG (anterior to posterior), 16: resp, 17:48: ECOG (from anterior left to posterior right (left-right first, anterior - posterior second), 49:64: ventral CA1
% Note: make sure to delete channels by running the command ecog01_channeldel (1-16 first and AUX7-9)

oemaps.fbr03 = [15:16 9:14 17:32 7:8 3:4 1:2 5:6]; % 1:2: right mPFC (50um wires), 3:8: left mPFC (optrode), 9:24: left CA1 (optrode), 25: RSA EEG, 26: M1 EEG, 27:28: OB, 29:30: Epithelium, 31:32: EMG

% Before converting, keep only channels: 1,6,7,8,9:14,25,26,28,29,32
oemaps.resp01 = [5:10 2 3 4 11 12 13 14 1 15]; % 1:6 EEG channels (from front to back), 3x resp channels, 2x left rostrsal intercostal, 1x left caudal intercostal, 1x right caudal intercostal, 2x nucheal EMG; 3x pressure sensor

%% Head-fixed
oemaps.hf02 = [3 1 2 6:16 4 5]; % Ch. 1: resp, 2:14: dCA1, 15,16:nothing
oemaps.hfh01pre = [1 2 3]; % before chronic, Ch. 1: EMG, Ch.2: Resp, Ch3: EEG
oemaps.hfh01pre_b = [2 3]; % before chronic, EMG broke  Ch. 2: resp, Ch3: EEG  % for 3D recording
oemaps.hfh01post = [1:16]; % 2:12 dCA1, 16 resp
oemaps.hfh01post_new = [16 2:12]; % 1: resp  2:133 dCA1 (Run with append 0)
oemaps.hfh02 = [1 2]; % before chronic Ch. 1: EMG, Ch.2: Resp
oemaps.hfh02post = [1:16]; % 1:3 5:8 dCA1, 13 resp
oemaps.hfp02pre = 1:16;
oemaps.hfp02post = [1:16]; % 2:9 11:12 mPFC, 13 EMG, 14 OB
oemaps.ob01pre = [1 2 3 4]; % before chronic Ch. 1: right resp, Ch.2: left resp, Ch.3-4: EMG
oemaps.ob01pre_ob = [1 2 3 4 5]; % before chronic Ch. 1: right resp, Ch.2: left resp, Ch.3-4: EMG, Ch. 5: OB
oemaps.ob02pre = [1:6]; % before chronic Ch. 1: red thermocouple (-), Ch2: yellow thermocoule (+), 3: resp, 4: OB, 5:6: EMG
oemaps.ob02double = [1:4]; % 1:2 EMG 3: OB, 4: resp

% hfh03 conversion
oemaps.hfh03pre = [];
oemaps.hfh03_double1 = [1:3 oemaps.P4+3 oemaps.P9+3+length(oemaps.P4)]; % 1:resp; 2-3: EMG
oemaps.hfh03_double2 = [1:3 oemaps.P7+3 oemaps.P9 + length(oemaps.P7)+3]; % 1:resp; 2-3: EMG
oemaps.hfh03_double3 = [1:3 oemaps.P9+3 ]; % 1:resp; 2-3: EMG
oemaps.hfh03_P9_CA1_M8_mPFC = [1:3 oemaps.P9+3 oemaps.M8 + length(oemaps.P9)+3]; % 1:resp; 2-3: EMG

oemaps.hfh03_P4_M11 = [1:3 oemaps.P4+3 oemaps.M11+length(oemaps.P4)+3]; %

oemaps.hfh03_B8_P9 = [1:3 oemaps.B8+3 oemaps.P9+length(oemaps.B8)+3]; %

oemaps.hfh04 = [1:6];
oemaps.hfh03_B8_P9_16 = [1:16 oemaps.B8+16 oemaps.P9+length(oemaps.B8)+16]; %

oemaps.hf03 = [1:5]; % 1: left osn, 2: right osn, 3: left OB, 4: right OB, 5: emg/ekg
oemaps.hf04 = [1 4 2 3 5]; % 1: osn, 2: osn, 3: ob , 4: ob , 5: 
oemaps.hf05 = [1 4 2 3 5 6]; % 1: , 2: , 3: , 4: , 5: , 6: 

%oemaps.CNE4 = [3 4 1 2 31 32 28 27 30 29 23 8 7 6 5 25 9 10 11 12 14 13 16 15 18 17 20 19 22 21 24 26 56 55 54 53 51 52 49 50 47 48 45 46 43 44 41 39 62 61 64 63 34 33 37 38 35 36 42 57 58 59 60 40]';
oemaps.CNE4 = [38 37 40 39 42 41 45 46 43 44 49 33  34 35 36 48 63 64 61 62 60 59 58 57 56 55 54 53 52 51 50 47 1 2 3 4 6 5 8 7 10 9 12 11 14 13 16 17 28 27 26 25 24 23 19 20 21 22 15 31 32 29 30 18]';
%oemaps.H3 = [[70;72;74;77;75;81;66;68;80;67;65;76;78;73;71;69;95;93;92;90;88;86;84;82;79;83;85;87;89;91;94;96;33;35;38;40;42;44;46;48;49;45;43;41;39;37;36;34;60;58;56;51;53;47;64;62;50;61;63;54;52;55;57;59]]';
oemaps.H3 = [[38,40,42,45,43,49,34,36,48,35,33,44,46,41,39,37,63,61,60,58,56,54,52,50,47,51,53,55,57,59,62,64,1,3,6,8,10,12,14,16,17,13,11,9,7,5,4,2,28,26,24,19,21,15,32,30,18,29,31,22,20,23,25,27]];
oemaps.E2converted = [[23,28,14,15,16,24,25,11,12,13,21,26,8,9,10,22,27,5,6,7,19,30,29,3,4,17,20,31,32,2,63,1,37,59,60,57,45,36,35,61,62,47,46,33,34,64,48,18,41,38,52,49,50,42,39,53,54,51,43,40,58,55,56,44]];
oemaps.E2          = [[38,37,40,39,42,41,45,46,43,44,49,33,34,35,36,48,63,64,61,62,60,59,58,57,56,55,54,53,52,51,50,47,1,2,3,4,6,5,8,7,10,9,12,11,14,13,16,17,28,27,26,25,24,23,19,20,21,22,15,31,32,29,30,18]];
%oemaps.M2temp = [38 40 42 45 43 49 34 36 48 35 33 44 46 41 39 37 63 61 60 58 56 54 52 50 47 51 53 55 57 59 62 64 1 3 6 8 10 12 14 16 17 13 11 9 7 5 4 2 28 26 24 19 21 15 32 30 18 29 31 22 20 23 25 27];
oemaps.M2 = [[38;40;42;45;43;49;34;36;48;35;33;44;46;41;39;37;63;61;60;58;56;54;52;50;47;51;53;55;57;59;62;64;2;4;5;7;9;11;13;17;16;14;12;10;8;6;3;1;27;25;23;20;22;31;29;18;30;32;15;21;19;24;26;28]]';
oemaps.H9 = [[[61,38,60,40,58,42,56,45,54,43,52,49,50,34,47,36,51,48,53,35,55,33,57,44,59,46,62,41,64,39,1,37,3,63,6,8,10,12,14,16,17,13,11,9,7,5,4,2,28,26,24,19,21,15,32,30,18,29,31,22,20,23,25,27]]];
oemaps.H8 = [63	38	61	40	60	42	58	45	56	43	54	49	52	34	50	36	47	48	51	35	53	33	55	44	57	46	59	41	62	39	64	37	28	1	26	3	24	6	19	8	21	10	15	12	32	14	30	16	18	17	29	13	31	11	22	9	20	7	23	5	25	4	27	2];
% still missing H8
