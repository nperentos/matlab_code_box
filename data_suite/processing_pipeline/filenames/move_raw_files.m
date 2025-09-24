% filebase = '/storage2/nikolas/data/Recordings/';
% rawbase = '/storage2/nikolas/data/raw/';
% 
% %%
% filebase = '/storage/lu/data/rec/';
% rawbase = '/storage/lu/data/raw/';
% 
% %%
% 
% rawbase = directory_sanitizer(rawbase);
% filebase = directory_sanitizer(filebase);
% 
% animals = list_files(filebase);
% 
% for an=1:length(animals);
%     sessions = list_files(animals{an});
%     
%     for s=1:length(sessions);
%         
%         tmp = list_files(sessions{s},'raw*');
%         if ~isempty(tmp)
%             [~,sessionname] = get_lfp_filename(sessions{s});
%             tmp{1}
%             outfn = [rawbase sessionname{1}]            
%             movefile(tmp{1},outfn);
%         end
%         
%     end    
% end
% 
% 
% %% Move to del files
% 
% rawbase = directory_sanitizer(rawbase);
% filebase = directory_sanitizer(filebase);
% 
% animals = list_files(filebase);
% 
% for an=1:length(animals);
%     sessions = list_files(animals{an});
%     
%     for s=1:length(sessions);
%         
%         tmp = list_files(sessions{s},'todel*');
%         if ~isempty(tmp)
%             [~,sessionname] = get_lfp_filename(sessions{s});
%             tmp{1}
%             outfn = [rawbase sessionname{1} '/todel'];
%             try;
%                 movefile(tmp{1},outfn);
%             catch;
%                 mkdir([rawbase sessionname{1}]);
%                 movefile(tmp{1},outfn);
%             end
%         end
%         
%     end    
% end
clc
for i = 1:length(myDB) 
    fclose('all');
    fileBase = myDB{i};
    goto(fileBase);
    cd ..
    if exist(['raw_',fileBase])
        [SUCCESS] = movefile(['raw_',fileBase],'/storage2/perentos/archiveNP/');
        display(num2str(SUCCESS))
    end
end