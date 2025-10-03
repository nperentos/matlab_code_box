function tmp = load_parallel(filename,variabname)
load(filename,variabname);
eval(['tmp = ' variabname ';']);
end
