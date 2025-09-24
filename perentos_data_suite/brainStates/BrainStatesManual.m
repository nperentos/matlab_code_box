

function periods = BrainStatesManual(fn, varargin)
%%
parsp = inputParser;

   validNum = @(x) isnumeric(x);
     addRequired(parsp,'fn');
     addParameter(parsp,'SaveFile',1,validNum);
      
  parse(parsp, fn, varargin{:});

  ain = parsp.Results;

  
%% get periods for brain states
periods.NREM=[];
periods.REM=[];
periods.WK=[];
periods.QW=[];

%NREM sleep
a=1;
while a==1;
prompt = 'NREM periods? Y/N [Y]: ';
str = input(prompt,'s');
if isempty(str)
    str = 'Y';
end

if ismember(str,'Y')
    
[xst,~]=ginput(2);

if xst(2)>xst(1) periods.NREM=cat(1,periods.NREM,xst'); end

else
    a=0;
end

end

%REM sleep

a=1;
while a==1;
prompt = 'REM periods? Y/N [Y]: ';
str = input(prompt,'s');
if isempty(str)
    str = 'Y';
end

if ismember(str,'Y')
    
[xst,~]=ginput(2);
if xst(2)>xst(1) periods.REM=cat(1,periods.REM,xst'); end

else
    a=0;
end

end

%Wake

a=1;
while a==1;
prompt = 'Wake periods? Y/N [Y]: ';
str = input(prompt,'s');
if isempty(str)
    str = 'Y';
end

if ismember(str,'Y')
    
[xst,~]=ginput(2);

if xst(2)>xst(1) periods.WK=cat(1,periods.WK,xst'); end

else
    a=0;
end

end

% Quiet wake

a=1;
while a==1;
prompt = 'Quiet Wake periods? Y/N [Y]: ';
str = input(prompt,'s');
if isempty(str)
    str = 'Y';
end

if ismember(str,'Y')
    
[xst,~]=ginput(2);

if xst(2)>xst(1) periods.QW=cat(1,periods.QW,xst'); end

else
    a=0;
end

end


%% save periods

if ain.SaveFile == 1
if isempty(fn)
save('periods.mat','periods');
else
  save([fn '/' 'periods.mat'],'periods');  
end
end
end
