% I should be rgb
function I1 = polycrop(I,BW)
if size(I,3)>1;
    I1 = rgb2gray(I);
else
    I1 = I;
end;
I1(~BW)=255;

%idx1 = sum(I1) ~= 255*size(I1,1);
%idx2 = sum(I1,2) ~= 255*size(I1,2);

idx1(1) = find(sum(BW),1,'first');
idx1(2) = find(sum(BW),1,'last');
idx2(1) = find(sum(BW,2),1,'first');
idx2(2) = find(sum(BW,2),1,'last');

idx1 = idx1(1):idx1(2);
idx2 = idx2(1):idx2(2);

I1 = I1(idx2,idx1);