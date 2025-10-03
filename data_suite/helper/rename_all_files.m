function rename_all_files(fn,pat1,pat2)
l = list_files(fn,[pat1 '*']);

for c=1:numel(l);
    [tmp1,tmp2,tmp3]=fileparts(l{c});
    tmp1 = directory_sanitizer(tmp1);
    movefile(l{c}, [tmp1 pat2 tmp3]);
end