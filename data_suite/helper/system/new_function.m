% new_function
% 
% Description: It creates a function template or appends one to an existing
% file.
%
%
% Input: 
% 
% Ouput: 
% 
% 
% Dependencies: directory_sanitizer
% 
% Author: Nikolas Karalis
% Date: 20-Dec-2013
%
% Copyright: 

% Updates: * I need to add the conditioning for more/all escape characters.

function new_function(function_name,author,append_flag)
if nargin<2 || isempty(author); author = 'Nikolas Karalis'; end; % For deployment, I'll change the default author to ''
if nargin<3 || isempty(append_flag); append_flag = 0; end;

fname = split_string(function_name,'/');
if isempty(fname(end)); fname = fname{end-1}; else; fname = fname{end}; end;
filename = [function_name '.m'];

content = ['%% ', fname, '\n%% ','\n%% Description: \n%% \n%% \n%% Input:','\n%% \n%% Ouput:','\n%% \n%% ',...
    '\n%% Dependencies: \n%% \n%% Author: ', author, '\n%% Date: ', date, '\n%% \n%% Copyright: \n%% \n%% \n%% Updates: \n\n\n'];
mode = 'a'; % Normally I use append mode, to make sure I don't overwrite accidentally an existing function.

% If append flag is provided, then the comments are added in the beginning
% of the file. 
if append_flag
    try;
        c = fileread(filename);
        c=strrep(c,'%','%%'); %This conditions the percentage symbol otherwise it causes problems.
        c=strrep(c,'\n','\\n'); %This conditions the percentage symbol otherwise it causes problems.
        content = strcat(content,c);    
        mode = 'w';
    catch;
        disp('No such file to append to.');
        return;
    end;
else 
    content = [content,'function ',function_name,'()\n'];
end;

try    
    fid = fopen(filename,mode);
    fprintf(fid,content);
    fclose(fid);
    eval(['edit ' filename]);   
catch
   disp('Could not create the function.');
   return;
end;