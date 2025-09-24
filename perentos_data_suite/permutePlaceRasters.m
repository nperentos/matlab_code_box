function out = permutePlaceRasters(data,varargin)
% permutePlaceRasters takes trial + position resolved firing rates, generates position
% shuffles and computes the spatial selectivity index for each shuffle. It
% then computes a p-value for the real SSI versus the shuffle distribution.
% The question here is whether to use smoothed or unsmoothed firing rates.
% A bit of a missnomer since data are spatially binned anyway so the
% notion of unsmoothed data is false.Perhaps we use the smoothed data to
% reduce noise.
% INPUT
%       data: position resolved firing rates (position x trial)
%       nSh:  number of shuffles (optional, default is 500)
%       changepoint: a trial number at which the firing rate changes substantially (optional)
%       trials: array of trial numbers to include. Rest are excluded.
%       This can be used for recordings with large distinct electrode drifts and will apply across
%       all neurons

close all;
options = {'nSh',500,'changepoint',[],'verbose',0};
options = inputparser(varargin,options);


%data = tun(45).cellTuningSm;


% many cells or just one?
if length(size(data)) == 2
    nCells=1;
elseif length(size(data)) == 3
    nCells = size(data,3);
end
if options.verbose
    figure('pos',[ 88         403        1072         570]);
end

%% GENERATE SHUFFLES AND COMPUTE SSI FOR EACH
    %textprogressbar('computing shuffles and SSIs: ');
    for k=1:nCells
        d = data(:,:,k); d = d';

    % generate shuffles and compute SSI
        trueSSI(k) = nansum(( 1/size(d,2)*mean(d,1,'omitnan')/mean(d(:),'omitnan') ).*log2(mean(d,1,'omitnan')/mean(d(:),'omitnan')) );

        for i = 1:options.nSh
            %textprogressbar(i*k*100/(options.nSh*nCells));
            id=randi(size(d,2),1,size(d,1));
            tmp=cell2mat(arrayfun(@(x) circshift(d(x,:),[1 id(x)]),(1:numel(id))','un',0));
            SSI(i,k) =  nansum(( 1/size(tmp ,2)*mean(tmp ,1,'omitnan')/mean(tmp(:),'omitnan')  ).*log2(mean(tmp ,1,'omitnan')/mean(tmp (:),'omitnan')) );
            shuffle(:,:,i) = tmp;
        end
        nullMap(:,:,k) = mean(shuffle,3,'omitnan'); clear shuffle;

    % statistical test trueSSI vs the shuffle distribution
        [zSSI,muZ,sdZ]=zscore(SSI(:,k)); 
        ztrueSSI = (trueSSI(k)-muZ)/sdZ;
        p(k)=pvaluefromz(ztrueSSI);
        shCorSSI(k) = trueSSI(k) - mean(SSI(:,k));    

    % visualisation
%         if options.verbose        
%             subplot(221);
%             imagesc(d); cx = caxis;
%             subplot(223);
%             imagesc(nullMap(:,:,k));caxis(cx);
%             subplot(2,2,[4]);
%             histogram(SSI(:,k)); hold on;
%             plot([trueSSI(k) trueSSI(k)],ylim,'--r','linewidth',2);
%             axes('pos',[0 0 1 1]); 
%             txt = {['cell = ' int2str(k)];
%                    ['trueSSI = ' num2str(trueSSI(k))]; 
%                    ['shuffleCorrectedSSI = ' num2str(shCorSSI(k))];
%                    ['nSpikes = ' int2str(sum(d(:))) ];
%                    ['p-val = ' num2str(p(k))]};
%             text(0.6,0.7,txt); axis off;            
%             drawnow;
%             waitforbuttonpress;
%             %pause(0.5);
%             clf;
%         end

    end

    out.trueSSI = trueSSI;
    out.nullMap = nullMap;
    out.pval = p;
    out.shufCorSSI = shCorSSI;
    out.shufflesSSI = SSI;
    
    %textprogressbar('done');

