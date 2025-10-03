% Creates a .fbr (matlab) file that contains the photometry signals and
% photo time


function [fbr, photo_time, out]=align_doric_photometry_lockin(filebase,ttl_ch, recalc)

if nargin<3; recalc=0; end;
fbrfn = get_lfp_filename(filebase,'fbr');
doricfn = get_lfp_filename(filebase,'doric.mat');

if exist(fbrfn) & ~recalc;    
    tmp = load(fbrfn,'-mat');
    fbr = tmp.fbr;
    photo_time = tmp.photo_time;
    
    tmp = load(doricfn);
    out = tmp.out;
    
    disp('.fbr file exists and is loaded. If you want to recalculate, run again with the recalc flag');
    return
end
%% Load CSV
if exist(doricfn);
    tmp = load(doricfn);
    out = tmp.out;
    disp('Photometry data loaded');
else
    disp('Converting photometry data');
    csvfn = get_lfp_filename(filebase,'csv');
    tic;
    out = read_doric_photometry_lockin(csvfn);
end

%% Find LFP TTL
tic;
lfpfn = get_lfp_filename(filebase);
ttl = load_binary(lfpfn,ttl_ch);
[beg, fin] = find_ttl_periods(ttl, 0.1, 1000, 20);
ttl_lfp = beg(1);
lfp_length = length(ttl);
disp('LFP TTL loaded');

%% Align LFP and Photometry
fbr = [];

tmp = [nan(1,ttl_lfp(1)-1) out.sig470(out.ttl_idx:end,:)'];

l = min(length(tmp),lfp_length);
fbr.sig470 = tmp(1:l);

tmp = [nan(1,ttl_lfp(1)-1) out.sig405(out.ttl_idx:end,:)'];
fbr.sig405 = tmp(1:l);

tmp = [nan(1,ttl_lfp(1)-1) out.sig470_ref(out.ttl_idx:end,:)'];
fbr.sig470_ref = tmp(1:l);

tmp = [nan(1,ttl_lfp(1)-1) out.sig405_ref(out.ttl_idx:end,:)'];
fbr.sig405_ref = tmp(1:l);

tmp = [nan(1,ttl_lfp(1)-1) out.sig470_dem(out.ttl_idx:end,:)'];
fbr.sig470_dem = tmp(1:l);

tmp = [nan(1,ttl_lfp(1)-1) out.sig405_dem(out.ttl_idx:end,:)'];
fbr.sig405_dem = tmp(1:l);

tmp = [nan(1,ttl_lfp(1)-1) out.ttl_trace(out.ttl_idx:end,:)'];
fbr.ttl_trace = tmp(1:l);

photo_time = [ttl_lfp/1000 lfp_length/1000];

%% Save

save(fbrfn,'fbr','photo_time');

toc;