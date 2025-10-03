function out=readlines(fn,nlines)
if nargin<2 | nlines<=0 | isempty(nlines); nlines = 0; end;

fid = fopen(fn);

out={};
c=1;
while 1
    % Get a line from the input file
    tline = fgetl(fid);
    % Quit if end of file
    if ~ischar(tline)
        break;
    end
    out{c} = tline;
    c=c+1;
    
    if nlines>0 & c>nlines; break; end;
end

fclose(fid);