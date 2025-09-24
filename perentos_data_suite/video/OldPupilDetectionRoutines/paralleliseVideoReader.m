% parallelise video reader/processor
%%
tic;
load('/storage2/perentos/data/recordings/NP19/NP19_2018-10-10_13-30-36/processed/pupilInit.mat');
    poolobj = gcp;
    addAttachedFiles(poolobj,{'processCurrentFrameMorpho.m'})
    spmd
        obj = VideoReader('side_cam_1_date_2018_10_10_time_13_30_28_v001.avi');        
        a = round(obj.Duration/12);
        r = 1:a:obj.Duration;
        if r(end) < obj.Duration; r = [r, obj.Duration]; end
%         a = round(957/12);
%         r = 1:a:957;
%         if r(end) < 957; r = [r, 957]; end                
    % labindex 1    
        if labindex == 1
            obj.CurrentTime = r(1);
            display(['Starting frame:  ',int2str(obj.CurrentTime)])
            to = r(2)
            for j = 1:to
                if hasFrame(obj)
                    huo = readFrame(obj);
                    sect{j} = processCurrentFrameMorpho(huo,pupilInit);%huo(:,:,1);
                else
                    break
                end
            end
        end
    % labindex 2    
        if labindex == 2
            obj.CurrentTime = r(2);
            display(['Starting frame:  ',int2str(obj.CurrentTime)])
            to = r(2+1)-r(2)
            for j = 1:to
                if hasFrame(obj)
                    huo = readFrame(obj);
                    sect{j} = processCurrentFrameMorpho(huo,pupilInit);%huo(:,:,1);
                else
                    break
                end
            end
        end  
    % labindex 3    
        if labindex == 3
            obj.CurrentTime = r(3);
            display(['Starting frame:  ',int2str(obj.CurrentTime)])
            to = r(3+1)-r(3)      
            for j = 1:to
                if hasFrame(obj)
                    huo = readFrame(obj);
                    sect{j} = processCurrentFrameMorpho(huo,pupilInit);%huo(:,:,1);
                else
                    break
                end
            end
        end
    % labindex 4  
        if labindex == 4
            obj.CurrentTime = r(4);
            display(['Starting frame:  ',int2str(obj.CurrentTime)])
            to = r(4+1)-r(4)      
            for j = 1:to
                if hasFrame(obj)
                    huo = readFrame(obj);
                    sect{j} = processCurrentFrameMorpho(huo,pupilInit);%huo(:,:,1);
                else
                    break
                end
            end
        end
    % labindex 5
        if labindex == 5
            obj.CurrentTime = r(5);
            display(['Starting frame:  ',int2str(obj.CurrentTime)])
            to = r(5+1)-r(5)     
            for j = 1:to
                if hasFrame(obj)
                    huo = readFrame(obj);
                    sect{j} = processCurrentFrameMorpho(huo,pupilInit);%huo(:,:,1);
                else
                    break
                end
            end
        end 

    % labindex 6
        if labindex == 6
            obj.CurrentTime = r(6);
            display(['Starting frame:  ',int2str(obj.CurrentTime)])
            to = r(6+1)-r(6)     
            for j = 1:to
                if hasFrame(obj)
                    huo = readFrame(obj);
                    sect{j} = processCurrentFrameMorpho(huo,pupilInit);%huo(:,:,1);
                else
                    break
                end
            end
        end  
    % labindex 7
        if labindex == 7
            obj.CurrentTime = r(7);
            display(['Starting frame:  ',int2str(obj.CurrentTime)])
            to = r(7+1)-r(7)     
            for j = 1:to
                if hasFrame(obj)
                    huo = readFrame(obj);
                    sect{j} = processCurrentFrameMorpho(huo,pupilInit);%huo(:,:,1);
                else
                    break
                end
            end
        end      
    % labindex 8
        if labindex == 8
            obj.CurrentTime = r(8);
            display(['Starting frame:  ',int2str(obj.CurrentTime)])
            to = r(8+1)-r(8)    
            for j = 1:to
                if hasFrame(obj)
                    huo = readFrame(obj);
                    sect{j} = processCurrentFrameMorpho(huo,pupilInit);%huo(:,:,1);
                else
                    break
                end
            end
        end  
    % labindex 9
        if labindex == 9
            obj.CurrentTime = r(9);
            display(['Starting frame:  ',int2str(obj.CurrentTime)])
            to = r(9+1)-r(9)    
            for j = 1:to
                if hasFrame(obj)
                    huo = readFrame(obj);
                    sect{j} = processCurrentFrameMorpho(huo,pupilInit);%huo(:,:,1);
                else
                    break
                end
            end
        end  
    % labindex 10
        if labindex == 10
            obj.CurrentTime = r(10);
            display(['Starting frame:  ',int2str(obj.CurrentTime)])
            to = r(10+1)-r(10)    
            for j = 1:to
                if hasFrame(obj)
                    huo = readFrame(obj);
                    sect{j} = processCurrentFrameMorpho(huo,pupilInit);%huo(:,:,1);
                else
                    break
                end
            end
        end  
    % labindex 11
        if labindex == 11
            obj.CurrentTime = r(11);
            display(['Starting frame:  ',int2str(obj.CurrentTime)])
            to = r(11+1)-r(11)   
            for j = 1:to
                if hasFrame(obj)
                    huo = readFrame(obj);
                    sect{j} = processCurrentFrameMorpho(huo,pupilInit);%huo(:,:,1);
                else
                    break
                end
            end
        end  
    % labindex 12
        if labindex == 12
            obj.CurrentTime = r(12);
            display(['Starting frame:  ',int2str(obj.CurrentTime)])
            to = r(12+1)-r(12)    
            for j = 1:to
                if hasFrame(obj)
                    huo = readFrame(obj);
                    sect{j} = processCurrentFrameMorpho(huo,pupilInit);%huo(:,:,1);
                else
                    break
                end
            end
        end      
    end
toc
sectlocal = [sect{1}];
for i = 2:12
    sectlocal = [sectlocal,sect{i}];
end
res = [sectlocal{:}];
res = (reshape(res,4,length(res)/4))';
toc