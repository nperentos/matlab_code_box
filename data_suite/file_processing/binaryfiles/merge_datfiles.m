function merge_datfiles(filebase)

%% Prepare filenames
listfn  = get_lfp_filename(filebase,'list');
basedir = directory_sanitizer(fileparts(filebase));

files = readlines(listfn);
files = cellfun(@(x) [basedir x],files,'un',0);
datfiles = get_lfp_filename(files,'dat');

out_dat = get_lfp_filename(filebase,'dat');
out_xml = get_lfp_filename(filebase,'xml');
out_map = get_lfp_filename(filebase,'map');
catcommand = ['cat ' cell2mat(cellfun(@(x) [x ' '], datfiles,'un',0)) ' > ' out_dat];

%% Make concatenation
tic; s = system(catcommand); toc;

if s;
    disp('There was an error concatenating');
    return;
end

%% Create xml and map file
copyfile(get_lfp_filename(files{1},'xml'),out_xml);

if ~exist(out_map);
    try;
        copyfile(get_lfp_filename(files{1},'map'),out_map);
    catch;
        disp('Please create a .map file.')
        return
    end
end
