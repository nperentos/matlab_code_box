function fix_face_csv(fn)
%%
data = load_data(fn);

facefn = get_lfp_filename(data.info.fn,'face.new.csv');
fid = fopen(facefn); header = fgetl(fid); fclose(fid);
nfields = length(split_string(header,' '));

fid = fopen(facefn); csvdata = textscan(fid,repmat('%f',1,nfields),'HeaderLines',1,'Delimiter',' '); fclose(fid);

facefn = get_lfp_filename(data.info.fn,'face.old.csv');
fid = fopen(facefn); header = fgetl(fid); fclose(fid);
nfields = length(split_string(header,' '));

fid = fopen(facefn); csvdataold = textscan(fid,repmat('%f',1,nfields),'HeaderLines',1,'Delimiter',' '); fclose(fid);

% To fix the case of one file that had a jump (to 0) of the timestamps.
%idx = find(csvdataold{1}<1);
%csvdataold{1}(idx:end) = csvdataold{1}(idx:end) + csvdataold{1}(idx-1);

csvdata{1} = csvdataold{1};
csvdata = cell2mat(csvdata);
csvdata(:,1) = csvdata(:,1) - csvdata(1,1);
facefn = get_lfp_filename(data.info.fn,'face.csv');

dlmwrite(facefn,csvdata,'delimiter',' ','roffset',1,'precision',10);
