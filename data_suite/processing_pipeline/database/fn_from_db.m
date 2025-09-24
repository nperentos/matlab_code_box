function fns = fn_from_db(idx)

datapath = '/storage2/nikolas/data/Recordings/';
T = load_recording_db;

if islogical(idx);
    idx = find(idx);
end;

fns = {};
for c=1:length(idx);    
    fn = [datapath cell2mat(T{idx(c),'AnimalName'}) '/' cell2mat(T{idx(c),'SessionName'})];
    fns{c} = fn;
end

fns = fns';

%if length(fns)==1
%    fns = fns{1};
%end;
