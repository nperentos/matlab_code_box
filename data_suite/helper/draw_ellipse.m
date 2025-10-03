% Input: x, y = coordinates of the center
% a Semimajor axis
% b Semiminor axis
% rotation: Angle of the ellipse (in degrees)

function X = draw_ellipse(x, y, a, b, rotation,plotflag,plotstyle)
if nargin<7 || isempty(plotstyle); plotstyle = '-k'; end;
if nargin<6 || isempty(plotflag); plotflag = 1; end;
if nargin<5 || isempty(rotation); rotation = 0; end;

steps = 36;
beta = -rotation * (pi / 180);
sinbeta = sin(beta);
cosbeta = cos(beta);

alpha = linspace(0, 360, steps)' .* (pi / 180);
sinalpha = sin(alpha);
cosalpha = cos(alpha);

X = x + (a * cosalpha * cosbeta - b * sinalpha * sinbeta);
Y = y + (a * cosalpha * sinbeta + b * sinalpha * cosbeta);

if plotflag; 
    jplot(X, Y, plotstyle); 
    %hold on;
    %[f1,f2] = ellipse_foci(x,y,a,b,rotation);
    %plot(f1(1),f1(2),'*r');
    %plot(f2(1),f2(2),'*b');    
end;

X = [X Y];
end