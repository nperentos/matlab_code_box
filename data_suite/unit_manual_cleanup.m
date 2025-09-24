% It gives you a GUI that shows you the waveform, template and autocorr 
% and enables you to select using keyboard one of the following options:
% (g) good
% (d) delete
% (m) mua
% (p) go to previous unit
% (n) go to next unit

% only after you reach the last unit, it asks you if you want to save or not
% if you choose to save, it will delete the units that are marked "delete" and will replace the .unit file

function units = unit_manual_cleanup(filebase);

info = get_datfile_info(filebase);

unitsfn = get_lfp_filename(filebase,'units');
load(unitsfn,'units','-mat');

%%

accmid = (length(units.autocorr{1})-1)/2 + 1;

%unittype = cell(size(units,1),1);
unittype = units.type;
h = fig;
set(h, 'WindowKeyPressFcn', @get_keypress)
global keyp

c=1;
while c<=size(units,1);
    [~,idx]=max(sum(units.waveform{c} == units.template{c},2)); % find which template channel is the waveform
    
    subplot(3,5,[2 3]); jplot(units.waveform{c},'k'); xlim([0 60]); box off; removeaxis('xy'); title([num2str(c) '/' num2str(size(units,1))]);
    subplot(3,5,[6:9]); 
    h1 = bar([-30:30],units.autocorr{c}((accmid-30):(accmid+30)),'k');
    hold on;   
    h1 = bar([-2:1:2],units.autocorr{c}((accmid-2):(accmid+2)),'r'); verticalline(0,'r--');
    hold off;
    xlim([-30 30]); box off;
    
    subplot(3,5,[11:14]); 
    h1 = bar([-100:100],units.autocorr{c}((accmid-100):(accmid+100)),'k');    
    xlim([-100 100]); box off; title(unittype{c});
    
    subplot(3,5,[5 10 15]); 
    jplot(units.template{c}','k');  
    hold on;
    jplot(units.template{c}(idx,:),'r');
    hold off;
    removeaxis('xy'); xlim([0 60]);    
    
    proceed=0;
    while ~proceed
        keyp = [];
        waitforbuttonpress;
        if strcmp(keyp,'d');
            unittype{c} = 'delete';
            proceed = 1;
            title(unittype{c}); pause(0.5);
        elseif strcmp(keyp,'g');
            unittype{c} = 'good';
            proceed = 1;
            title(unittype{c}); pause(0.5);
        elseif strcmp(keyp,'m');
            unittype{c} = 'mua';
            proceed = 1;
            title(unittype{c}); pause(0.5);
        elseif strcmp(keyp,'o');
            unittype{c} = 'ok';
            proceed = 1;
            title(unittype{c}); pause(0.5);    
        elseif strcmp(keyp,'p') | strcmp(keyp,'leftarrow');;
            if c>1;
                c=c-2;
                proceed = 1;
            else
                proceed = 0;
            end;
        elseif strcmp(keyp,'n') | strcmp(keyp,'rightarrow');
            if c<size(units,1);
                c=c;
                proceed = 1;
            else
                proceed = 0;
            end;
        end
    end
    
    c=c+1;
end;
close

units.type = unittype;
todel = find(strcmp(units.type,'delete'));

disp('The following units are marked for deletion: ');
disp(num2str(todel(:)'));

%units = units(~strcmp(units.type,'delete'),:);

%%
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