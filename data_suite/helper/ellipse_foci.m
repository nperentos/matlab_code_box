function [f1,f2] = ellipse_foci(x, y, a, b, rotation)

theta = -rotation * (pi / 180);
c = sqrt((a/2)^2 + (b/2)^2);
f1 = [c*cos(theta)+x,c*sin(theta)+y];
f2 = [-c*cos(theta)+x,c*sin(-theta)+y];

