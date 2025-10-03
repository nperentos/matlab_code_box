% Parallel version
%%%%%%%%%%%%%%%%%%%%%%%%%
matlabpool open local 4

%% Options
directory = directory_sanitizer('F:\Data\Nikolas\toreextractchannels\');
email_address = 'nikolaskaralis@gmail.com';

%% Main block
files = dir([directory '*.plx']);
for f=1:size(files,1)
    tic;
    disp(files(f).name);
    split_plx_files_parallel(directory,files(f).name,1);
    tstop = toc;
    %mailer(email_address,['Status update - ' files(f).name],[files(f).name ' is complete. Time elapsed : ' num2str(tstop)], 'herry.lab@gmail.com','herry.lab')
end;

%% Close paralllel
matlabpool close

%% Comments
% For not parallel version, just comment out the first and last line
% and run the split_plx_files_parallel with last argument 0.