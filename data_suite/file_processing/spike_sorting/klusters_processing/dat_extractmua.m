function dat_extractmua(fn, delflag)
if nargin<2; delflag = 1; end; % by default delete the .fil file

fn = directory_sanitizer(fn);
currentdir = pwd; % Preserve directory
cd(fn)

fn1 = get_lfp_filename(fn,'');
fn1 = fn1(1:end-1);

hpfn = get_lfp_filename(fn,'fil');
[xmlfn,sessionname] = get_lfp_filename(fn,'xml');

%% Compute high-pass signal
if ~exist(get_lfp_filename(fn,'fil'))
    system(['ndm_hipass ' fn1]);
end

%% Compute MUA from high-pass signal
settings = xml2struct(xmlfn);
nChannels = str2num(settings.parameters.acquisitionSystem.nChannels.Text);

for c=1:nChannels;
    disp(['Converting channel ' num2str(c)]);
    tmp = load_binary(hpfn,c);    
    tmp1 = abs(hilbert(double(tmp)));
    clear tmp
    tmp = decimate(tmp1,30);
    if c==1; mua = zeros(nChannels,length(tmp)); end;
    mua(c,:) = tmp;
end

disp('Saving MUA');
binary_save(get_lfp_filename(fn,'mua'),mua);

if delflag; delete(get_lfp_filename(fn,'fil')); end;
cd(currentdir)
disp('MUA extraction complete')

