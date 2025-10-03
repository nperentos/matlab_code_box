function [elements,indexes] = find_string_in_cell(data,str,column)
indexes =~cellfun(@isempty,strfind(data(:,column),str));
elements =data(~cellfun(@isempty,strfind(data(:,column),str)),:);