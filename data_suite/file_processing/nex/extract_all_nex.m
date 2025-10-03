% Options
directory = 'D:\4Hz project\Cecilia Data\nex_big\';
directory_behavior = 'D:\4Hz project\Cecilia Data\behavior\';
samplingrate = 1000;


% Beginning of code
directory = directory_sanitizer(directory);
directory_behavior = directory_sanitizer(directory_behavior);
files = dir([directory '*.nex']);

for f=1:length(files)
    tic;
    filename = [directory files(f).name];
    disp(filename);
    temp = str2cell(files(f).name,'.');
    temp = str2cell(temp{1},'_');
    animal = temp{1};
    session = temp{2};
    
    try
        temp = str2cell(files(f).name,'.');
        beh_file = dir([directory_behavior,temp{1},'.*']);
        behavior_filename = [directory_behavior beh_file.name];
        positions = extract_behavior(behavior_filename,2);
        freeze = calculate_freezing_from_raw(positions(:,1),2);
    catch
        disp(['Could not find behavior : ',behavior_filename]);
        freeze = [];
    end
    
    try
        convert_nex_file(filename,samplingrate,animal,session,freeze); 
        try; mailer('nikolaskaralis@gmail.com',['Succesfully Complete : ' animal '_' session],'OK', 'herry.lab@gmail.com','herry.lab'); catch; end;
    catch
        disp(['Problem with file : ',filename]);
        try; mailer('nikolaskaralis@gmail.com',['Problem : ' animal '_' session],'Problem', 'herry.lab@gmail.com','herry.lab'); catch; end;
    end;
    toc;
end;