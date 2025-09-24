function find_ripples_again(fn);
try;
    %%
    data = load_data(fn);
    
    states = data.states;
    statesfn = get_lfp_filename(fn,'states');
    
    pyrch = [];
    posib = {'pyr'};
    for c=posib
        if isfield(data.channels, c)
            pyrch = data.channels.(c{1})(1);
            pyrtmp = getmd(data,pyrch); % Only for the first channel
        end
    end
    
    if isfield(data.channels,'rippleref')
        ref = getmd(data,data.channels.rippleref);
    elseif isfield(data.channels, 'cortex')
        ref  = getmd(data,data.channels.cortex(1));
    elseif isfield(data.channels, 'eeg')
        ref  = getmd(data,data.channels.eeg(1));
    elseif isfield(data.channels, 'mpfc')
        ref = getmd(data,data.channels.mpfc(1));
    elseif isfield(data.channels, 'mPFC')
        ref = getmd(data,data.channels.mpfc(1));
    else
        ref=[];
    end
    
    if ~isempty(pyrch)
        if ~isempty(ref);
            states.swr = find_ripples(pyrtmp,'thr',2.5,'plot',0,'periods',[data.states.quiet ; data.states.sws],'refsig',ref); % Remove ripples inside theta periods
        else
            states.swr = find_ripples(pyrtmp,'thr',2.5,'plot',0,'periods',[data.states.quiet ; data.states.sws]); % Remove ripples inside theta periods
            disp('SWR calculated')
        end
    end
    
    clear ref pyrtmp
    save(statesfn,'states','-v7.3')
    disp(fn)
    disp('States saved')
catch
    disp('Data not found');
end
