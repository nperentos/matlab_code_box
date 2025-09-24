function apply_neuroscope_template(filename,templatefilebase)
if nargin<2; disp('Please provide all arguments'); return; end;
if strcmp(filename,templatefilebase); disp('Destination is same as source.'); return; end;

%templatefilebase = '/storage2/nikolas/code/neuroscope_templates/';
%templatefilename = [templatefilebase templatename '.xml'];
%templatenrsfilename = [templatefilebase templatename '.nrs'];
templatefilename = get_lfp_filename(templatefilebase,'xml');
templatenrsfilename = get_lfp_filename(templatefilebase,'nrs');

filenamexml = get_lfp_filename(filename,'xml');
filenamenrs = get_lfp_filename(filename,'nrs');

if ~exist(templatefilename); 
    disp('No template found');
    return;
end;

if ~exist(filenamexml); 
    disp('No data found');
    return;
end;

templatexml = xml2struct(templatefilename);
templateChannels = str2num(templatexml.parameters.acquisitionSystem.nChannels.Text);

filexml = xml2struct(filenamexml);
fileChannels = str2num(filexml.parameters.acquisitionSystem.nChannels.Text);

if fileChannels == templateChannels;
    movefile(filenamexml,[filenamexml '.bkp']);
    struct2xml(templatexml,filenamexml);
    copyfile(templatenrsfilename, filenamenrs);
    disp('Neuroscope template applied.');
else
    disp('Different number of channels. Cannot apply template.');
end;


