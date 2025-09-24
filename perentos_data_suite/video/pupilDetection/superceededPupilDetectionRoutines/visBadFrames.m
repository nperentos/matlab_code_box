% loop over bad frames just to visualise
% figure('units','normalized','outerposition',[0 0 1 1])
figure('Position',[-978   378   972   903]);
pause(1);
for i = flagND(2:end)
    next = false;
    %imshow(all.frames(i).cdata(:,:,1));
    imagesc(all.frames(i).cdata(:,:,1));
    colormap gray;
    hold on;
    bx  = tracked(i).BoundingBox;
    ofs = pupilData.rct(1:2);
    
    bx  = [bx(1)+ofs(1) bx(2)+ofs(2) bx(3) bx(4)];    
    rectangle('Position',bx,'EdgeColor',[1 0 0]);
    title(int2str(i));
    gcf;%set(gcf,'Position',[-978   37es8   972   903])
    while ~next
        prompt = 'press enter for next: ';
        str = input(prompt,'s');        
        gcf;
        if strcmp('','')
            next = true;
        end
    end
    clf;
end