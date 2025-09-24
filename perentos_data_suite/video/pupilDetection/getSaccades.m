function [out] = getSaccades(fileBase,varargin)
% extracts saccade timepoints and saves them in saccades.mat    

%% PREREQUISITES
    % fileBase = 'NP49_2020-06-30_14-05-10';
    options = {'SR',30,'lm',2,'session_pth',[],'vidName','side','abs_vid_path',[],'pupil_file_name','pupilRes.mat','verbose',0};
    options = inputparser(varargin,options);   
    if ~isempty(options.session_pth)
        pth = getfullpath(fileBase,options.session_pth); % path to session
    else
        pth = getfullpath(fileBase); % path to session
    end
    goto(fileBase);
    global fb; fb = fileBase;
    
    if exist(fullfile(pwd,'pupilRes.mat')) == 2
        load(options.pupil_file_name);
    else
        disp('no pupilRes.mat file found - skipping');
        out = nan;
        return;
    end
    
    % below doesnt work as session.mat not generate yet
    %[session,behavior] = loadSession(fileBase);
    % labels for the goodVidVar coding: 0: bad, 1:good, 2:average
    T = getCarouselDataBase;
    s = [T.session]; 
    entr = find(strcmp(fileBase,s));
    lbls = {'bad','good','average'};
    qual = lbls{str2num(T.pupil{129})+1};%session.info.goodVidVars.val(1)+1
    %session.info.
    SR = options.SR; % this should be loaded automatically from session
    lm=options.lm;
    X = (resSm(:,strcmp(varNames,'centerX'))); Xraw = X;
    Y = (resSm(:,strcmp(varNames,'centerY'))); Yraw = Y;
    
    %figure;
    %subplot(211); plot([X,Y]);title('raw');
    
    
%% COMPUTE THE PCA OF X AND Y
    % essentially trying to rotate the eye so that X is X and Y is Y
    [COEFF, SCORE] = pca([X,Y]);
    % choose highest variance as the X direction (heuristic)
    X = SCORE(:,find(nanstd(SCORE) == max(nanstd(SCORE))));
    Y = SCORE(:,find(nanstd(SCORE) == min(nanstd(SCORE))));    
    %subplot(212); plot([X,Y]); title('PCA');
    %linkaxes(get(gcf,'Children'),'x');
    
    
%% DETECTION - X
    disp 'detecting horizontal saccades...'    
    LP  = ButFilter(X,1,7/(SR/2),'low'); % order 1 works best - no ringing!
    LPz = zscore(LP); LPzX = LPz; LPX = LP;
    jerk = zscore(smooth(abs([0; 0; 0; diff(LP,3)]),4)); jerkX = jerk;
    [pk,pki] = findpeaks(jerk ,'MinPeakHeight',lm,'MinPeakDistance',5);

    % ensure none of the detections are too close to start and end of data
    if any(pki-6 <= 0)
        pki(find(pki-6 <= 0)) = [];
        pk(find(pki-6 <= 0)) = [];
    end
    if any(pki+6 >= length(jerk))
        pki(find(pki+6 >= 0)) = [];
        pk(find(pki+6 >= 0)) = [];
    end    
    % validate detection
    pk_rej_i = find(abs(LP(pki-6) - LP(pki+6)) < 2);
    pkrej = pki(pk_rej_i);
    pkkeep = setdiff(pki,pkrej);
    
    saccades.X.keepI    = pkkeep;% passed jerk and cliff criterion
    saccades.X.rejI     = pkrej; % passed jerk criterion but failed cliff criterion
    saccades.X.thr      = lm;    % detection threshold on smoothed jerk trace
    saccades.X.jerk     = jerk;    % detection threshold on smoothed jerk trace
    
    
%% DETECTION - Y
    disp 'detecting vertical saccades...'
    clear jerk pki pk LP LPz pk_rej_i pkrej pkkeep
    LP  = ButFilter(Y,1,7/(SR/2),'low'); % order 1 works best - no ringing!
    LPz = zscore(LP); LPzY = LPz; LPY = LP;
    jerk = zscore(smooth(abs([0; 0; 0; diff(LP,3)]),4)); jerkY = jerk;
    [pk,pki] = findpeaks(jerk ,'MinPeakHeight',lm,'MinPeakDistance',5);
    
    % ensure none of the detections are too close to start and end of data
    if any(pki-6 <= 0)
        pki(find(pki-6 <= 0)) = [];
        pk(find(pki-6 <= 0)) = [];
    end
    if any(pki+6 >= length(jerk))
        pki(find(pki+6 >= 0)) = [];
        pk(find(pki+6 >= 0)) = [];
    end  
    % validate detection
    pk_rej_i = find(abs(LP(pki-6) - LP(pki+6)) < 2);
    pkrej = pki(pk_rej_i);
    pkkeep = setdiff(pki,pkrej);
    
    saccades.Y.keepI    = pkkeep;% passed jerk and cliff criterion
    saccades.Y.rejI     = pkrej; % passed jerk criterion but failed cliff criterion
    saccades.Y.thr      = lm;    % detection threshold on smoothed jerk trace
    saccades.Y.jerk     = jerk;    % detection threshold on smoothed jerk trace
    
    
