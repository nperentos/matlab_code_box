function oemap2viewermap(map, filename)
% makeOEmapFile created a file with the map given, readable by Open Ephys,
% to be able to look at the mapped channels while recording. If you don't 
% have a map already, look into OEmapsShare.m to check if the map you want 
% was already created by somebody, or if you can reuse part of what has 
% already been done.

nChan = length(map);

%% Writing on File
file = fopen(filename,'w');
fprintf(file,'%s \n', '{');
fprintf(file,'%s \n', '    "0": {');
fprintf(file,'%s \n', '      "mapping": [');

for i = 1:nChan
    fprintf(file,'%s \n', ['        ' num2str(map(i)) ',']);
end

fprintf(file,'%s \n', '      ],');
fprintf(file,'%s \n', '      "reference": [');

for i = 1:nChan
    fprintf(file,'%s \n', '        -1,');
end

fprintf(file,'%s \n', '      ],');
fprintf(file,'%s \n', '      "enabled": [');

for i = 1:nChan
    fprintf(file,'%s \n', '        true,');
end

fprintf(file,'%s \n', '      ]');
fprintf(file,'%s \n', '    },');
fprintf(file,'%s \n', '    "refs": {');
fprintf(file,'%s \n', '      "channels": [');

for i = 1:4
    fprintf(file,'%s \n', '        -1,');
end

fprintf(file,'%s \n', '      ]');
fprintf(file,'%s \n', '    },');
fprintf(file,'%s \n', '    "recording": {');
fprintf(file,'%s \n', '      "channels": [');

for i = 1:nChan
    fprintf(file,'%s \n', '        false,');
end

fprintf(file,'%s \n', '      ]');
fprintf(file,'%s \n', '    }');
fprintf(file,'%s \n', '  }');
fclose(file);
end