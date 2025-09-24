function [pupilDLC] = importPupilDLC(fileBase, startRow, endRow)

%% PRE
    % find csv dlc o/p
    fullPath = fullfile(getFullPath(fileBase),'video');
    test = (dir(fullfile(fullPath,'*pupil*.csv')));
    
    if size(test,1) ~=1
        error('no csv or more than one found - cannot proceed');        
    else
        filename = [test.folder,'/',test.name];
    end
    
    verbose = 0; % switch to 1 to visualise some detections (see visualise outliers  below)
    
    load(fullfile(getfullpath(fileBase),'faceROIs.mat'));
    eye_roi = ROI.pts(find(strcmp(ROI.names,'eye')),:);
    

    % initialize variables.
    delimiter = ',';
    if nargin<=2
        startRow = 4;
        endRow = inf;
    end
    

    % open the text file
    formatSpec = '%*s%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%[^\n\r]';
    fileID = fopen(filename,'r');
    dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'EmptyValue' ,NaN,'HeaderLines' ,startRow-1, 'ReturnOnError', false, 'EndOfLine', '\r\n');
    fclose(fileID);


    % identify relevant video file
    goto(fileBase); cd ..; cd video;
    vidfle = dir('*pupil*.avi');
    if length(vidfle) ~= 1
        error('cannot identify a unique pupil video file. Please check'); 
    end
    obj = VideoReader(vidfle.name); 



    % pupil characteristics
    pup = [dataArray{1:end-1}]; % the raw dlc data
    X = pup(:,[1:3:24]); % y coordinates of all the datapoints
    Y = pup(:,[2:3:24]); % x coordinates of all the datapoints
    refl = pup(:,[25:26]); % IR led reflection on the eye ball
    % quick and dirty definition of outliers
    lik = pup(:,[3:3:24]);
    otl = find(sum(lik,2) ~= 8); % anything with non unitary likelyhood

    
%% visualisation of markers together with video frame
    ifRun = 0;
    if ifRun
        figure; clf;
        obj = VideoReader(vidfle.name);    
        %display type: every x frames or outliers
        lst_ = [1:100:length(X)];
        lst_ = otl;
        for i = 1:length(lst_)
            hold off;
            obj.CurrentTime = lst_(i)-1;
            fr = obj.readFrame;
            imshow(fr(:,:,1),'InitialMagnification',300); hold on;
            axis on;
            scatter(X(lst_(i),:),Y(lst_(i),:),6,'.');
            hold on;
            scatter(refl(lst_(i),1),refl(lst_(i),2),'r');
            xlim([0 100]);ylim([0 100]); %set(gca,'YDir','reverse');
            drawnow;
        end
    end


%% fit ellipses, circles and polygons to each data point + discover otls
    for i = 1:length(X)
        Xtmp = X(i,:)';
        Ytmp = Y(i,:)';
        % fit polygon
        [polyg.geom(i,:), polyg.iner(i,:), polyg.cpmo(i,:)] = polygeom(Xtmp,Ytmp); %area and centroid of said polygon
        % fit circle
        circl(i,:) = circfit(Xtmp,Ytmp); % fit a circle to the data points
        resid(i,1) = sum(abs(sqrt((Xtmp-circl(i,2)).^2 + (Ytmp-circl(i,3)).^2)-circl(i,1))); % circular fit residual
        % fit ellipse (used for residuals)
        [elips(i,:)] = fitellipse(Xtmp,Ytmp); % Returned = round(params.*[1 1 1 1 180]);        
        t = linspace(0,pi*2,40);
        x = elips(i,3) * cos(t);
        y = elips(i,4) * sin(t);
        nx = x*cos(elips(i,5))-y*sin(elips(i,5)) + elips(i,1); 
        ny = x*sin(elips(i,5))+y*cos(elips(i,5)) + elips(i,2);
        % since we would need to figure out the rotation of the fitted ellipse and
        % the corresponding radius at that angle to be able to compute the residual
        % on an individual point's basis, we can take a shortcut and instead
        % compute all the distances of the each point in question to those define
        % by the ellipse(nx,ny). The minimum of this set will be the equivalent to
        % the residual as defined above for circfit
        resid_ = 0;
        for pt = 1:8
            resid_(pt) = min(sqrt((Xtmp(pt)-nx).^2 + (Ytmp(pt)-ny).^2));
        end
        resid(i,2) = sum(resid_);
    end
    
    Area_polygon = polyg.geom(:,1);
    Area_circle = pi.*circl(:,1).^2;
    Centroid_polygon = [polyg.geom(:,2), polyg.geom(:,3)];
    Centroid_circle  = [circl(:,2) circl(:,3)];
    
  
    
