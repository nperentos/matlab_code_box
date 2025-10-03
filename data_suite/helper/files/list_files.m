function [fullpaths, filenames]=list_files(base_dir, rule)
base_dir = directory_sanitizer(base_dir);
if nargin<1 || isempty(base_dir); base_dir = '.'; end;
if nargin<2 || isempty(rule); rule = ''; end;

tmp=dir([base_dir rule]);
filenames = arrayfun(@(x)x.name, tmp,'un',0);
fullpaths = cellfun(@(x)[base_dir x],filenames,'un',0);


idx = strcmp(filenames,'.') | strcmp(filenames,'..');
filenames = filenames(~idx);
fullpaths = fullpaths(~idx);