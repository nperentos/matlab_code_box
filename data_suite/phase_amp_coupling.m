% Phase Amplitude Coupling
% 
% With inspiration from: PowerPhaisePairs.m, PowerModulation.m,CrossFreqCoupling.m
% Date: 13/10/2017
% Author: Nikolas Karalis

function out = phase_amp_coupling(phasesig,ampsig,varargin)

%% Input parsing
options = {'sr',1000,'bw',[1 5],'fstep',[0.2 3],'ampfreqs',[20 120],'phasefreqs',[1 12],'downsamplefactor',4,'nShuffles',10,'uniformphase',1,'plot',0};
options = inputparser(varargin,options);

if nargin<2 | isempty(ampsig); ampsig = phasesig; end;

edg = options.phasefreqs(1):options.fstep(1):options.phasefreqs(2); phase_bins = [edg-options.bw(1); edg+options.bw(1)]';
edg = options.ampfreqs(1):options.fstep(2):options.ampfreqs(2); pow_bins = [edg-options.bw(2) ; edg+options.bw(2)]';

%% Optionally decimate the signals
ampsig = decimate(ampsig,options.downsamplefactor);
phasesig = decimate(phasesig,options.downsamplefactor);
sr = options.sr/options.downsamplefactor;

%% Pre-calculate  the phase and power signals
%tic;
%phall = zeros(size(phase_bins,1), length(phasesig));
%for c=1:size(phase_bins,1);
%    phall(c,:) = angle(hilbert(filter_lfp(phasesig,sr,phase_bins(c,:))));
%end
tic;
powall = zeros(size(pow_bins,1), length(ampsig));
for k=1:size(pow_bins,1);     
   powall(k,:) = abs(hilbert(filter_lfp(ampsig,sr,pow_bins(k,:))));
end
toc;

%% Calculate the Modulation Index for each phase - power pair
tic;
MI = {};
nbins = 18;
phedges = linspace(-pi,pi,nbins+1);
parfor c=1:size(phase_bins,1);    
    %ph = phall(c,:);
    ph = angle(hilbert(filter_lfp(phasesig,sr,phase_bins(c,:))));
    if options.uniformphase; ph = MakeUniformDistr(ph,-pi,pi); end;
    [~,idx] = histc(ph,phedges);  
    tmpMI = [];
    tmpMRL = [];
    for k=1:size(pow_bins);
        pow = powall(k,:);
        pow_dens = accumarray(idx',pow',[nbins 1],@sum)./sum(pow);
        % compute the MI via the entropy
        Hpow = -sum(pow_dens.*log(pow_dens));
        Hmax = log(nbins);
        tmpMI(k) = (Hmax-Hpow)/Hmax;
        % compute the mean resultant length
        tmpMRL(k) = sum(exp(1i*ph).*pow)./sum(pow);
    end
    MI{c} = tmpMI;
    MRL{c} = tmpMRL;    
end

MI1 = [];
for c=1:length(MI);
    MI1(c,:) = MI{c};
    MRL1(c,:) = MRL{c};
end
toc;

%% Calculate shuffled MI for each phase - power pair
if options.nShuffles>0;
    for sh = 1:options.nShuffles;
        tic;
        disp(['Shuffle #' num2str(sh)]);
        MI = {};
        nbins = 18;
        phedges = linspace(-pi,pi,nbins+1);
        N = length(phall(1,:)); % number of shuffled events    
        parfor c=1:size(phase_bins,1);
            ph = phall(c,:);
            if options.uniformphase; ph = MakeUniformDistr(ph,-pi,pi); end;
            [~,idx] = histc(ph,phedges);  
            tmpMI = [];
            tmpMRL = [];
            for k=1:size(pow_bins);
                pow = randsample(powall(k,:),N); % shuffle
                pow_dens = accumarray(idx',pow',[nbins 1],@sum)./sum(pow);
                % compute the MI via the entropy
                Hpow = -sum(pow_dens.*log(pow_dens));
                Hmax = log(nbins);
                tmpMI(k) = (Hmax-Hpow)/Hmax;
                % compute the mean resultant length
                tmpMRL(k) = sum(exp(1i*ph).*pow)./sum(pow);
            end
            MI{c} = tmpMI;
            MRL{c} = tmpMRL;
        end

        MI1shuf = [];
        for c=1:length(MI);
            MI1shuf(c,:) = MI{c};
            MRL1shuf(c,:) = MRL{c};
        end

        if sh==1;
            MIshufall = zeros(size(MI1shuf,2), size(MI1shuf,1),options.nShuffles);
            MRLshufall = zeros(size(MRL1shuf,2), size(MRL1shuf,1),options.nShuffles);
        end;
        MIshufall(:,:,sh) = MI1shuf';
        MRLshufall(:,:,sh) = MRL1shuf';

        toc;
    end
end
%% Prepare output
out = struct();
out.MI = MI1';
out.MRL = MRL1';
out.ph_f = mean(phase_bins,2);
out.amp_f = mean(pow_bins,2);
out.params = options;

if options.nShuffles>0
    out.MIshuf = MIshufall;
    out.MIpval = sum(out.MIshuf>out.MI,3)./size(out.MIshuf,3);
    out.MIz = (out.MI - mean(out.MIshuf,3))./std(out.MIshuf,0,3);

    out.MRLshuf = MRLshufall;
    out.MRLpval = sum(abs(out.MRLshuf)>abs(out.MRL),3)./size(out.MRLshuf,3);
    out.MRLz = (abs(out.MRL) - mean(abs(out.MRLshuf),3))./std(abs(out.MRLshuf),0,3);
end

%% Plot
fig; 
if options.nShuffles>0;
    sp(2,2); 
else
    sp;
end;

imagesc(out.ph_f,out.amp_f,smoothn(abs(out.MRL),1)); colorbar; axis xy;
title('MRL');
ylabel('Amplitude frequency');
sp; 
imagesc(out.ph_f,out.amp_f,smoothn(abs(out.MI),1)); colorbar; axis xy;
title('MI');

if options.nShuffles>0;
    sp;
    imagesc(out.ph_f,out.amp_f,smoothn(abs(out.MRLz),1)); colorbar; axis xy;
    title('MRL - zscored');
    sp;
    imagesc(out.ph_f,out.amp_f,smoothn(abs(out.MIz),1)); colorbar; axis xy;
    title('MI - zscored');
    xlabel('Phase frequency');
end;

if options.nShuffles>0;
    tmp = double(out.MRLpval<0.05); tmp(tmp==0)=NaN;
    fig; imagesc(out.ph_f,out.amp_f,tmp.*angle(out.MRL)); circ_colormap; colorbar; axis xy;
else;
    fig; imagesc(out.ph_f,out.amp_f,angle(out.MRL)); circ_colormap; colorbar; axis xy;
end;