%% output    
    pupDLC.res = [Area_circle, Centroid_circle]; 
    pupDLC.resIntrp = pupDLC.res;
    pupDLC.resIntrp(otl,:) = nan;
    pupDLC.lik = lik;
    for i = 1:3
        nanx = isnan(pupDLC.resIntrp(:,i));      %resSm(:,i) = inpaint_nans(resSm(:,i)); % or  
        xtmp = 1:1:length(X);
        pupDLC.resIntrp(nanx,i) = interp1(xtmp(~nanx), pupDLC.resIntrp(~nanx,i), xtmp(nanx),'linear','extrap');        
    end
    pupDLC.reflection = refl;
    pupDLC.fitResiduals = resid;
    pupDLC.outliers = otl;
    pupDLC.aux.polyg = polyg;
    pupDLC.aux.circl = circl;
    pupDLC.aux.elips = elips;
    pupDLC.dlxX = X;
    pupDLC.dlxY = Y;
    cd(goto(fileBase));
    save('pupilDLC.mat','pupDLC');

    
    
%% visualise outliers  
if verbose
    lst = otl;
    %lst = sort(randperm(length(X),200));
    ofs = 0;
    figure;
    for i = 1:length(lst)
        clf;
        % current frame's DLC data points
        Xtmp = X(lst(i),:)';
        Ytmp = Y(lst(i),:)';
        
        % current frame's ellipse
        x = elips(lst(i),3) * cos(t);
        y = elips(lst(i),4) * sin(t);
        nx = x*cos(elips(lst(i),5))-y*sin(elips(lst(i),5)) + elips(lst(i),1); 
        ny = x*sin(elips(lst(i),5))+y*cos(elips(lst(i),5)) + elips(lst(i),2);
        
        
        % current frame's video frame        
        obj.CurrentTime = lst(i)-1;
        fr = obj.readFrame; axis on;
        fr = fr(:,:,1);
        imshow(fr,'InitialMagnification',600); hold on;
        plot(Xtmp-ofs,Ytmp+ofs,'xr');  % the dlc data points
        plot(nx-ofs,ny+ofs,'c-','linewidth',0.1);      % ellipse fit
        circle([circl(lst(i),2)-ofs,circl(lst(i),3)+ofs],circl(lst(i),1),30,'y');      % circle fit
        circle([pupDLC.resIntrp(lst(i),2)-ofs,pupDLC.resIntrp(lst(i),3)+ofs],sqrt(pupDLC.resIntrp(lst(i),1)/pi),30,'g');
        % intterpolated circle fit
        
        %plot(pup(lst(i),25),pup(lst(i),26),'dm','markersize',4);
        title(['lik: ',num2str(sum(lik(lst(i),:))/8,2),' ,    resid: ', num2str(resid(lst(i),1),2), ' & ',num2str(resid(lst(i),2),2)]);
        text(min(xlim),min(ylim),['fr# ', num2str(lst(i))],'verticalalignment','bottom','color','r');
        xlim([0 100]);ylim([0 100]);
        axis square;
        drawnow; pause(0.7*(resid(lst(i),2)/10));
    end
end    
    
    
%% gui style display of relevant frame and fited pupil params by clicking
% onto any point inside the time series (Area, X Y)
    ifRun = 0;
    if ifRun
        figure; 
        subplot(211); 
        plot(zscore(Area_polygon)); 
        hold on; % plot(out.circ(:,2));
        plot(zscore(resid(:,1))); ylim([-5 5]);

        title('press "Enter" to exit');
        while true
            [x,~,bt] = ginput(1);
            if isempty(bt)
                disp hello;
                break;
            end
            x = round(x);
            obj.CurrentTime = round(x);
            fr = obj.readFrame;
            subplot(212); cla;
            imshow(fr(:,:,1),'InitialMagnification',300); hold on;
            axis on;
            scatter(X(x,:),Y(x,:),6,'.');
            xlim([0 100]);ylim([0 100]); axis square;
        end
    end




