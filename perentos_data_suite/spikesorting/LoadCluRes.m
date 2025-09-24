%
% A simple matlab function to load from the .clu and .res files the vectors G and T
% from many electrodes 
% Usage: [T,G,Map,Par]=LoadCluRes(FileBase,ElGpsToLoad, ClusToLoad)
% Enter the FileBase without the extension .clu or .res
% ElGpsToLoad - list of electrode groups to load (load them all by default)
% ClusToLoad allows to specifiy the vector of El numbers in ElGpsToLoad and
% matching length vector of Clu numbers (original indexing) such that only
% those are loaded
% alternatively ClusToLoad can specify ElClu pairs , and then ElGspToLoad
% can be just unique list of electrodes to load where these ElClu pairs are
% T is in samples, G goes from 1 to total number of clusters (excludes
% noise and artifacts )
% Map is a matrix displaying the correspondance between new cluster numbers (first column) and inital
% shank # (second column) and cluster # (third column)
% Pascale production, Anton just helped and made few additions :))
function [T,G,Map,Par]=LoadCluRes(FileBase,varargin)

%FileBase = ResolvePath(FileBase,0);

%Par = LoadPar([FileBase '.xml']);
%FileBase = fullfile(getfullpath(FileBase),'KS');

pth = getfullpath(FileBase);

[ElGpsToLoad, ClusToLoad, Kilosort] = DefaultArgs(varargin,{1,[],1});

G=[];
T=[];
Map=[];
Par=[];
maxG=0;

% Loop over x=ElGpsToLoad from LoadPar

for x=ElGpsToLoad(:)'
    % for each ElGp, load clu and res
    if ~FileExists(fullfile(pth,[FileBase '.clu.' num2str(x)]))
        continue;
    end
    g = LoadClu(fullfile(pth,[FileBase '.clu.' num2str(x)]));
    fid = fopen(fullfile(pth,[FileBase '.res.' num2str(x)]),'r');
    t = fscanf(fid,'%d'); %faster than load
    fclose(fid);
    %    t=load([FileBase '.res.' num2str(x)]);

    % Removes clusters artifact and noise clusters (0 & 1)
    if ~Kilosort
        indx=(g>1);
        if sum(indx)==0
            continue;
        end;
        g=g(indx);
        t=t(indx);
        
        maxG;
        % creates vector of initial g and renames cluster # since 1 to n
        [ugini,b,g]=unique(g); % ugini: vector of initial unique values of g
        max(g);
        g=maxG+g;
        ug=unique(g);
   
        % Creates a "map" matrix
        shk=zeros(length(ug),1)+x; % electrode #
        map=[ug,shk,ugini];
        Map=[Map;map];
    end
    % concatenates all the g and t
    G=[G;g];
    maxG=max(G);
    T=[T;t];
end
%sort the spikes not to have surprizes later -A
[T si] = sort(T);
G=G(si);

%now more fancy : if one specifies [El Clu] pairs to load
if ~isempty(ClusToLoad)
    if length(ClusToLoad)~=length(ElGpsToLoad) & size(ClusToLoad,2)~=2 
        warning('length(ClusToLoad)~=length(ElGpsToLoad)');
        return;
    end
   if size(ClusToLoad,2)~=2 
       myi = find(ismember(Map(:,2:3),[ElGpsToLoad(:), ClusToLoad(:)],'rows'));
   else
       myi = find(ismember(Map(:,2:3),ClusToLoad,'rows'));
   end
   gi = ismember(G, myi);    
   G = G(gi);
   T = T(gi);
   [uclu dummy G] = unique(G);
   Map = [[1:length(myi)]' Map(myi,2:3)];
   
end
    
display('successfully loaded clu and res as T,G,Map,Par');