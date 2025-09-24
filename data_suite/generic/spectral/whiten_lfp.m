% It works well but it introduces a phase shift of about 1ms.
% I can consider using Filter0, however my experimentation shows that it
% produces a larger phase delay.
% DO NOT use filtfilt. It gives spurious results (it applies the model in
% both ways and leads to an approximately ~f structure to the spectrum.
%
% Author: Nikolas Karalis
% Date : June 2013
% Updates : 27/11/2013 (NK) Tried filters and concluded on using simple
% filter and not filtfilt or Filter0
% Added the functionality to run it on 2D matrices.
% Updates : 25/12/2013 (NK) I changed the way it is applied on 2D matrices.
% The model parameters are calculated based on the first trace and then
% the same are applied to all the other lfps.

function [lfp_whitened, A] =whiten_lfp(lfp,varargin)
options = {'sr',1000,'model','burg','window',4,'plot',0,'order',2};
options = inputparser(varargin,options);
if strcmp(options,'error'); return; end;

doubleflag=0;
if ~strcmp(lfp,'double'); lfp = double(lfp); doubleflag=1; end;

if ~isvector(lfp) && size(lfp,2)>size(lfp,1)
   display what? 
end;

if isempty(options.window) || length(lfp)<options.window*options.sr;
    windowsize = length(lfp);
else
    windowsize = options.window*options.sr;
end;

if isvector(lfp)
    if strcmp(options.model,'burg')
        [A, NoiseVariance] = arburg(lfp(1:windowsize),options.order);
    elseif strcmp(options.model,'yule')
        [A, NoiseVariance] = aryule(lfp(1:windowsize),options.order);
    elseif strcmp(options.model,'cov')
        [A, NoiseVariance] = arcov(lfp(1:windowsize),options.order);
    elseif strcmp(options.model,'mcov')
        [A, NoiseVariance] = armcov(lfp(1:windowsize),options.order);
    end;
    lfp_whitened=filter(A,1,lfp);
else
    if strcmp(options.model,'burg')
        lfp_whitened=zeros(size(lfp));
        [A, NoiseVariance] = arburg(double(lfp(1,1:windowsize)),options.order);
        for c=1:size(lfp,1)
            lfp_whitened(c,:)=filter(A,1,lfp(c,:));
        end;
    elseif strcmp(options.model,'yule')
        lfp_whitened=zeros(size(lfp));
        [A, NoiseVariance] = aryule(double(lfp(1,1:windowsize)),options.order);
        for c=1:size(lfp,1)
            lfp_whitened(c,:)=filter(A,1,lfp(c,:));
        end;
    elseif strcmp(options.model,'cov')
        lfp_whitened=zeros(size(lfp));
        [A, NoiseVariance] = arcov(double(lfp(1,1:windowsize)),options.order);
        for c=1:size(lfp,1)
            lfp_whitened(c,:)=filter(A,1,lfp(c,:));
        end;
    elseif strcmp(options.model,'mcov')
        lfp_whitened=zeros(size(lfp));
        [A, NoiseVariance] = armcov(double(lfp(1,1:windowsize)),options.order);
        for c=1:size(lfp,1)
            lfp_whitened(c,:)=filter(A,1,lfp(c,:));
        end;
    end;
end;

if doubleflag; lfp_whitened=single(lfp_whitened); end;

if strcmp(options.plot,'on') || options.plot;
    figure; calculate_spectrum(lfp,options.sr); hold on; calculate_spectrum(lfp_whitened,options.sr,'color','r');
end;