%% DISCARDED CODE
%{
% Create output variable
pup = [dataArray{1:end-1}]; % the raw dlc data
clearvars filename delimiter startRow formatSpec fileID dataArray ans;
likelihoods = pup(:,[3:3:24]); % likelyhoods of points' coordinates
otl = find(sum(likelihoods,2) ~= 8); % outliers from the likelihood vars
X = pup(:,  [1:3:24]); % y coordinates of all the datapoints
Y = pup(:,[2:3:24]); % x coordinates of all the datapoints
refl = pup(:,[25:26]); % IR led reflection on the eye ball
clear A;
for i = 1:size(X,1)
    %A(i,:) = fitellipse(X(i,:),Y(i,:));
    A(i,:) = circfit(X(i,:),Y(i,:));
    %A(i,:) = EllipseDirectFit([X(i,:)',Y(i,:)']);
end
% A = [1 1 1 1 180].*A;

pupilDLC = pup;

idx = find(sum(likelihoods,2) <3); % prob inadequate as an otl detector...
[~,re] = sort(rand(size(idx)));
idx = idx(re);
%idx = 1:100;
goto(fileBase); cd ..; cd video;
vidfle = dir('*pupil*.avi'); figure; clf;
if length(vidfle) == 1
    obj = VideoReader(vidfle.name);
    for i = 1:100%length(idx)
        obj.CurrentTime = idx(i);
        fr = obj.readFrame;
        imshow(fr); hold on;
        % dlc labels
        scatter(Y(1,:),X(1,:),'xr')
        plot(pupilDLC(idx(i),1),pupilDLC(idx(i),2),'or');
        plot(pupilDLC(idx(i),4),pupilDLC(idx(i),5),'og');
        plot(pupilDLC(idx(i),7),pupilDLC(idx(i),8),'ob');
        plot(pupilDLC(idx(i),10),pupilDLC(idx(i),11),'om');
        xlim([eye_roi(1) eye_roi(1)+eye_roi(3)]);
        ylim([eye_roi(2) eye_roi(2)+eye_roi(4)]);
        % fitted circle
        viscircles([A(i,2), A(i,3)],A(i,1));
%         % fitted ellipse
%         Returned = A(i,:);
%         % Draw the returned ellipse
%         t = linspace(0,pi*2);
%         x = Returned(3) * cos(t);
%         y = Returned(4) * sin(t);
%         nx = x*cos(Returned(5))-y*sin(Returned(5)) + Returned(1); 
%         ny = x*sin(Returned(5))+y*cos(Returned(5)) + Returned(2);
%         hold on
%         plot(nx,ny,'r-')
        pause;clf;
    end
end

        
        
% quick vis
figure;
scatter(pupilDLC(:,1),pupilDLC(:,2),'r');
hold on;
scatter(pupilDLC(:,4),pupilDLC(:,5),'g');
scatter(pupilDLC(:,7),pupilDLC(:,8),'b');
scatter(pupilDLC(:,10),pupilDLC(:,11),'m');
        
        
        
% make sure that the order of labels is as expected
    mus = mean(T(:,1:6));
    [~, i_apex_x]=max(mus(1:3));
    [~, i_base_right_y]=max(mus(4:6));
    [~, i_base_left_y]=min(mus(4:6));    
    seq = [i_base_left_y i_apex_x i_base_right_y];
    T = T(:,[seq seq+3 seq+6]);
    
% center of mass or per point movement tolerance away from the mean
    px = 10;


% find unreliable frames based on DLC posteriors and center of mass calc.
    tmp = min(T(:,7:9),[],2);
    otl1 = find(tmp<0.995);    

% find unreliable frames based center of mass of three points
    cx = median(vc(T(:,1:3))); cy = median(vc(T(:,4:6)));% center of mass
    cxi = mean(T(:,1:3),2); cyi = mean(T(:,4:6),2); % COM per timepoint    
    otl2 = find(abs(cxi-cx)>px|abs(cyi-cy)>px); 

% a per pupil point deviation rather than COM deviation? It might be more robust
%     cx = median(T(:,1:3)); cy = median(T(:,4:6));
%     otl2 = [];
%     for i = 1:3
%         otl2 = [otl2; find(abs(T(:,i)-cx(i))>px)];
%     end
%     for i = 1:3
%         otl2 = [otl2; find(abs(T(:,i+3)-cy(i))>px)];
%     end
%     otl2 = unique(otl2);



    
    % all detected outliers
    otl = union(otl1,otl2);
    disp(['detected ',num2str(round(length(otl)/6)),' possible outliers']);
% mean corrected
    Tmr = T;
    mns = mean(T,1);
    for i = 1:6
        Tmr(otl,i) = mns(i);
    end    
% interpolate the nans
    Tint = T;
    Tint(otl,1:6) = nan; Tnans = Tint;
    t = [1:size(Tint,1)]';
    nanx = isnan(Tint(:,i));
    Tint(nanx,1:6) = interp1(t(~nanx),Tint(~nanx,1:6),t(nanx),'linear');

% summary plot
    close all;
    figure('pos',[1 1 1500 1100]);    
    hx = tight_subplot(6,1,0.03);
    for i = 1:6  
        axes(hx(i));
        jplot((Tint(:,i)),'linewidth',2); hold on;yl=ylim;
        jplot((Tmr(:,i)),'linewidth',1.5);    
        jplot((T(:,i)),'linewidth',1);
        %jplot((Tnans(:,1)),'*','linewidth',1.5);
        ylim(yl);        
%     chH = get(gca,'Children'); %uistack(hx(i),'top')
%     set(gca,'Children',[chH(end);chH(1:end-1)]);
    end
    legend('interpolated','mean corrected','original');%,'missing vals');% 'X1 original',
    %
    linkaxes(hx,'x','y');
    % find the middle of the interpolated values series and center aroun it
    tt = otl(round(end/3));
    xlim([tt-1000,tt+1000]);
    %xlim([73474.1322751323          73590.5343915344]);
    %xlim([ 53586       55586]);
    xlim([1,60*30]);
    xlabel('time (frames)');
    mtit('pupil position, X1,X2, X3, Y1 Y2 and Y3');
    print(fullfile(getfullpath(fileBase),'pupil_DLC_tracking.jpg'),'-djpeg');


