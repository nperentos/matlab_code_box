% simple detection of gross states
% 0. import the .lfp data or the peripherals channel

% 1. compute delta t
+heta ratio [ick one channel that looks good pref. PFC

    PFCSignal = data(3,:);
    options.defaults = 'theta';
    wPFCSignal = WhitenSignal(PFCSignal);
    SpPFC = specmt(wPFCSignal,options);
    figure; subplot(311);
    imagesc(SpPFC.t',SpPFC.f',log10(SpPFC.Sxy)');
    hold on; caxis([0 1000]);
    axis xy;
    hold on;
    colorbar; %plot([ev ev],[0 20],'w');

% 2. compute zscored movement from accelerometers mv = sqrt(mean(zX^2)+mean(zY^2)+mean(zZ^2))
    intAcc = zscore(sum(abs(hilbert(data(7,:))),1));
    dthR = mean(SpPFC.Sxy(:,1:18),2)./mean(SpPFC.Sxy(:,19:45),2);
    subplot(312); plot(tScale,intAcc); 
    subplot(313);cla;plot(SpPFC.t, dthR); hold on; plot(SpPFC.t,smooth(dthR, 100),'r'); ylim ([0 50]);
    linkaxes(get(gcf,'Children'),'x')
    axis tight


% 3. SD of EEG channel

% 4. kmeans clustering (soft clustering)
% 5. post processing because alg is blind to transition rules (REM must follow NREM))

