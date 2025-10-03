% Creates a .fbr (matlab) file that contains the photometry signals and
% photo time
% Takes about 5 min / hour of recording


function [fbr, photo_time]=align_doric_photometry(filebase,ttl_ch, recalc)

if nargin<3; recalc=0; end;
fbrfn = get_lfp_filename(filebase,'fbr');

if exist(fbrfn) & ~recalc;    
    tmp = load(fbrfn,'-mat');
    fbr = tmp.fbr;
    photo_time = tmp.photo_time;
    disp('.fbr file exists and is loaded. If you want to recalculate, run again with the recalc flag');
    return
end
%% Load CSV
csvfn = get_lfp_filename(filebase,'csv');
tic;
out = read_doric_photometry_old(csvfn);

%% Find LFP TTL
lfpfn = get_lfp_filename(filebase);
ttl = load_binary(lfpfn,ttl_ch);
[beg, fin] = find_ttl_periods(ttl, 0.1, 1000, 20);
ttl_lfp = beg(1);
lfp_length = length(ttl);

%% Align LFP and Photometry
fbr = [];
fbr(1,:) = [nan(1,ttl_lfp(1)-1) out.sig470(out.ttl_idx:end,:)'];
fbr(2,:) = [nan(1,ttl_lfp(1)-1) out.sig405(out.ttl_idx:end,:)'];
l = min(length(fbr),lfp_length);
fbr = fbr(:,1:l);
photo_time = [ttl_lfp/1000 lfp_length/1000];

%% Save

save(fbrfn,'fbr','photo_time');

toc;