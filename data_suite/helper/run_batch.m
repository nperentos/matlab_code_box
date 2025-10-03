function run_batch(functionname,rootdir, arguments)
    if nargin>2
        arguments = [',' arguments];
    else
        arguments = '';
    end;
    
    rootdir = directory_sanitizer(rootdir);
    folders = dir(rootdir);
    for folder=1:size(folders,1)
        if ~strcmp(folders(folder).name,'.') && ~strcmp(folders(folder).name,'..') && folders(folder).isdir == 1 
            directory = directory_sanitizer(strcat(rootdir,folders(folder).name));
            disp(folders(folder).name)
            command = [functionname '(''' directory '''' arguments ')'];
            eval(command)
        end;
    end;