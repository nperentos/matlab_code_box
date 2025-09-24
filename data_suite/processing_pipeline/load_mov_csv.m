function mov = load_mov_csv(data,csvfn,smooth)

if nargin<3; smooth=1; end;

fid = fopen(csvfn); header = fgetl(fid); fclose(fid);
tmp = split_string(header,' ');
nfields = sum(cellfun(@(x) ~strcmp(x,''),tmp)); % doing these instead of just length, because in some cases there is an extra space at the end of the string.

fid = fopen(csvfn); csvdata = textscan(fid,repmat('%f',1,nfields),'HeaderLines',1,'Delimiter',' '); fclose(fid);

m = memmap_datfile(data.info.fn,'lfp');
maxt = m.Format{2}(2);

% Freely moving tracking
if length(csvdata)>=14 % freely moving
     t = csvdata{1};
     mov = csvdata{14};
     t = (t-t(1))/1000;

elseif length(csvdata)==2 % head fixed
     t = csvdata{1};
     mov = csvdata{2};
     t = (t-t(1))/1000;

elseif length(csvdata)==1 % old head-fixed (no frame times saved)
    mov = csvdata{1};
    t = linspace(0,maxt/data.info.sr,length(mov));
end

if length(mov)~=length(t);
    l = min(length(mov),length(t));
    t = t(1:l);
    mov = mov(1:l);
end

mov = mov(:);
mov = resample(mov,t,data.info.sr);

if length(mov)>=maxt;
    mov = mov(1:maxt);
else
    mov1 = zeros(maxt,1);
    mov1(1:length(mov))=mov;
    mov = mov1;
    clear mov1
end

if smooth;
    mov = abs(diff(mov));
    mov = smooth_gauss(mov,1*data.info.sr,0.5*data.info.sr);
end;

mov = mov(:)';