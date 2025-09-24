function data = fix_data_filepath(data, newpath);

if nargin<2; newpath = '/storage2/nikolas/data/Recordings/'; end;

data.info.fn = strrep(data.info.fn,'/storage/lu/data/rec/',newpath);
data.info.fn = strrep(data.info.fn,'/storage2/nikolas/data/Recordings/',newpath);
data.info.fn = strrep(data.info.fn,'/storage/nikolas/data/Recordings/',newpath);
