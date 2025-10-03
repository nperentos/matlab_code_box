function interpolation = interpolate_waveforms(waveforms, ratio)
[ly, lx]= size(waveforms);

x=1:lx;
xx=linspace(1,lx,lx*ratio);

interpolation = zeros(ly,lx*ratio);
for s=1:ly
    interpolation(s,:) = spline(x,waveforms(s,:),xx);
end;