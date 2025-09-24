function plotTraj(data,varargin)
    % plots trajectory in 3D space as a function time. data can be 2 or
    % 3-D. if clr_var is not provided then the trajectory is colorcoded by
    % time. clr_var can be any variable that is sampled on the time scale
    % as data.
    % INPUT:
    % data: a matrix timepoints x neuron
    % clr_var: a variable the same length as data used to color the
    % trajectory (can be speed, position etc)
    % ax: an axis handle in which to plot

    
    options = {'clr_var',[],'style', 0, 'ax',[], 'rec', 0, 'st_sz', 100};
    options = inputparser(varargin,options);
    
    
    if isempty(options.clr_var) % color by time
        
        CMap=colormap(jet(length(data)));
        dbin = 1:length(data);
    elseif ~isempty(options.clr_var) & options.style == 1 % continuous colormap
        display('using a (pseudo) continuous color map');
        n = 256;
        CMap = colormap(jet(n));
        [a,b,dbin] = histcounts(options.clr_var,n-1);
    elseif ~isempty(options.clr_var) & options.style == 2 % discrete colormap
        display('using a discrete color map');
        CMap = distinguishable_colors(length(unique(options.clr_var)),[1 1 1; 0 0 0]);
        n = 50;
        [a,b,dbin] = histcounts(options.clr_var,n-1);
    else
        error('unexpected function inputs?');
    end
    
    
    %figure; plot(normalize_array1(clr_var)); hold on; plot(-dbin/256);
    lims = [min(data(:,1)) max(data(:,1)) min(data(:,2)) max(data(:,2)) min(data(:,3)) max(data(:,3))];
    
    if isempty(options.ax)
        figure; axes;%LineH = line(1, 1);
    else
        ax = findobj(options.ax);
        axes(ax);
    end
    
    
    if isempty(options.rec) || options.rec == 0
        rec = 0;
    elseif options.rec == 1
        rec = 1;
    end
    
    % rotate angles for better visualisation
    el = [-90:1:90 89:-1:-89];Lel = length(el);
    el = repmat(el,ceil(length(data)/Lel),1);
    el = reshape(el',1,numel(el));
    
    az = [-360:2:360 359:-2:-359];Laz = length(az);
    az = [-45:1:45 44:-1:-44];Laz = length(az);
    az = repmat(az,ceil(length(data)/Laz),1);
    az = reshape(az',1,numel(az));
        
    if size(data,2) == 3     
        xlabel('pPCA factor 1'); 
        ylabel('pPCA factor 2');
        zlabel('pPCA factor 3');

        % change color of curve as a function clr_var (tested with tScale,
        % idxTrials and speed from the peripheralsPP.mat ppp structure
        st_sz = options.st_sz; i = 1;        
        line(data(1:st_sz,1),data(1:st_sz,2),data(1:st_sz,3),'color',CMap(1,:)); 
        hold on; grid on; 
        view(-100,52);%view(-75,2);

        if rec
            myVideo = VideoWriter('pPCA'); %open video file
            myVideo.FrameRate = 15;  %can adjust this, 5 - 10 works well for me
            open(myVideo)
        end
        
        for k = st_sz+1:st_sz:length(data)-st_sz
            line(data(k-1:k+st_sz,1),data(k-1:k+st_sz,2),data(k-1:k+st_sz,3),'color',CMap(dbin(k),:),'linewidth',2);            
            axis(lims); %view(az(i),el(i));
            drawnow;     
            i = i+1;
            if rec
                frame = getframe(gcf); %get frame
                writeVideo(myVideo, frame);
            end
        end
        
        close(myVideo)


    
    %     if size(data,2) == 3
    %         
    %         LineH = plot3(data(1,1),data(1,2),data(1,3));
    %         for k = 2:10:length(data)
    %             oldX = get(LineH, 'XData');
    %             oldY = get(LineH, 'YData');
    %             oldZ = get(LineH, 'ZData');
    %             X    = data(k,1);
    %             Y    = data(k,2);
    %             Z    = data(k,3);
    %             set(LineH, 'XData', [oldX, X], 'YData', [oldY, Y], 'ZData', [oldZ, Z],'color',CMap(k,:));
    %             drawnow; axis(lims); view(az(k),el(k));
    %         end
    elseif size(data,2) == 2
        LineH = plot(data(1,1),data(1,2));
        for k = 2:10:length(data)
            oldX = get(LineH, 'XData');
            oldY = get(LineH, 'YData');
            X    = data(k,1);
            Y    = data(k,2);
            set(LineH, 'XData', [oldX, X], 'YData', [oldY, Y]);
            %pause(0.01);
            drawnow;
        end
    else
        error('bad data');
    end        