% GET PRINCIPAL COMPONENTS
    rmpath(genpath('/storage2/perentos/code/thirdParty/drtoolbox'));
    [coeff, score, latent] = pca(Tint(:,1:6));

% EXTRACT A VECTOR OF pupil ORIENTATION    
for i = 1:2 % process both raw and interpolated traces
    clear L phi;
    if i == 2; v = T; elseif i == 1; v = Tint; end
    %  pupil base midpoint confirmed as long as labels 1 and 3 are indeed the pupil bases which should always be the xase
    m = [(v(:,1)+v(:,3))/2,  (v(:,4)+v(:,6))/2]; % pupil ase midpoint
    apx = [v(:,2),v(:,5)]; % pupil apex
    %L = diag(pdist2(m,apx)); % eucledian length from base midpoint to apex
    % the above susceptible to memory limitations - break it in pieces    
    lll=9;
    rs = diff(fix(linspace(0,length(m),lll+1)));
    C = mat2cell(m, rs, 2);
    D = mat2cell(apx, rs, 2);
    for jj = 1:lll
        Lcell{jj} = diag(pdist2(C{jj},D{jj}))';
    end
    L = cell2mat(Lcell)';
    phi = acos((apx(:,1)-m(:,1))./L).*sign(m(:,2)-apx(:,2)); % eucledian angle of said vector wrt to the x-axis of the 

    [Out, XBins, YBins, Pos] = hist2([rad2deg(phi),L],100,100);
    XBins = XBins(2:end) - mean(diff(XBins))/2;
    YBins = YBins(2:end) - mean(diff(YBins))/2;   
    
    if i == 2
        pupil.vector.raw.phi = phi;
        pupil.vector.raw.L   = L;
        pupil.vector.raw.baseMidPoint   = m;
        pupil.vector.raw.apex = apx;
        pupil.vector.raw.polarDistr = Out;
        pupil.vector.raw.polarXBins = XBins;
        pupil.vector.raw.polarYBins = YBins;
    elseif i == 1
        pupil.vector.int.phi = phi;
        pupil.vector.int.L   = L;
        pupil.vector.int.baseMidPoint = m;
        pupil.vector.int.apex   = apx;        
        pupil.vector.int.polarDistr = Out;
        pupil.vector.int.polarXBins = XBins;
        pupil.vector.int.polarYBins = YBins;
    end

