%% 
oemaps.h16 = [9 11 12 16 13 14 15 10 7 2 3 4 1 5 6 8];
oemaps.h32 = [17 18 19 21 22 23 32 31 30 28 27 26 25 29 24 20 13 9 4 8 7 6 5 3 2 1 10 11 12 14 15 16];
oemaps.linear16 = [9 8 10 7 11 6 12 5 13 4 14 3 15 2 16 1];
oemaps.linear32 = [17 16 18 15 19 14 20 13 21 12 22 11 23 10 24 9 25 8 26 7 27 6 28 5 29 4 30 3 31 2 32 1];
oemaps.edge32 = [32 31 30 29 28 27 26 25 24 23 22 21 20 19 18 17 16 15 14 13 12 11 10  9  8  7  6  5  4  3  2  1];
oemaps.buzsaki32 = [1 8 2 7 3 6 4 5 9 16 10 15 11 14 12 13 17 24 18 23 19 22 20 21 25 32 26 31 27 30 28 29];

%% Mouse specific
oemaps.cc07 =  [16+oemaps.h16(oemaps.linear16) 1:16];
oemaps.cc07a =  [1:16 16+oemaps.h16(oemaps.linear16)];
oemaps.op01 =  [oemaps.h32(oemaps.edge32)];
oemaps.drd02 = [oemaps.h32(oemaps.buzsaki32) 33:48];
oemaps.drd03 = [oemaps.h16(oemaps.linear16) (oemaps.h32(oemaps.buzsaki32) + 16)];