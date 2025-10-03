function split_plx_files_parallel(directory,filename, parallel_flag)
directory = directory_sanitizer(directory);
directory_out = directory_sanitizer([directory filename '_channels']);

file = [directory filename];

[n,t] = plx_adchan_samplecounts(file);
channelslist = find(t~=0)-1; % The channels index is 0 based in plexon, so I substract 1

if nargin<3
    parallel_flag=0;
end;

if parallel_flag
    parfor i = 1:length(channelslist)
        ch = channelslist(i);
        read_data(ch,file,directory_out);
    end;
else
    for i = 1:length(channelslist)
        ch = channelslist(i);
        read_data(ch,file,directory_out);
    end;
end;

[n, events] = plx_event_ts(file,3);
file_out = [directory_out 'events.mat'];
save(file_out,'events');

plx_close(filename)

function read_data(ch,file,directory_out)
    channel = struct();
    [channel.frequency,channel.samplecounts,channel.timestamp,temp,channel.values]=plx_ad_v(file,ch);
    channel.number = ch+1;
    disp(channel.number);
    save([directory_out 'ch' num2str(channel.number) '.mat'],'channel');
    clear channel