function files = fn_from_fn(files,filebase)
global datapath
if nargin<2; filebase = datapath; end;
filebase = directory_sanitizer(filebase);

convertback = 0;
if ~iscell(files);
    files = {files};
    convertback = 1;
end

for f=1:length(files);
    if strcmp(files{f},''); continue; end;
    an = split_string(files{f},'_');
    an = an{1};
    files{f} = [filebase an path_separator files{f}];
end

if convertback;
    files = files{1};
end