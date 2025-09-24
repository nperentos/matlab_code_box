function T = load_recording_db(key);

if nargin<1; key = '1lDKOeWDsX_wCrUjbWJIUfNWSLU2pcrEjVUGVyxNzB3Y'; end;

%% Load spreadsheet
csvdata = GetGoogleSpreadsheet(key);

%% Get basic info
animal_col = find(cellfun(@sum,strfind(csvdata(1,:),'Animal')));
session_col = find(cellfun(@sum,strfind(csvdata(1,:),'Session')));
animals = unique(csvdata(:,animal_col));

%% Remove empty rows
csvdata(strcmp(csvdata(:,session_col),''),:) = [];

%% Fix names of variables
varnames = csvdata(1,:);
varnames = cellfun(@(x) strrep(x,' ','_'),varnames,'un',0);
varnames = cellfun(@(x) strrep(x,'-','_'),varnames,'un',0);

%% Convert to table
T  = cell2table(csvdata(2:end,:),'VariableNames',varnames);
