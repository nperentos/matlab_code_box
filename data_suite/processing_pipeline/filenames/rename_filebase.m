function rename_filebase(fn,newname)

tmp = split_string(fn,'/');
fb = [strjoin(tmp(1:end-1),'/') '/'];
name = tmp{end};
movefile(fn,[fb newname]);

fn = directory_sanitizer([fb newname],1);
l = list_files(fn,[name '*']);

for c=1:length(l)
    ff = split_string(l{c},'.');
    nn = [fb newname '/' newname '.' strjoin(ff(2:end),'.')];
    movefile(l{c},nn)
end
