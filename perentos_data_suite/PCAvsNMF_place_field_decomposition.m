close all;

% data = (randn(200,K) +[zeros(100,K);0.5*ones(100,K)])*randn(K,201);
data = (randn(200,K))*randn(K,201);
data = meas;
[M,N] = size(data);

U = randn(M,K) + 0.5*randi([0 1], M,K);%+[zeros(M,floor(K/2)),0.1*ones(M,K-floor(K/2))];
figure; subplot(221); imagesc(data'); colorbar;colormap 'jet'; cax = caxis; %caxis([-10 10]); 
subplot(222); imagesc(U); %caxis([-10 10]);%axis square;
for iteration = 1:10
    Vt = U \ data;
    subplot(223);imagesc((U*Vt)'); colorbar; caxis(cax);
    U = data / Vt;
    loss(iteration) = norm(data - U*Vt, 'fro');
    subplot(222); imagesc(U); colorbar;%caxis([-10 10]);
    title(['iteration:',num2str(iteration),' error:',num2str(loss(iteration))]);
    
    subplot(224);imagesc(data' - (U*Vt)'); colorbar; %caxis([-1e15 1e15]);
    drawnow; %pause;
    if iteration == 1
        display('paused on first iteration')
        pause;
    end
    iteration;
end

% nnmf matlab example

%load fisheriris
%rng(1) % For reproducibility

%% shared figure for PCA and NNMF comparison on an example place field
close all;
figure('pos',[0.3066    0.5602    1.6688    0.4176].*1e3); colormap 'jet';%'summer';
fileBase = 'NP46_2019-12-02_18-47-02';
cd(getfullpath(fileBase));
load place_cell_tunings.mat;
M = [tun.cellTuningSm];
allM = reshape(M,[size(tun(1).cellTunings,1),size(tun(1).cellTunings,2),length(M)/size(tun(1).cellTunings,2)]);    
% lims
SSI_lim = 0.2; meanFR_lim = 1; muCC_lim = 0.6;
idx = find(([tun(:).SSI]    > SSI_lim &...
            [tun(:).meanFR] > 0.2 & ... % [tun(:).meanFR] < 5 &
            [tun(:).muCC]   > muCC_lim) == 1);
subM = allM(:,:,idx); 
% eliminate last trial since it is empty - is this general?    
subM = subM(:,1:end-1,:);     [~,I] = sort(max(W),'descend');
    plot(W(:,I)); axis tight; xlabel('position'); ylabel('activity (A.U.?)');
cID = [tun.cellID];
K=3; % 
for nC = 1:size(subM,3)
    clf;
    meas = subM(:,1:110,nC);
% NMF
    [W,H] = nnmf(meas,K);
    subplot(251); imagesc(meas'); title('original data'); cax = caxis;
    h = subplot(252);  %imagesc((W')); % the components
    %axes('pos', get(h,'pos'));
    [~,I] = sort(max(W),'descend');
    plot(W(:,I)); axis tight; xlabel('position'); ylabel('activity (A.U.?)');
    title('NMF components');  box off;
    %set(gca,'YAxisLocation','right','color','none'); axis tight;
    subplot(253); imagesc((H')); ylabel('trial (#)'); title('NMF activations'); colorbar; 
    subplot(254); imagesc((W*H)'); xlabel('position');ylabel('trial (#)'); title('NMF reconstruction'); caxis(cax);
    subplot(255); imagesc(meas'-(W*H)'); xlabel('position');ylabel('trial (#)'); title(['NMF residual, ', num2str(norm(meas - W*H, 'fro'))]); caxis(cax);

% PCA
    [M,N] = size(meas);
    U = randn(M,K);
    for i = 1:100
         Vt = U \ meas;    
        U = meas / Vt;
    end
    subplot(256); imagesc(meas'); title('original data'); cax = caxis;
    h = subplot(257); %imagesc((U')); % the components
    %axes('pos', get(h,'pos'));
    [~,I] = sort(max(W),'descend');
    plot(U(:,I)); axis tight; xlabel('position'); ylabel('activity (A.U.?)');
    title('PCA components');  box off;
    %set(gca,'YAxisLocation','right','color','none'); axis tight;
    subplot(258); imagesc((Vt')); ylabel('trial (#)'); title('PCA activations');colorbar;
    subplot(259); imagesc((U*Vt)');xlabel('position');ylabel('trial (#)'); title('PCA reconstruction'); caxis(cax);
    subplot(2,5,10); imagesc(meas'-(U*Vt)'); xlabel('position');ylabel('trial (#)'); title(['PCA residual, ', num2str(norm(meas - U*Vt, 'fro'))]); caxis(cax);
    drawnow;
    print(gcf,[pwd,'/NMF_vs_PCA/','_',num2str(cID(idx(nC))),'_NMFvPCA'],'-djpeg');
    display 'figure saved'
end
close all;    



% using pca function instead! 
% r
% subplot(257); plot(score(:,[1:3])); axis tight;
% subplot(258); imagesc(coeff(1:3,:)');subplot(258); colorbar
% subplot(259); imagesc((score(:,1:3)*coeff(:,1:3)')');
% subplot(2,5,10); imagesc(meas'-(score(:,1:3)*coeff(:,1:3)')');