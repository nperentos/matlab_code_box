function yfilt = convolve_signal(y, kernelsize, kernelsigma, kerneltype)
if nargin<4 || isempty(kerneltype); kerneltype = 'gaussian'; end;

x = linspace(-kernelsize / 2, kernelsize / 2, kernelsize);

switch kerneltype;
    case 'gaussian'; 
        kernel = exp(-x .^ 2 / (2 * kernelsigma ^ 2));
        kernel = kernel / sum (kernel); % normalize
end

yfilt = conv (y, kernel, 'same');