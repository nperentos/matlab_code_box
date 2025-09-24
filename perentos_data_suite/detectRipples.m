% detect ripples - wrapper for find_ripples
% e.g. out = detectRipples(fileBase,)
function ripples = detectRipples(fileBase,varargin)
goto(fileBase);

%% Input parsing
options = {'sig',[],'sr',1000,'method','hilbert','plot',1,'ripplefreq',[80 250],'mode','auto','thr',2.5,'mincycles',4,'refsig',[], 'periods',[],'wavelet_freq',0};

options = inputparser(varargin,options);

if strcmp(options,'error'); return; end;


%% CA1 channel and reference signal (with no ripple power) definition
display('loading session data...');
[session, behavior] = loadSession(fileBase);

if exist([fileBase '.RippleChannelDetection.mat'])
    load([fileBase '.RippleChannelDetection.mat'])
else
    display('detecting ripple channel(s)...');
    out =  RippleChannelDetection(fileBase);   
end

allCh = [];
for i = 1:length(out.CA1_Chan)
    allCh = [allCh; out.MyChannelsByShank{i}];
end

%% Find ripples on anatomical groups
display('detecting ripples on each anatomical group...');
for i = 1:length(out.CA1_Chan)
    [data,settings,tScale] = getLFP(fileBase,[],[out.CA1_Chan(i),out.refsig(i)]);
    ripples{i} = find_ripples(data(1,:),'refsig',data(2,:));
    close all;
end

%% Generate an event file
ts = []; tp = [];
for i = 1:length(out.CA1_Chan)
    ts = [ts; ripples{i}.ripple_t(:)];
    tp = [tp; i.*ones(length(ripples{i}.ripple_t),1)];
end
MakeEvt(ts(:),[fileBase,'.rpl.evt'],tp(:),session.info.SR_LFP,1);

%% Save the ripples structure
save([fileBase '.' 'ripples.mat'],'ripples'); %save([FileBase '.' mfilename '.mat'],'out');

%load events example
%evv = LoadEvents([fileBase,'.rpl.evt']);