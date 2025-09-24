%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% A wrapper function to find_ripples.m 
% Adds creation of event file for neuroscope
% record of which channels were used
% saving of output in matlab format
% INPUTS: 
% fle
% data
% chRpl
% noiseCh: channel with no ripple power but s
% SR: sampling rate
% recompute: 0/1 flag recomputing (1) or loading previous results (0)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [ripples] = getRipples(fle,data,chRpl, noiseCh,SR,recompute)

% recompute or load from file 
if nargin <6
    recompute = 1
else 
    if ~recompute 
        display 'I found a ''ripples.mat'' file - will load from file'
        load([getfullpath(fle),'ripples.mat']);
    else
        if isempty(data)
            [data,settings,tScale] = getLFP(fle);
        end
        % find ripples
        display 'detecting ripples'
        [ripples] = find_ripples(data(chRpl,:),'refsig', data(noiseCh,:),'sr',SR);

        % create event file
        display 'making evt file for neuroscope'
        str='rpl';Labels = repmat({str},1,length(ripples.ripple_t)); Overwrite = 0; SampleRate = 1000;
        MakeEvt([ripples.ripple_t],[getfullpath(fle),fle,'.rpl.evt'],Labels,SampleRate,Overwrite);

        % add some records to ripples array
        ripples.options.chRpl = chRpl;
        ripples.options.noiseCh = noiseCh;
        ripples.options.fle = fle;
        %
        display 'saving ripple data in matlab file'
        save([getfullpath(fle),'ripples.mat'],'ripples');
    end
end








%%
% below was a simplistit ripple detection by NP. Karalis version follows
% the same line so reverting to that to save time but adding some more
% automation
%  function [tR] = getRipples(fle,chSW,chRpl, chNoRpl)
% % basic ripple detection function
% % use 3 channels, one is pyramidal, one is no ripple control channel to use
% % for muscle artefact rejection and the third is for sharp wave detection
% % chNoRpl = 8;
% % chRpl = 30; 
% % chSW = 37;
% [data,settings,tScale] = getLFP(fle);
% 
% % filter for ripple channel 
% tmp = (data(chRpl,:));
% tmp = eegfilt(tmp,1000,100,250);
% [tmp,MU,SIGMA] = zscore(tmp);
% tmp = abs(hilbert(tmp));
% tmpSm = smooth(tmp,20)';
% 
% %close all; eegplot([data([chRpl],:);tmp.*SIGMA;tmpSm.*SIGMA],'srate',1000,'color','on');
% eegplot([tmp;tmpSm],'srate',1000,'color','on');
% 
% thr = 3;
% idx1 = find(tmpSm>thr);
% candCrs = zeros(size(tmpSm));% candidate crossing
% candCrs(idx1) = 1; % timepoints exceeding thr
% candCrs(1) = 0; candCrs(end) = 0;
% eegplot([candCrs;tmpSm],'srate',1000,'color','on');
% % transitions from below to above thrsh
% RplStart = find(candCrs - circshift(candCrs,1) == 1);
% RplStop = find(candCrs - circshift(candCrs,-1) == 1);
% 
% % candidate ripples
% cand = [RplStart;RplStop]; clear RplStart RplStop candCrs;
% 
% 
% 
% % how you will save them to load into neuroscope
% str='rpl';Labels = repmat({str},1,length(cand)); Overwrite = 0; SampleRate = 1000;
% MakeEvt(cand(1,:)',[getfullpath(fle),fle,'.rpl.evt'],Labels,SampleRate,Overwrite);
% % xcor with no ripple channel (both raw) to exclude EMG events
% for i = 1:length(cand)
%     d1 = data(chNoRpl,cand(1,i):cand(2,i));
%     d2 = data(chRpl  ,cand(1,i):cand(2,i));
%     
%     if length(d1) > 30
%         Ctmp = corrcoef(d1,d2);
%         C(i) = Ctmp(2,1);
%         l(i) = 1;
%     else
%         C(i) = 1;
%         l(i) = 1;
%     end
% end
% C= abs(C);
%     
% 
% ifPlot = 1;
% if ifPlot
%     figure; ofs = 100;
%     for i = 1:length(cand)
%         %if (cand(2,i)-cand(1,i)>10 & max(tmpSm(cand(1,i):cand(2,i)))>4)
%         if (C(i)<.3 & l(i))
%             plot(tScale(cand(1,i)-ofs:cand(2,i)+ofs),data(chRpl,cand(1,i)-ofs:cand(2,i)+ofs),'k');
%             hold on;
%             plot(tScale(cand(1,i)-ofs:cand(2,i)+ofs),data(chSW,cand(1,i)-ofs:cand(2,i)+ofs)+1000,'k');
%             plot(tScale(cand(1,i):cand(2,i)),data(chRpl,cand(1,i):cand(2,i)),'r');
%             hold off;
%             title([int2str(i),' , ',num2str(C(i))]);
%             pause
%         end
%     end
% end
% 
% % 