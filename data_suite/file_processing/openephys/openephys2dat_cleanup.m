function openephys2dat_cleanup(fn)
fn = directory_sanitizer(fn);

% Create raw folder
if ~exist([fn 'raw'])
    mkdir([fn 'raw']);
elseif ~isempty(list_files([fn 'raw'],'*'))
    disp('Raw folder exists. Terminating')
    return
end

% Move all raw files to raw folder
files = list_files(fn,'*.continuous');
files = cat(1,files,list_files(fn,'*.events'));
files = cat(1,files,list_files(fn,'*.openephys'));
files = cat(1,files,list_files(fn,'*.xml'));
for c=1:length(files); movefile(files{c},[fn 'raw']); end;

% Move all processed files to main folder
if numel(list_files([fn 'processed'],'*'))>2;
    movefile([fn 'processed/*'],fn)
end

% Remove empty processed folder (if empty)
if numel(list_files([fn 'processed'],'*'))<=2;
    rmdir([fn 'processed'])
end
