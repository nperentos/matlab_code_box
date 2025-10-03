function polyspikegroups(fn,overlap,comment)

if nargin<2; overlap=2; end;
if nargin<3; comment=''; end;
fn = directory_sanitizer(fn);
[xmlfn,sessionname] = get_lfp_filename(fn,'xml');
settings = xml2struct(xmlfn);
nchannels = str2num(settings.parameters.acquisitionSystem.nChannels.Text);
spikegroups1 = get_lfp_filename(fn,'spikegroups');

fid = fopen(spikegroups1,'w');
fprintf(fid,'# %s \n',sessionname{1});
fprintf(fid,'# Template \n\n');
fprintf(fid,'# Note that channel numbers start from 0s \n\n');


for c=0:(nchannels-overlap)
    
    fprintf(fid,'%.0f,%.0f,%.0f # %s \n',[(0:overlap-1) + c],comment);
end

fclose(fid);

disp('Poly spike group file created');