function SSI = SSI(fileBase)


% does the nq structure exist?
% if you use the bootstrapped firing rate in the nq structure you are
% including all time itervals, not just the behavior. Instead we will work
% with the overall firing rate computed only on those intervals that were
% included in the tuning curves which is when the carousel was actually
% spinning
%fle_nq = fullfile(getfullpath(fileBase),[fileBase,'.nq.mat']);

fle_tunings = fullfile(getfullpath(fileBase),'place_cell_tunings.mat');
fle_peripherals = fullfile(getfullpath(fileBase),'peripheralsPP.mat');
if ~exist(fle_nq) == 2 | ~exist(fle_tunings) == 2 | ~exist(fle_tunings) == 2
    error('cannot find the ''fileBase.nq.mat'' file and/or the  place_cell_tunings.mat. Please investigate'); 
end

load(fle_nq); % cluster properties
load(fle_tunings); % rasters for all cells
load(fle_peripherals); %position speed etc
carouselSpeed = carouselGetVar(fileBase,{'carouselSpeed'},ppp,pppNames);
location = carouselGetVar(fileBase,{'posDiscr'},ppp,pppNames);
idxMv = find(carouselSpeed>1); % idxMv = find(runSpeed>1);
tmpLoc = location(idxMv); %
[occupancy]=histc(tmpLoc,(unique(tmpLoc))); 
occupancy = occupancy./sum(occupancy);

% cycle through all cell and generate the SSI metric
for i = 1:max(length(nq.cids),length(tun.cellID))
    try
        % lets use the tun structure as our indexing order and search into nq
        idx = find(nq.cids == tun.cellID(i));
    % mean firing from bootstraping
        L = nq.fr(idx); % bootstrapped firing rate
    % mean firing rate from rasters (movement periods only)
        L = sum(sum(tun.allCellTunings(:,:,i))); 
        L = L/(length(tmpLoc)/1000); 
    % firing rate in spatial bins
        Li = mean(tun.allCellTunings(:,:,i),2)';
        SSI = nansum(occupancy'.*Li/L.*log2(Li/L)); %SSIocc(i) = nansum(occ.*Li/L.*log2(Li/L));
        % occupancy.*
        if SSI > 0
            fprintf('cell: %0.0f SSI %0.2f bins/spike and SSI %0.2f bins/spike\n',tun.cellID(i),SSI,SSIocc);
        end 
    catch
        warning('matrix dimensions mismatch between the two structures!')
    end
end

figure; subplot(211);histogram(SSI(SSI ~= 0),50); title('excluding zeros');
        subplot(212);histogram(SSI,50); title('all data');


        
        
        
%% BU
%{
% does the nq structure exist?
fle_nq = fullfile(getfullpath(fileBase),[fileBase,'.nq.mat']);
fle_tunings = fullfile(getfullpath(fileBase),'place_cell_tunings.mat');
fle_peripherals = fullfile(getfullpath(fileBase),'peripheralsPP.mat');
if ~exist(fle_nq) == 2 | ~exist(fle_tunings) == 2 | ~exist(fle_tunings) == 2
    error('cannot find the ''fileBase.nq.mat'' file and/or the  place_cell_tunings.mat. Please investigate'); 
end

load(fle_nq); % cluster properties
load(fle_tunings); % rasters for all cells
load(fle_peripherals); %position speed etc
carouselSpeed = carouselGetVar(fileBase,{'carouselSpeed'},ppp,pppNames);
location = carouselGetVar(fileBase,{'posDiscr'},ppp,pppNames);
idxMv = find(carouselSpeed>1); % idxMv = find(runSpeed>1);
tmpLoc = location(idxMv); %
[occupancy]=histc(tmpLoc,(unique(tmpLoc))); 
occupancy = occupancy./sum(occupancy);

% cycle through all cell and generate the SSI metric
for i = 1:max(length(nq.cids),length(tun.cellID))
    try
        % lets use the tun structure as our indexing order and search into nq
        idx = find(nq.cids == tun.cellID(i));
    % mean firing from bootstraping
        L = nq.fr(idx); % bootstrapped firing rate
    % mean firing rate from rasters (movement periods only)
        L = sum(sum(tun.allCellTunings(:,:,i))); 
        L = L/(length(tmpLoc)/1000); 
    % firing rate in spatial bins
        Li = mean(tun.allCellTunings(:,:,i),2)';
        SSI(i) = nansum(occupancy'.*Li/L.*log2(Li/L)); %SSIocc(i) = nansum(occ.*Li/L.*log2(Li/L));
        % occupancy.*
        if SSI > 0
            fprintf('cell: %0.0f SSI %0.2f bins/spike and SSI %0.2f bins/spike\n',tun.cellID(i),SSI,SSIocc);
        end 
    catch
        warning('matrix dimensions mismatch between the two structures!')
    end
end

figure; subplot(211);histogram(SSI(SSI ~= 0),50); title('excluding zeros');
        subplot(212);histogram(SSI,50); title('all data');
%}
