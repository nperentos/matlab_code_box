% Description : 
%
% Algorithm :  
%
% Input : A directory path
%
% Output : A sanizited directory path
%
% Author : Nikolas Karalis
% Date : April 2013
%
% Dependencies : None
%
% Updates : 
%

function directory = directory_sanitizer(directory,create)
if nargin<2; create=0; end;
%if isempty(directory); return; end;
% Check if it works on a Mac or Windows and use the correct character for
% moving between folders.
term_char = set_term();

% Check if the directory provided ends with the term_char and if not, add
% it.
if directory(end) ~= term_char
    directory = [directory term_char];
end;

% Check if the folder exists and if it doesn't create it.
if exist(directory,'file')==0 & create
    mkdir(directory);
end;