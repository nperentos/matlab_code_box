function [out] = goto(fileBase)
% [out] = goto(fileBase) changes the current path to the fileBase's
% got to 'processed' path and return path to 'out' variable
cd(getfullpath(fileBase));
pwd;
out = pwd;