%% VISUALISATION
    if options.verbose
        fig=figure('pos',[10 10 1287 687]);        
        span = 60;
        k = 1;o=0;
        while k 
            sp = [1:span*SR]+span*o*SR;
        % X channel
            pkkeep = saccades.X.keepI;
            pkrej  = saccades.X.rejI;
            subplot(311);
            plot(sp,[jerkX(sp),-jerkX(sp)],'color',[0.7 0.7 0.7]);
            hold on; 
            plot(sp,LPzX(sp),'Linewidth',2,'color',[0 0 1]);
            plot(intersect(sp,pkrej),LPzX(intersect(sp,pkrej)),'*r');
            plot(intersect(sp,pkkeep),LPzX(intersect(sp,pkkeep)),'*g');
            plot([xlim],[-1 1;-1 1].*lm,'--','color',[0 1 1]); axis tight;ylim([-6 6]);
            title('X_{PCA}'); hold off;
            
        % Y channel
            pkkeep = saccades.Y.keepI;
            pkrej  = saccades.Y.rejI;            
            subplot(312);            
            plot(sp,[jerkY(sp),-jerkY(sp)],'color',[0.7 0.7 0.7]);
            hold on; 
            plot(sp,LPzY(sp),'Linewidth',2,'color',[0 0 1]); 
            plot(intersect(sp,pkrej),LPzY(intersect(sp,pkrej)),'*r');
            plot(intersect(sp,pkkeep),LPzY(intersect(sp,pkkeep)),'*g');
            plot([xlim],[-1 1;-1 1].*lm,'--','color',[0 1 1]); axis tight;ylim([-6 6]);
            title('Y_{PCA}'); hold off;   
            
        % raw activities overlapping for sanity check
            subplot(313);
            plot(sp,Xraw(sp)); hold on; plot(sp,Yraw(sp));
            hold off; title('raw X and Y');           
            
        % pupil detection quality label
            axes('pos',[0 0 1 1]); text(0.05,0.95,[fileBase,', quality: ', qual],'interpreter','none');
            axis([0 1 0 1]); axis off;
        
        % button to display Video of pupil detection
            c = uicontrol;
            c.String = 'show vid';
            c.Callback = @plotPupilVideo;
           
        % cycle through whole recording
            was_a_key = waitforbuttonpress;
            
            if      was_a_key && strcmp(get(fig, 'CurrentKey'), 'rightarrow') & o ~= floor(length(LP)/(span*SR))
                disp forward
              o=o+1;
            elseif  was_a_key && strcmp(get(fig, 'CurrentKey'), 'leftarrow' ) & o > 1
                disp back
              o=o-1;
            elseif  was_a_key && strcmp(get(fig, 'CurrentKey'), 'uparrow' )
                disp exit
                k = 0;
                close;
            end
        end
    end

    
%% SAVE
    saccades.info = {   'Note   - data based on PCs not raw positions',
                        'X      - horizontal saccade',
                        'Y      - vertical saccade (more rare in HF)',
                        'keepI  - good saccades',
                        'rejI   - ambiguous saccades',
                        'thr    - z-threshold for detection on jerk channel',
                        'jerk   - smoothed, rectified, 3rd derivative of the 7Hz LP filtered eye position'};    
    fprintf('saving ''saccades.mat''...');
    save(fullfile(getfullpath(fileBase),'saccades.mat'),'saccades','-v7.3');      fprintf('DONE!\n');
    out = saccades;
    fprintf('DONE!\n');
end

%% CALLBACK FOR THE PUSHBUTTON
function plotPupilVideo(src,event)
    global fb;
    try
        displayFrames(fb);
    catch ME
        display(ME.message);
    end
