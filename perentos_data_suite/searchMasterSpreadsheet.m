function out = searchMasterSpreadsheet(fileBase,fld)
% fileBase: the data folder name
% fld:      the field to look for 
% searches a fixed spreadsheet for a particular recording and a particular
% variable for that recording. For now we will have a hardcoded spreadsheet
% this doesnt generalise well but its OK for a single user

%T = readtable('/storage2/perentos/data/recordings/animals_and_recording_session_particulars.xlsx','Sheet','AnalysisVars');
T = getCarouselDataBase();
idx = find(strcmp(T.session,fileBase));

if isempty(idx)
    error('there is no recording by this name, aborting...');
end

out = cell2mat(table2array(T(idx,fld))); % or if you want to convert some of the variables here, use below:

% tmp = table2array(T(idx,fld));
% if strcmp(class(tmp),'double')
%     out = tmp;
% elseif strcmp(class(T.Session(1)),'cell')
%    out = cell2mat(tmp);
% end