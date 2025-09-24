function unit_manual_channel_setting(filebase);

info = get_datfile_info(filebase);

unitsfn = get_lfp_filename(filebase,'units');
load(unitsfn,'units','-mat');

%%
h = fig;
set(h, 'WindowKeyPressFcn', @get_keypress)
global keyp
changed = 0;
c=1;
while c<=size(units,1);
    
    temp = units.template{c};
    wf = units.waveform{c};
    [~,wfch]=max(sum(wf == temp,2)); % find which template channel is the waveform
    tmp1 = min(temp(:,20:40),[],2);
    tmp1 = tmp1 - [0:1000:(length(tmp1)-1)*1000]';
    [~,idx]=min(tmp1);
    if idx~=wfch;
        jplot(temp','k')
        hold on; jplot(temp(idx,:),'g');
        hold on; jplot(temp(wfch,:),'r');
        hold off;                
        box off
        %legend({'','New','Original'}); legend('boxoff')     
        xlim([0 61])
        removeaxis('xy');
        verticalline(31,'k');
        proceed=0;
        while ~proceed
            keyp = [];
            waitforbuttonpress;
            if strcmp(keyp,'c');
                disp(['Previous channel: ' num2str(units.channel(c))]);
                units.channel(c) = units.channel(c) + (idx - wfch);
                disp(['New channel: ' num2str(units.channel(c))]);
                proceed = 1;
                changed = changed+1;
            elseif strcmp(keyp,'s');
                proceed = 1;
            end
        end
    end
    c=c+1;
end
close

%%
if changed>0;
    while 1;
        s = input('Save units? (will replace the original file) [y/n] ','s');
        if strcmp(s,'y');
            disp('Units saved')
            save(unitsfn,'units');
            break;
        elseif strcmp(s,'n')
            disp('Changes not saved');
            break;
        end
    end
end