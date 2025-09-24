function generateDLCpaths(full_path_to_spreadsheet)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% generateDLCpaths(full_path_to_spreadsheet) runs through a excel file that
% holds all the recording information and discovers sessions where video 
% data from the top position exists. It generates a txt file that holds all 
% the paths with these videos. The txt file is then used to run all videos 
% as a batch process through the DLC code. 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% OLD
% if nargin ~= 1
%     T = getCarouselDataBase;
%     %readtable('/storage2/perentos/data/recordings/GOODCOPY_animals_and_recording_session_particulars.xlsx','Sheet','AnalysisVars');
% else     
%     T = readtable(full_path_to_spreadsheet,'Sheet','AnalysisVars');
% end
% %% write contents of the xlsx file to a text file for DLC to use
% fid = fopen('/storage2/perentos/data/recordings/DLCpaths.txt','w');
% for jj = 1 : height(T)
%     fprintf(num2str(jj));
%     fle = dir(fullfile(getFullPath(T.session{jj}),'video/top*.avi'));
%     if length(fle) == 1
%         %fprintf( fid, '%s\n', ['''',fullfile(fle.folder,fle.name),'''']);
%         fprintf( fid, '%s\n', fullfile(fle.folder,fle.name));
%     end    
%     if jj<10; fprintf('\b'); else; fprintf('\b\b'); end
%     %pause(0.2);
% end
% fclose(fid); fprintf('\n');
% 
% disp('The file was succesfully generated');
% disp('Please inspect it at /storage2/perentos/data/recordings/DLCpaths.txt');



%% NEW
if nargin ~= 1
    T = getCarouselDataBase;
    %readtable('/storage2/perentos/data/recordings/GOODCOPY_animals_and_recording_session_particulars.xlsx','Sheet','AnalysisVars');
else     
    T = readtable(full_path_to_spreadsheet,'Sheet','AnalysisVars');
end

%% limited list
for i = 1:length(myDBBehOnly)
    j(i) = find(strcmp(T.session,myDBBehOnly{i}));
end


%% write contents of the xlsx file to a text file for DLC to use
fid = fopen('/storage2/perentos/data/recordings/DLCpaths.txt','w');
for jj = 1 : height(T) %j
    fprintf(num2str(jj));
    fle = dir(fullfile(getFullPath(T.session{jj}),'video/top*.avi'));
    if length(fle) == 1
        %fprintf( fid, '%s\n', ['''',fullfile(fle.folder,fle.name),'''']);
        fprintf( fid, '%s\n', fullfile(fle.folder,fle.name));
    end    
    if jj<10; fprintf('\b'); else; fprintf('\b\b'); end
    %pause(0.2);
end
fclose(fid); fprintf('\n');

disp('The file was succesfully generated');
disp('Please inspect it at /storage2/perentos/data/recordings/DLCpaths.txt');

%% for the pupil dlc
%% write contents of the xlsx file to a text file for DLC to use
% fid = fopen('/storage2/perentos/data/pupil3-NP-2020-10-16/paths_to_analysis_vids.txt','w');
% for jj = j%1 : height(T) %j
%     fprintf(num2str(jj));
%     fle = dir(fullfile(getFullPath(T.session{jj}),'video/*pupil.avi'));
%     if length(fle) == 1
%         %fprintf( fid, '%s\n', ['''',fullfile(fle.folder,fle.name),'''']);
%         fprintf( fid, '%s\n', fullfile(fle.folder,fle.name));
%     end    
%     if jj<10; fprintf('\b'); else; fprintf('\b\b'); end
%     %pause(0.2);
% end
% fclose(fid); fprintf('\n');
% 
% disp('The file was succesfully generated');
% disp('Please inspect it at /storage2/perentos/data/recordings/DLCpaths.txt');