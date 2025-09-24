function openDatFile(fileBaseOrDataBaseRowNumber)


T = getCarouselDataBase;OEmaps;


% find the session inside the carousel data base
if strcmp(class(fileBaseOrDataBaseRowNumber),'char')
    idx = fileBaseOrDataBaseRowNumber;
    idx = find(strcmp(T.session,idx));
elseif strcmp(class(fileBaseOrDataBaseRowNumber),'double')
    %idx = T.session{fileBaseOrDataBaseRowNumber-1};
    idx = fileBaseOrDataBaseRowNumber;
end

display(['Opening in neuroscope session ', T.session{idx}]);
pth = getfullpath(T.session{idx});
cd(pth);
ddd = dir('*.dat');
fle = [ddd.folder,'/',ddd.name];
eval(['!neuroscope ',fle]);