function [files_list, programs_list] = get_dependencies(files)

files_list = cell(1,length(files));
programs_list = cell(1,length(files));

for c=1:length(files)    
    [fList,pList] = matlab.codetools.requiredFilesAndProducts(files{c});
    files_list{c} = fList';
    programs_list{c} = cellfun(@(x,y) [x '_' y], {pList.Name}', {pList.Version}','un',0);
end