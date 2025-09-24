% Default window : 10 ms
% Nikolas Karalis
% Date : 26/11/2013

function lfp=lfp_envelope(lfp, samplingrate, window, method)

% This takes care that lfp is provided in the form : row x column =
% channels x time so that the transformations are applied on the time dim
transposed=0;
if ~isvector(lfp) && ismatrix(lfp); if size(lfp,2)>size(lfp,1); lfp=lfp'; transposed=1; end; end;

% Input handling
if nargin<4; method = 'lowess'; end;
if nargin<3; window=0.01; end;

% keep the original shape of the input
dims =size(lfp); 

span = samplingrate * window;
lfp = smoothn(abs(hilbert(lfp)),span,method);
lfp = reshape(lfp, dims); % reshape the output to match the input

% Convert back to original shape for the matrix case
if transposed;
    lfp=lfp';
end;