global probemaps

probemaps = struct();

%% L1
v = 50;
h = 0;
nchan = 32;

xcoords = ones(nchan,1)*h;
ycoords = [0:nchan-1]'*v;
kcoords = ones(nchan,1);
probemaps.L1.xcoords = xcoords;
probemaps.L1.ycoords = ycoords;
probemaps.L1.kcoords = kcoords;

%% L3
v = 100;
h = 0;
nchan = 32;

xcoords = ones(nchan,1)*h;
ycoords = [0:nchan-1]'*v;
kcoords = ones(nchan,1);
probemaps.L3.xcoords = xcoords;
probemaps.L3.ycoords = ycoords;
probemaps.L3.kcoords = kcoords;

%% L5
v = 100;
h = 0;
nchan = 32;

xcoords = ones(nchan,1)*h;
ycoords = [0:nchan-1]'*v;
kcoords = ones(nchan,1);
probemaps.L5.xcoords = xcoords;
probemaps.L5.ycoords = ycoords;
probemaps.L5.kcoords = kcoords;

%% P1
v = 25;
h = 18;
nchan = 32;

xcoords([1 2:3:nchan]) = h;
xcoords(3:3:nchan) = 0;
xcoords(4:3:nchan) = 2*h;

idx = [1 2:3:nchan];
ycoords(idx) = (0:length(idx)-1)*25;
idx = 3:3:nchan;
ycoords(idx) = (0:length(idx)-1)*25+40;
idx = 4:3:nchan;
ycoords(4:3:nchan) = (0:length(idx)-1)*25+40;
kcoords = ones(nchan,1);

probemaps.P1.xcoords = xcoords;
probemaps.P1.ycoords = ycoords;
probemaps.P1.kcoords = kcoords;

%% P2
v = 25;
h = 50;
nchan = 32;


xcoords = ones(nchan,1)*h;
xcoords(2:2:length(xcoords)) = 0;
ycoords = [0:nchan-1]'*v;
kcoords = ones(nchan,1);
probemaps.P2.xcoords = xcoords;
probemaps.P2.ycoords = ycoords;
probemaps.P2.kcoords = kcoords;

%% P4
v = 23;
h = 30;
nchan = 64;

xcoords = ones(nchan,1)*h;
xcoords(2:2:length(xcoords)) = 0;
ycoords = [0:nchan-1]'*v;
kcoords = ones(nchan,1);
probemaps.P4.xcoords = xcoords;
probemaps.P4.ycoords = ycoords;
probemaps.P4.kcoords = kcoords;

%% P4half
v = 23;
h = 30;
nchan = 32;

xcoords = ones(nchan,1)*h;
xcoords(2:2:length(xcoords)) = 0;
ycoords = [0:nchan-1]'*v;
kcoords = ones(nchan,1);
probemaps.P4half.xcoords = xcoords;
probemaps.P4half.ycoords = ycoords;
probemaps.P4half.kcoords = kcoords;


%% P7
v = 25;
h = 43;
nchan = 32;

xcoords = ones(nchan,1)*h;
xcoords(2:2:length(xcoords)) = 0;
ycoords = [0:nchan-1]'*v;
kcoords = ones(nchan,1);
probemaps.P7.xcoords = xcoords;
probemaps.P7.ycoords = ycoords;
probemaps.P7.kcoords = kcoords;

%% P9
v = 23;
h = 30;
nchan = 64;

xcoords = ones(nchan,1)*h;
xcoords(2:2:length(xcoords)) = 0;
ycoords = [0:nchan-1]'*v;
kcoords = ones(nchan,1);

kcoords = [kcoords ; kcoords*2];
xcoords = [xcoords ; xcoords+200];
ycoords = [ycoords ; ycoords];

probemaps.P9.xcoords = xcoords;
probemaps.P9.ycoords = ycoords;
probemaps.P9.kcoords = kcoords;

%% M5
v = 200;
h = 200;
nchan = 64;
shanks = 8;

xcoords = [];
kcoords = [];
for c=1:shanks
    xcoords = cat(1,xcoords,ones(nchan/shanks,1)*h*(c-1));
    kcoords = cat(1,kcoords,c*ones(nchan/shanks,1));
end
ycoords = repmat([0:(nchan/shanks-1)]*v,1,shanks)';
probemaps.M5.xcoords = xcoords;
probemaps.M5.ycoords = ycoords;
probemaps.M5.kcoords = kcoords;

%% M11
v = 0;
h = 50;
nchan = 16;

xcoords = (0:nchan-1)*h;
ycoords = [0:nchan-1]'*v;
kcoords = ones(nchan,1);
probemaps.M11.xcoords = xcoords;
probemaps.M11.ycoords = ycoords;
probemaps.M11.kcoords = kcoords;

