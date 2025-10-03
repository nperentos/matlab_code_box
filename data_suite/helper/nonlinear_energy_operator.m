% Calculates the Nonlinear Energy Operator
% which is defined as y(n) = x(n)^2 - x(n-1)*x(n+1)
% It uses the instanteous amplitude and frequency of the signal
% and it can be used for the spike detection
%
% Appends a 0 at the beginning and end of the signal to have the same length as the input
% Like that it is not causing a phase shift.
%
% References : 
% Kim and Kim, IEEE Transactions on Biomedical Engineering, 2000
% Hill et al., J.Neuroscience, 2011 
% 
%
% Dependencies : None
%
% Updates : 27/11/2013 (NK) :Converted the code to work with 2D matrices
% Added the option for variable n
%
%
% Date : 17/05/2013
% Author : Nikolas

function y=nonlinear_energy_operator(x,n)
if nargin<2; n=1; end;
%x=x(:)';
%y=x(2:end-1).^2;
%y=[0 y - x(1:end-2).*x(3:end) 0];
transposed = 0;
if ~isvector(x) && ismatrix(x); if size(x,2)<size(x,1); x=x'; transposed=1; end; end;

% The commented out part is the correct/original version.
%y=[zeros(size(x,1),1) x(:,2:end-1).^2 - x(:,1:end-2).*x(:,3:end) zeros(size(x,1),1)];

% This version allows for the number of n to be modified.
% This corresponds to takling points further apart in time. Not sure what
% it would mean though.
% In order to work correctly without spurious time shifting, n MUST be an
% odd number.
y=[zeros(size(x,1),(n+1)/2) x(:,n+1:end-1).^2 - x(:,1:end-n-1).*x(:,n+2:end) zeros(size(x,1),(n+1)/2)];

% Convert back to original shape for the matrix case
if transposed;
    y=y';
end;