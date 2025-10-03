% I need to improve accuracy
% Maybe with Timer class

function pausebar(time, message, frequency, cancellable,fontoptions)
if nargin <2 || isempty(message); message = 'Waiting'; end;
if nargin <3 || isempty(frequency); frequency = 0.5; end;
if nargin <4 || isempty(cancellable); cancellable=1; end;

if cancellable;
    h = waitbar(0,message,'CreateCancelBtn','setappdata(gcbf,''canceling'',1)');
else;
    h = waitbar(0,message);
end;
    
if nargin>4;
    titleHandle = get(findobj(h,'Type','axes'),'Title');
    if iscell(fontoptions) & ~mod(length(fontoptions),2);
        for k=0:(length(fontoptions)/2)-1
            set(titleHandle,fontoptions{k*2+1},fontoptions{k*2+2});
        end
    end
end

setappdata(h,'canceling',0)
steps = time*frequency;

tic;
for step = 1:steps
    if getappdata(h,'canceling')
        break
    end
    pause(1/frequency)
    %java.lang.Thread.sleep(1000/frequency) % An alternative, supposedly
    %better way, but from my tests makes no difference.
    
    waitbar(step / steps)       
end
toc;
delete(h) 