%% M12
probemaps.M12 = probemaps.M11;

%% M8
probemaps.M8 = probemaps.M11;

%% B8
v = 23;
h = 200;
nchan = 64;
shanks = 4;

xcoords = [];
kcoords = [];
for c=1:shanks
    tmp = ones(nchan/shanks,1)*h*(c-1)-17/2;
    tmp(2:2:length(tmp)) = tmp(2:2:length(tmp))+17;
    xcoords = cat(1,xcoords,tmp);
    %xcoords = cat(1,xcoords,ones(nchan/shanks,1)*h*(c-1));
    kcoords = cat(1,kcoords,c*ones(nchan/shanks,1));
end
ycoords = repmat([0:(nchan/shanks-1)]*v,1,shanks)';
probemaps.B8.xcoords = xcoords;
probemaps.B8.ycoords = ycoords;
probemaps.B8.kcoords = kcoords;

%% Buzsaki32
v = 40;
h = 40;
shankspacing = 200;
nchan = 32;
shanks = 4;

xcoords = [];
kcoords = [];
for c=1:shanks   
    tmp = nan(nchan/shanks,1); 
    tmp([1:2:nchan/shanks])=0;
    tmp([2:2:nchan/shanks])=40;    
    xcoords = cat(1,xcoords,tmp+(c-1)*shankspacing);    
    kcoords = cat(1,kcoords,c*ones(nchan/shanks,1));
end
ycoords = repmat([0:(nchan/shanks-1)]*v,1,shanks)';
probemaps.Buzsaki32.xcoords = xcoords;
probemaps.Buzsaki32.ycoords = ycoords;
probemaps.Buzsaki32.kcoords = kcoords;

%% Edge32
v = 100;
h = 0;
nchan = 32;

xcoords = ones(nchan,1)*h;
xcoords(2:2:length(xcoords)) = 0;
ycoords = [0:nchan-1]'*v;
kcoords = ones(nchan,1);
probemaps.Edge32.xcoords = xcoords;
probemaps.Edge32.ycoords = ycoords;
probemaps.Edge32.kcoords = kcoords;

%% Linear16
v = 100;
h = 0;
nchan = 16;

xcoords = ones(nchan,1)*h;
xcoords(2:2:length(xcoords)) = 0;
ycoords = [0:nchan-1]'*v;
kcoords = ones(nchan,1);
probemaps.Linear16.xcoords = xcoords;
probemaps.Linear16.ycoords = ycoords;
probemaps.Linear16.kcoords = kcoords;

%% S1
v = 200;
h = 200;
nchan = 128;
shanks = 16;

xcoords = [];
kcoords = [];
for c=1:shanks    
    kcoords = cat(1,kcoords,c*ones(nchan/shanks,1));
end

for c=1:4
    xcoords = cat(1,xcoords,ones(nchan/shanks,1)*h*(c-1));
end
xcoords = repmat(xcoords,4,1);

ycoords = repmat([0:(nchan/shanks-1)]*v,1,shanks)';
probemaps.S1.xcoords = xcoords;
probemaps.S1.ycoords = ycoords;
probemaps.S1.kcoords = kcoords;

%% CM1 (A4x8-10mm-200-400)
v = 200;
h = 400;
nchan = 32;
shanks = 4;

xcoords = [];
kcoords = [];
for c=1:shanks
xcoords = cat(1,xcoords,ones(nchan/shanks,1)*h*(c-1));
kcoords = cat(1,kcoords,c*ones(nchan/shanks,1));
end
ycoords = repmat([0:(nchan/shanks-1)]*v,1,shanks)';
probemaps.CM1.xcoords = xcoords;
probemaps.CM1.ycoords = ycoords;
probemaps.CM1.kcoords = kcoords;

%% CNE4 (cambridge neurotech e series with 4 shanks)
nchan = 16; % per shank
shanks = 4;
v = 20;
h = linspace(0,70,nchan)'; mid = length(h)/2;
xcoords = [h(1:mid),flipud(h(mid+1:end))];
xcoords=xcoords';xcoords = xcoords(:)
xcoords = [xcoords; xcoords+250; xcoords+500; xcoords+750];
ycoords = repmat(flipud([0:v:v*(nchan-1)]'),4,1);
kcoords = [ones(nchan,1); 2*ones(nchan,1); 3*ones(nchan,1); 4*ones(nchan,1)];
probemaps.CNE4.xcoords = xcoords;
probemaps.CNE4.ycoords = ycoords;
probemaps.CNE4.kcoords = kcoords;
plot3(probemaps.CNE4.xcoords,probemaps.CNE4.ycoords,probemaps.CNE4.kcoords,'or');
xlabel('x');ylabel('y');zlabel('k');












