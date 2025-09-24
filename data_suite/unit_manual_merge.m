function mergelist = unit_manual_merge(filebase)
%%
info = get_datfile_info(filebase);

unitsfn = get_lfp_filename(filebase,'units');
load(unitsfn,'units','-mat');

%%
unit_pairs = [];
for c=1:size(units,1);
    %[~,idx]=spikes_in_periods(units.channel,(units.channel(c)-1):(units.channel(c)+2));
    idx  = find(units.channel == units.channel(c));
    idx = idx(~(idx==c));
    for k=1:length(idx);
        pair = [c idx(k)];
        if isempty(unit_pairs) | sum(unit_pairs(:,1) == pair(2) & unit_pairs(:,2) == pair(1))==0 % to not keep the reverse pair
            unit_pairs = cat(1,unit_pairs,pair);
        end
    end
end

score = [];
for c=1:size(unit_pairs,1);
    tmp = corrcoef(units.waveform{unit_pairs(c,1)}(20:40),units.waveform{unit_pairs(c,2)}(20:40));
    score(c) = tmp(1,2);
end
[score,idx]=sort(score,'descend');
unit_pairs = unit_pairs(idx,:);

mergelist = zeros(size(unit_pairs,1),1);

%%
h = fig;
set(h, 'WindowKeyPressFcn', @get_keypress)
global keyp

c=1;
while c<=size(unit_pairs,1);
    
    subplot(3,2,[1 3 5])
    plot(units.template{unit_pairs(c,1)}','k');
    hold on;
    plot(units.template{unit_pairs(c,2)}','r');
    hold off;
    xlim([0 60]); box off;  removeaxis('xy'); xlim([0 60]);
    title([num2str(c) '/' num2str(size(unit_pairs,1))]);
    
    T = [units.spikes{unit_pairs(c,1)}(:)];
    G = [ones(length(units.spikes{unit_pairs(c,1)}),1)];
    [acc1,t] = CCG(T,G,0.001*info.fs,0.05/0.001,info.fs,1,'count');
    
    T = [units.spikes{unit_pairs(c,2)}(:)];
    G = [ones(length(units.spikes{unit_pairs(c,2)}),1)];
    [acc2,t] = CCG(T,G,0.001*info.fs,0.05/0.001,info.fs,1,'count');
    
    T = [units.spikes{unit_pairs(c,1)}(:) ; units.spikes{unit_pairs(c,2)}(:)];
    G = [ones(length(units.spikes{unit_pairs(c,1)}),1) ; ones(length(units.spikes{unit_pairs(c,2)}),1)];
    [acc12,t] = CCG(T,G,0.001*info.fs,0.05/0.001,info.fs,1,'count');
    
    subplot(3,2,[2])
    bar(t,acc1,'k'); box off; xlim([-50 50]); 
    if mergelist(c)==1; title('Merge'); end;
    subplot(3,2,[4])
    bar(t,acc2,'r'); box off; xlim([-50 50]); 
    subplot(3,2,[6])
    bar(t,acc12,'g');box off; xlim([-50 50]); 
    
    proceed=0;
    while ~proceed
        keyp = [];
        waitforbuttonpress;
        if strcmp(keyp,'n') | strcmp(keyp,'rightarrow');
            if c<size(units,1);
                c=c;
                proceed = 1;
            else
                proceed = 0;
            end;
            
        elseif strcmp(keyp,'p') | strcmp(keyp,'leftarrow');
            if c>1;
                c=c-2;
                proceed = 1;
            else
                proceed = 0;
            end;
            
        elseif strcmp(keyp,'m');
            mergelist(c) = 1;
            proceed = 1;
            
        elseif strcmp(keyp,'u'); %unmerge
            mergelist(c) = 0;
            proceed = 1;
            
        elseif strcmp(keyp,'s');
            c=size(unit_pairs,1);
            proceed = 1;
        end
        c=c+1;
    end
end

close
mergelist = logical(mergelist);
mergelist = unit_pairs(mergelist,:);