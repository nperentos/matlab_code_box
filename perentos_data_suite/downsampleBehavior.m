function downsampleBehavior(fileBase,varargin)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function  downsampleBehavior(fileBase,varargin) downsamples 
% the behavior.mat structure to a time bin of 10ms (unless otherwise defined)
% also does the same for the behTrialMatrices variables (where necessary)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% PREREQUISITES
    options = {'init',1,'track',0,'session_pth',[],'time_bin',10};
    options = inputparser(varargin,options);   
    
    if ~isempty(options.session_pth)
        pth = getfullpath(fileBase,options.session_pth); % path to session
    else
        pth = getfullpath(fileBase); % path to session
    end

    tau = options.time_bin;
    
    disp 'loading behavioral trial matrices ...'
    load('behTrialsMatrices.mat');
    disp 'loading session and behavior structures...'     
    [session, behavior] = loadSession(fileBase);
    SR = session.info.SR_LFP;
    
    
%% DOWNSAMPLE RAW BEHAVIOR MATRIX
    beh = behavior.data.data;        
    behavior_downsampled.data = resample(beh,SR/tau,SR);
    behavior_downsampled.SR = tau;
    behavior_downsampled.times = [1:tau:length(beh)]';
    behavior_downsampled.name = behavior.name;
    behavior_downsampled.idxTrials = session.helper.idxTrials;
    behavior_downsampled.idxMov = session.helper.idxMov;
    behavior_downsampled.notes = 'the behavioral matrix of behavior.mat but downsampled';
    %sanity plots
    %     figure; 
    %     jplot(beh(:,25));hold on;
    %     jplot([1:10:length(behavior_downsampled)],behavior_downsampled(:,25),'*r');
    goto(fileBase);
    save(['behavior_downsampled_',num2str(tau),'ms.mat'],'behavior_downsampled');
    

%% DOWNSAMPLE BEHAVIORAL TRIAL MATRICES - TIME DOMAIN ONLY
    if strcmp(session.info.taskType,'continuous')
        % relevant variables are traj, traj_pos
        % we will cycle through them one by one and downsample
        B = A;
        for i = 1:length(A)
            for j = 1:length(A(i).traj)
                for k = 1:length(A(i).traj{1,j})
                    tmp = A(i).traj{1,j}{1,k};
                    B(i).traj{1,j}{1,k} = resample(tmp,SR/tau,SR);
                    tmp = A(i).traj_pos{1,j}{1,k};
                    B(i).traj_pos{1,j}{1,k} = downsample(tmp,SR/tau);
                end
            end
        end                        
    else
        error('non-contnuous tasks not implemented yet');
    end
    goto(fileBase);
    A = B;
    save(['behTrialsMatrices_downsampled_',num2str(tau),'ms.mat'],'A');
