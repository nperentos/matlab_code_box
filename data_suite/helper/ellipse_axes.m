function [m1_major,m2_major, m1_minor, m2_minor] = ellipse_axes(x, y, a, b, rotation)

theta = -rotation * (pi / 180);
c = sqrt((a/2)^2 + (b/2)^2);
f1 = [c*cos(theta)+x,c*sin(theta)+y];
f2 = [-c*cos(theta)+x,c*sin(-theta)+y];


%% Major axis
x=a*cos(rotation*pi/180) + x; 
y=a*-sin(rotation*pi/180) + y;

m1_major = [x y];

x=-a*cos(rotation*pi/180) + x; 
y=-a*-sin(rotation*pi/180) + y;

m2_major = [x y];

%% Minor axis
x=b*sin(rotation*pi/180) + x; 
y=b*cos(rotation*pi/180) + y;

m1_minor = [x y];

x=-b*sin(rotation*pi/180) + x; 
y=-b*cos(rotation*pi/180) + y;

m2_minor = [x y];