end
    
    
%% TO DELETE
%{
close all;figure; 
%plot(zscore([X,LP,LP2,dv])); legend({'X','LP','LP2','dv'});xlim([0 1200]);
plot(zscore([X,LP,LP2])); legend({'X','LP','LP2'});xlim([0 1200]);

figure;
subplot(141); plot(X);                              title('X'); xlim([700 780]);
subplot(142); plot([0; 0; 0; diff(diff(diff(X)))]); title('X'); xlim([700 780]); ylim([-6 10]);
subplot(143); plot([0; 0; 0; diff(diff(diff(LP)))]); title('LP');xlim([700 780]);ylim([-6 10]);
subplot(144); plot([0; 0; 0; diff(diff(diff(LP2)))]); title('LP2');xlim([700 780]);ylim([-6 10]);
close all
figure;
x = LP2;
subplot(141); plot(x);                                  title('x'); xlim([700 780]);
subplot(142); plot(zscore([0; 0; 0; diff(x,3)]));               title('x'); xlim([700 780]); ylim([-6 20]);
subplot(143); plot(zscore(abs([0; 0; 0; diff(x,3)])));          title('x'); xlim([700 780]); ylim([-6 20]);
subplot(144); plot(zscore(smooth(abs([0; 0; 0; diff(x,3)]),4)));title('x'); xlim([700 780]); ylim([-6 20]);
linkaxes(get(gcf,'children'),'x');

% no flipping the array doesnt lead to a different third derivative - duh
% subplot(143); plot(flipud(X));                              title('X'); xlim(length(X)-[780 700]);
% subplot(144); plot([0; 0; 0; diff(diff(diff(flipud(X))))]); title('X'); xlim(length(X)-[780 700]); ylim([-6 10]);


% 'scrollable' plot
%% 
% SR = 30; mrksz = 12;
% close all; fig=figure; 
% span = SR*60*2;% 2 minutes
% k = 1;o=0;
% while k 
%     sp = [1:span]+span*o;
%     subplot(211); plot(X(sp)); hold on;
% tmp = p_i(p_i>=sp(1) & p_i<=sp(end));
%     plot(tmp,X(tmp),'*r','markersize',mrksz); 
% tmp = n_i(n_i>=sp(1) & n_i<=sp(end));
%     plot(tmp,X(tmp),'*k','markersize',mrksz); hold off;
%     
%     subplot(212); plot(jerk(sp)); hold on;
% tmp = p_i(p_i>=sp(1) & p_i<=sp(end));
%     plot(tmp,jerk(tmp),'*r','markersize',mrksz); 
% tmp = n_i(n_i>=sp(1) & n_i<=sp(end));
%     plot(tmp,jerk(tmp),'*k','markersize',mrksz); hold off;
%      
%     linkaxes(get(gcf,'children'),'x');
%     was_a_key = waitforbuttonpress;
%     if      was_a_key && strcmp(get(fig, 'CurrentKey'), 'rightarrow') & o ~= floor(length(LP)/(span*SR))
%         disp up?
%       o=o+1;
%     elseif  was_a_key && strcmp(get(fig, 'CurrentKey'), 'leftarrow') & o > 1
%         disp down?
%       o=o-1;
%     else
%         disp dddd?
%         k = 0;
%         close;
%     end
% end




%% avoid piecewise linear fitting - might not be necessary
% lets try piecewise linear fitting?
ii = 1:30*1*60;
chunk = X(ii); % 2 minutes
lambda_max = l1tf_lambdamax(chunk);
[z1,status] = l1tf(chunk, 0.0001*lambda_max); % L1 trend filtering (piecewise-linear-like)
jerk_tmp = [0; 0; 0; diff(diff(diff(z1)))];
acc_tmp = [0; 0; diff(diff(z1))];

%%
close all;
figure; 
subplot(211); plot(zscore([jerk(ii), X(ii)])); % , acc(ii)
hold on;
plot(xlim,-[5 5]);plot(xlim,[5 5]);
legend({'jerk','X'});% ,'acc'
subplot(212); plot(zscore([jerk_tmp,z1]));% ,acc_tmp
hold on;
plot(xlim,-[5 5]);plot(xlim,[5 5]);
legend({'jerk','fit'});% ,'acc' ,'X'
linkaxes(get(gcf,'children'),'xy'); ylim([-10 10]*2); xlim auto;


%%
% below mostly works with 1kHz data although its not really finished in any
% sense
fileBase = 'NP49_2020-06-30_14-05-10';
[session,behavior] = loadSession(fileBase);
SR = session.info.SR_LFP; SR = 30;
ii = find(contains(behavior.name,'pupil'));
if length(ii) ~= 3; error('too many variables found'); end
pup = behavior.data.data(:,ii)';
tScale = 1/SR:1/SR:session.info.nSamples_LFP/SR;
X = pup(2,:);
LP = ButFilter(X,2,3./(SR/2),'low');
LPz = zscore(LP);
dv = [[0 0 0 ],diff(diff(diff(LP)))];

%%

lm=5;
[a,b]=findpeaks(zscore(dv),'MinPeakHeight',lm);
[c,d]=findpeaks(-zscore(dv),'MinPeakHeight',lm);
close all; fig=figure; 
subplot(211); plot(tScale,LPz);hold on;plot(tScale,zscore(pup(2,:)));%plot([b,d]/SR,[a,c],'xr');
plot([b]/SR,LPz(b),'*r');
plot([d]/SR,LPz(d),'*g');
subplot(212); plot(tScale,zscore(LP));hold on;plot(tScale,zscore(dv));

plot([xlim],[-1 1;-1 1].*lm,'k');
legend({'LP','pup'});
linkaxes(get(gcf,'children'),'x');
xlim([1000 1030]);


%%
lm=5;
close all; fig=figure; 
% subplot(211); plot(tScale,zscore(LP));hold on;plot(tScale,zscore(pup(2,:)));
% subplot(212); plot(tScale,zscore(dv));hold on;plot(tScale,zscore(LP));
% plot([xlim],[-1 1;-1 1].*lm,'k');
%legend({'LP','pup'});
%linkaxes(get(gcf,'children'),'x');
span = 30;
xlim([0 span]);%ylim([-2 2]);
k = 1;o=0;
while k 
    sp = [1:span*SR]+span*o*SR;
    subplot(211); plot(tScale(sp),zscore(LP(sp)));
    hold on;      plot(tScale(sp),zscore(pup(2,sp))); hold off;
    subplot(212); plot(tScale(sp),zscore(dv(sp)));
    hold on;      plot(tScale(sp),zscore(LP(sp)));
                  plot([xlim],[-1 1;-1 1].*lm,'--r'); axis tight;ylim([-6 6]);hold off;    
    linkaxes(get(gcf,'children'),'x');
    was_a_key = waitforbuttonpress;
    if      was_a_key && strcmp(get(fig, 'CurrentKey'), 'rightarrow') & o ~= floor(length(LP)/(span*SR))
        disp up?
      o=o+1;
    elseif  was_a_key && strcmp(get(fig, 'CurrentKey'), 'leftarrow') & o > 1
        disp down?
      o=o-1;
    else
        disp dddd?
        k = 0;
        close;
    end
end




%% problem definition:filtering with a butterworth or even smoothing has a negative impact on the sacade signal due to its
% nature of being essentially a DC signal with large abrupt DC changes.Any
% filtering smoothes these changes out and introduces ringing. A different
% problem arises when we compute acceleration or jerk where any noise
% fluctuation within the estimate of pupil position gets amplified. One way
% to deal with this may be to get an estimate of the low amplitude noise
% through the histogram of the amplitude difference which is expected to be bimodal
% given the expected two types of signal derivatives (large derivative at
% saccades and small derivative due to noise). Then use noise level
% velocieites as the mask for data points to exlclude. I implemented this
% below for the upsampled signal but it doesnt work because a diff at 1k is
% very different to the real diff which is at the 30 Hz camera sampling.
% Therefore it looks like we need to go back to the 30 Hz pupil data in
% pupilRes.mat

vel = diff(res(:,[2]),3);
figure; 
plot(tScale,zscore([[0 vel];X]')');
%subplot(221); 
figure; histogram(abs(vel'));set(gca,'Yscale','log');

% need to trim the edges - no data screws up the clustering!
tmp = abs(vel(:,200*SR:end-200*SR));

[mods] = kmeans(tmp',2);
clu1 = tmp(mods==1); clu1_sd = std(clu1); clu1_mu = mean(clu1);
clu2 = tmp(mods==2); clu2_sd = std(clu2); clu2_mu = mean(clu2);
al = [clu1_mu,clu1_sd;clu2_mu,clu2_sd];


if clu1_mu > clu2_mu
    ix = find(tmp > clu1_mu - clu1_sd);
    iy = find(tmp < clu1_mu + clu1_sd);
else
    ix = find(tmp > clu2_mu - clu2_sd);
    iy = find(tmp < clu2_mu + clu2_sd);
end
close all;
figure;
subplot(211); jplot(tmp,'k'); hold on; jplot(iy,tmp(iy),'.r');
subplot(212); jplot(X(200*SR:end-200*SR));
linkaxes(get(gcf,'children'),'x');


figure;gscatter(tmp(1,:),tmp(2,:),mods);

%}