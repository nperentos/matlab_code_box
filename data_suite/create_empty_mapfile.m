animalname = 'hf05';

files = list_files(['/storage2/nikolas/data/Recordings/' animalname],[animalname '*']);

for f=1:length(files);
    mapfn = get_lfp_filename(files{f},'map');
    mapfn = get_lfp_filename(files{f},'dat');
    if ~exist(mapfn) & exist(datfn);
        fclose(fopen(mapfn, 'w'));
    end
    
end;

%%
x = 80 * randn(1, 30);
y = 80 * randn(size(x));
r = randi(1500, size(x));
c = randi(10, size(x));

fig = figure;

scatter(x, y, r, c, 'filled', 'MarkerEdgeColor', 'k')

%--PLOTLY--%

% strip = false => preserve MATLAB style!

response = fig2plotly(fig, 'filename', 'matlab-bubble-chart',  'strip', false,'offline',true);hf04_P4_ca1_2500_craamma_M12_mpfc_2200