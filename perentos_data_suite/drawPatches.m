function drawPatches(h,events)
if nargin ~= 2
    error('two inputs needed, handle to axes and events');
elseif size(events,2) < 2
     error(['I need a two dimensional array with the first colum being the', ...
     'start of the patches and the second one being the end of the patches']);
end

for i = 1:length(events)
    x1 = events(i,1); x2 = events(i,2);
    lms = ylim(h);
    st = fill([x1 x2 x2 x1],[lms(1) lms(1) lms(2) lms(2)],[1 1 0],'facealpha',0.5,'FaceColor','red','EdgeColor','none');
    uistack(st,'top');
end

% for i = 1:length(rewards.soundIdx)
%     x1 = tScale(rewards.soundIdx(i)); x2 = tScale(rewards.consumeIdx(i,2));
%     lms = ylim(h(1));
%     fill([x1 x2 x2 x1],[lms(1) lms(1) lms(2) lms(2)],[1 1 0],'facealpha',0.5,'FaceColor','red','EdgeColor','none');
% end