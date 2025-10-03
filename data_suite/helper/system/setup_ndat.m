fprintf('Please select the path to the Neural Data Analysis Toolbox to add it to the Matlab path \nPress Enter to continue.\n')
pause
try
    dir_name=uigetdir;
    addpath(genpath(dir_name));
    savepath
    fprintf('Neural Data Analysis Toolbox was added to the path. Thank you!\n')
catch
    fprintf('Nothing was added th the path. Please try again!\n')
end;