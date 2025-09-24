function T = getCarouselDataBase()

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% T = getCarouselDataBase loads a single-sheet google spreadsheet in the
% form of a table T that holds variables pertaining to each recording
% session.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DOCID = '10AK8pGCEKtEbVWkAcL6-LFnBGBFmn3Fo3gHwRomzG2U';

% fetch the spreadsheet
C = GetGoogleSpreadsheet(DOCID);

% first row is variable names - trim them
T = cell2table(C(2:end,:));

% extract first row as variable names
T.Properties.VariableNames = C(1,:);

% there are some fields that we know should be numbers so we will manually
% modify them here. Not very elegant, but given that only rarely would we
% add new fields, then this is not too costly to edit later.

% vars = {'n_of_sessions','thetaCh','respCh','blocks','SUA','MUA','merge'};
% 
% for i = 1:length(vars)
%     test = getfield(T,vars{i});
%     test2 = str2double(test);
%     %setfield(T,vars{i}) = test2;
%     eval(['T.',vars{i},'=test2;']);
%     clear test test2;
% end