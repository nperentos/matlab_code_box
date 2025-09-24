    function [kept_cids, tCurves, II] = placeCellCoverage(fileBase,varargin)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% finds cells that satisfy specified thresholds (SSI, meanFR, cellType,
% muCC) sorts them according to the location of their peaks on carousel
% space and plots the cell coverage
% if output is requested, a list is given with the cids (cluster IDs) of the 
% kept clusters (at the strictest criterion) 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% PRE
%     close;
    options = {'pth',[],'saveFig',0,'SSI_lim', 0.1, 'muFR_min_lim', 0.05, 'muFR_max_lim', 100, 'muCC_lim', 0.01, 'tpe', [2]};
    options = inputparser(varargin,options);
    if ~isempty(options.pth)
        processedPath = getfullpath(fileBase,options.pth);
    else
        processedPath = getfullpath(fileBase);
    end        
    load([fileBase,'.tun1.mat']);  
    [session, behavior] = loadSession(fileBase);

%% sub population resolved by position (shows place cells coverage)
    figure('pos',[10 -20 1139/1.5 1250/1.2]);
    
    subplot(431); histogram([tun1.SSI]);      title('SSI'); axis tight;
    subplot(432); histogram([tun1.muFR]);   title('firing rate'); axis tight;
    subplot(433); histogram([tun1.CC]);       title('trial cross correlation'); axis tight;
    
% all cells
    pop_coverage_all = mean(tun1.tuningSm,3,'omitnan')./tun1.muFR; %   ALL CELLS IRRESPECTIVE OF QUALITY
    [~,I] = max(pop_coverage_all,[],2); % find max position of each place field
    [~,II] = sort(I); 
    
    txt_pos = tun1.lns(1:end-1) + diff(tun1.lns)./2
    
    subplot(4,3,[4:6]);
    if strcmp(session.info.taskType,'continuous')
        imagesc(linspace(0,360,size(pop_coverage_all,2)),[],pop_coverage_all(II,:)); 
    elseif strcmp(session.info.taskType,'controlled')
        imagesc(tun1.locEdges,[],pop_coverage_all(II,:)); hold on;
        plot([tun1.lns; tun1.lns],ylim,'w--')
        text(txt_pos(1),-max(ylim)*0.1,'B \leftarrow A','horizontalalignment','center');
        text(txt_pos(2),-max(ylim)*0.1,'A \leftarrow B','horizontalalignment','center');
        text(txt_pos(3),-max(ylim)*0.1,'A \rightarrow C','horizontalalignment','center');
        text(txt_pos(4),-max(ylim)*0.1,'C \rightarrow A','horizontalalignment','center');
    end
    clb = colorbar; %xlabel(clb,'mean-normalised rates','fontsize',14);
    ylabel('putative cell (#)'); %xlabel('carousel angular position (^o)');
    title('MUA & SUA');
    
% SUA only
    idx = find(tun1.cellType == 2);
    pop_coverage_sua = squeeze(mean(tun1.tuningSm(idx,:,:),3,'omitnan')); % average across trials [cell x position]
    %pop_coverage = pop_coverage(idx,:);
    [~,I] = max(pop_coverage_sua,[],2); % find max position of each place field
    [~,II] = sort(I); % get sorting order (early to late place field positions)    
    pop_coverage_sua = pop_coverage_sua./tun1.muFR(idx);
    pop_coverage_sua = pop_coverage_sua(II,:); % sort by position
    idx_cluIDs = [tun1.cids(idx)];
    
kept_cids.allSUA = idx_cluIDs;
tCurves.allSUA  = tun1.tuningSm(idx,:,:); % average across trials [cell x position]

    subplot(4,3,[7:9]);
    if strcmp(session.info.taskType,'continuous')
        imagesc(linspace(0,360,size(pop_coverage_sua,2)),[],pop_coverage_sua); clb = colorbar; xlabel(clb,'rates (mean-normalised)','fontsize',14);
        ylabel('putative cell (#)'); %xlabel('carousel angular position (^o)');    
        title('SUA','fontweight','normal');
    elseif strcmp(session.info.taskType,'controlled')
        imagesc(tun1.locEdges,[],pop_coverage_sua); hold on;
        plot([tun1.lns; tun1.lns],ylim,'w--');
%         text(txt_pos(1),-max(ylim)*0.1,'B \leftarrow A','horizontalalignment','center');
%         text(txt_pos(2),-max(ylim)*0.1,'A \leftarrow B','horizontalalignment','center');
%         text(txt_pos(3),-max(ylim)*0.1,'A \rightarrow C','horizontalalignment','center');
%         text(txt_pos(4),-max(ylim)*0.1,'C \rightarrow A','horizontalalignment','center');        
    end
    ylabel('putative cell (#)'); %xlabel('carousel angular position (^o)');    
    title('SUA','fontweight','normal');
    clb = colorbar;
    
% SUA subselection
    idx = find([tun1.SSI]       >  options.SSI_lim &...
               [tun1.muFR]      >  options.muFR_min_lim  & ...
               [tun1.muFR]      <  options.muFR_max_lim & ...
               [tun1.cellType]  == options.tpe & ... 
               [tun1.muCC]      >  options.muCC_lim );
    idx_cluIDs = [tun1.cids(idx)];

    pop_coverage = squeeze(mean(tun1.tuningSm(idx,:,:),3,'omitnan')); % average across trials [cell x position]
    %pop_coverage = pop_coverage(idx,:);
    [~,I] = max(pop_coverage,[],2); % find max position of each place field
    [~,II] = sort(I); % get sorting order (early to late place field positions)    
    pop_coverage = pop_coverage./tun1.muFR(idx);
    pop_coverage = pop_coverage(II,:); % sort by position
    
kept_cids.subselectedSUA  = idx_cluIDs;
tCurves.subselectedSUA  = tun1.tuningSm(idx,:,:); % average across trials [cell x position]

    subplot(4,3,[10:12]);
    if strcmp(session.info.taskType,'continuous')
        imagesc(linspace(0,360,size(pop_coverage,2)),[],pop_coverage); clb = colorbar; %xlabel(clb,'mean-normalised rates','fontsize',14);
    elseif strcmp(session.info.taskType,'controlled')
        imagesc(tun1.locEdges,[],pop_coverage); hold on;
        plot([tun1.lns; tun1.lns],ylim,'w--');
%         text(txt_pos(1),-max(ylim)*0.1,'B \leftarrow A','horizontalalignment','center');
%         text(txt_pos(2),-max(ylim)*0.1,'A \leftarrow B','horizontalalignment','center');
%         text(txt_pos(3),-max(ylim)*0.1,'A \rightarrow C','horizontalalignment','center');
%         text(txt_pos(4),-max(ylim)*0.1,'C \rightarrow A','horizontalalignment','center');   
    end
    clb = colorbar;
    ylabel('putative cell(#)'); xlabel('carousel angular position (^o)');        
    title(['SUA clusters (muFR>',num2str(options.muFR_min_lim),', SSI>',num2str(options.SSI_lim),', muCC>',num2str(options.muCC_lim),')'],'fontweight','normal');
    
    ForAllLabels('fontsize',14,'fontweight','normal')
    
%% save a figure 
    if options.saveFig
        [session, behavior] = loadSession(fileBase);
        stampFig(fileBase,gcf,str2cell(session.info.conditions)); 
        print(gcf,[processedPath,'place_cell_coverage'],'-djpeg');
    end
    
    %kept_cids = idx_cluIDs;
    %tCurves = tun1.tuningSm(idx,:,:); % average across trials [cell x position]
    
    