end


% SUMMARY PLOT
close all;
cd(fullfile(getFullPath(fileBase),'video'));
lst = dir('top*.avi');
if length(lst) == 1
    obj = VideoReader(lst.name);
end

figure('pos',[10 10 1100 800]); subplot(3,4,[1 2 5 6] );
for oo = 9%1:100
    obj.CurrentTime = oo-1;
    fr = obj.readFrame;
    imshow(fr); hold on;
    nPx = 100;
    xlim([cx-nPx cx+nPx]);
    ylim([cy-nPx cy+nPx]);
    plot(T(oo,1),T(oo,4),'xr','markersize',14,'linewidth',2);
    plot(T(oo,2),T(oo,5),'xg','markersize',14,'linewidth',2);
    plot(T(oo,3),T(oo,6),'xb','markersize',14,'linewidth',2);
    plot([m(oo,1) T(oo,2)],[m(oo,2) v(oo,5)],'w');
    plot(xlim,[m(oo,2) m(oo,2)])
    title(['frame ',int2str(oo),',  ',num2str(rad2deg(pupil.vector.raw.phi(oo))),char(176)]);
    view(-90,90);
    %pause; clf;
end


subplot(3,4,[3 4]);%subplot(3,4,[3 4 7 8]);
[h,c] = polarPcolor(pupil.vector.raw.polarYBins,pupil.vector.raw.polarXBins,pupil.vector.raw.polarDistr','Nspokes',4,'Ncircles',2,'Rscale','log');
view(180, -90);
c.YLabel.String = 'raw signal';
subplot(3,4,[7 8]);
[h,c] = polarPcolor(pupil.vector.int.polarYBins,pupil.vector.int.polarXBins,pupil.vector.int.polarDistr','Nspokes',4,'Ncircles',2,'Rscale','log');
view(180, -90)
c.YLabel.String = 'interp. signal';

subplot(3,4,[9 10]);
histogram(rad2deg(pupil.vector.raw.phi),[-60:2:60]);%[N1,X1] = 
set ( gca, 'xdir', 'reverse' );
hold on;
histogram(rad2deg(pupil.vector.int.phi),[-60:2:60]); %[N2,X2] = 
set ( gca, 'xdir', 'reverse' )
xlabel(['pupil direction (',char(176),')']); 
ylabel(['count (',char(35),')']); 
legend('raw','interpolated');
axis tight;hold on;

subplot(3,4,[11 12]);
histogram(pupil.vector.raw.L,[0:0.5:40]); hold on;
histogram(pupil.vector.int.L,[0:0.5:40]);
xlabel(['pupil length (pixels)']); ylabel(['count (',char(35),')']); axis tight;
xlim([0 40]);legend('raw','interpolated');
ForAllLabels('fontsize', 10, 'fontweight','normal');
ForAllSubplots('set(gca,''TickDir'',''out'',''box'',''off'',''fontsize'',10)');
print(fullfile(getfullpath(fileBase),'pupil_angle.jpg'),'-djpeg');

% ASSEMBLE REMAINING VARIABLES
    pupil.dataRaw = T;
    pupil.dataInterp = Tint;
    pupil.dataMr= Tmr;
    pupil.varNames = varNames;
    pupil.otl1 = otl1;
    pupil.otl2 = otl2;
    pupil.otl = otl;
    note.px = px;
    pupil.PCs.coeff = coeff;
    pupil.PCs.score = score;
    pupil.PCs.latent= latent;  
    pupil.note = {'dataMr: mean corrected','dataIntert:interpolated',...
                 'otl1:outliers based on DLC posterior',...
                 'otl2:outliers based on center of mass',...
                 'otl:union of otl1 & otl2',...
                 'px:center of mass displacement allowed (in pixels)',...
                 'PCs:principal compoents'};

  

% SAVE
    disp('saving pupil data...');
    save(fullfile(getfullpath(fileBase),['pupilTracking.mat']),'pupil');  
    disp(['pupil tracking data saved in ', fullfile(getfullpath(fileBase)),'pupilTracking.mat']);
    disp('DONE!');  
%}

