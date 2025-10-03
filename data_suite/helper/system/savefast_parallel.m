function savefast_parallel(filename,ad,variabname)
eval([variabname '=ad;']);
savefast(filename,variabname);
end

