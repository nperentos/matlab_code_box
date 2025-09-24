function [csd, z, t] = inverseCSD(lfp, varargin)
%CurSrcDnsInverse is a function which calculates 1D inverse current source density (iCSD) from LFP
%using an explicit inversion of the electrostatic forward solution (Pettersen et al., 2006, J. Neurosci Methods) .
%iCSD estimator incorporates a prior knowledge about the horizontal spread of the activation and spatially
%varying extracellular condactivity. The CSD is assumed to have cylindrical symmetry.
%iCSD can be computed by three methods:
%   delta iCSD, where the CSD localized in infinitely thin discs in the planes of electrode contacts, 
%   step iCSD, where  the CSD is stepwise constant, 
%   spline iCSD, where the CSD is continuous and smoothly varying (using
%   cubic splines) in the vertical direction.
%
%The core scripts are parts of CSDplotter toolbox taken from    http://compneuro.umb.no/wiki/Miscellaneous/Downloads
%See also user_guide.pdf in /csd/CSDplotter-0.1.1/
%
%NOTE:
%   It is recommended to filter out frequencies out of interest before computing CSD to reduce spatial noise.
%   LFP must have no bad channels (not implemented yet).
%   In contrast with the standard CSD method, the inter-contact distances do not need to be constant in the iCSD methods.
%This could be a big advantage, e.g. if one electrode contact is shown to be defect. This problem could be solved by simply
%taking the erroneous electrode contact data out of the potential matrix in the pre-processing stage and omitting the electrode
%contact position in the Electrode Positions vector.
%
%
%USAGE:    [csd, z] = CurSrcDnsInverse(lfp, <elPos>, <Method>, <SamplingRate>, <Diam>, <GaussSigma>, <Cond>, <CondTop>)
%
%INPUT:
% lfp   is a matrix with LFP where each column is a data from a single electrode.
% <SamplingRate> -  is a sampling rate of LFP (1250 Hz).
% <elPos>    is the vector containing the electrode contact positions (mm) below the cortical surface.
%                  This vector could be written on any matlab vector form, i.e. [0.1 0.2 0.3], [0.1,0.2,0.3] and 0.1:0.1:0.3 all produces the
%                  same result, three electrode contacts placed at cortical depths 0.1 mm, 0.2 mm and 0.3 mm. Default value is
%                  [0.1 : 0.05 : 1.65] which means that the first electrode contact is placed 0.1 mm below the cortical surface,
%                  the inter-contact distance is 0.05 mm and the electrode contains 32 contacts. By definition, the vector length of elPos
%                  must equal the number of columns of the LFP matrix.
%                  Note: spline iCSD method requires non-zero first contact position.
%                  Note: different from the standard CSD method the inter-contact distances do not need to be constant in the iCSD methods.
% <Cond>, <CondTop> -  the extracellular conductivities (siemens/m) in (elPos>0) and above (elPos<0) the cortex.
%                 The conductivity above cortex depends on which substance the experimentalist has used on top of cortex to prevent
%                  it from drying out during the experiment. If top Cond. is different from ex. Cond., the absolute positions of the electrode
%                  contacts are used, and the method requires that all contacts are put into cortex (elPos>0). If top Cond. equals ex. Cond.,
%                  the inter-contact distances are the only important values, thus all values are accepted. Default = 0.3 S/m for both.
% <Diam>     is an effective diameter of the cortical region that was activated by stimuli and that generated CSDs(mm). Default = 0.5mm.
% <GaussSigma>  is  the standard deviation (mm) of a continuous spatial  gaussian filter applied to continuous step- and spline iCSD
%                         instead of a  three-point Hamming filter used in a discrete delta iCSD. Default = 0.5 mm.
% <Method>
%
%OUTPUT:
% CSD - csd matrix
% Z is a vector with corresponding Z coordinate (either channels or continous)

%
%EXAMPLE:    [ csd, z] = CurSrcDnsInverse(lfp,[], 'step');
%
% Evgeny Resnik
% version 13.03.2013

% SamplingRate = 1250;
% Method='delta'
% Times=[];


%Check number of parameters
if nargin < 1
    error('USAGE:  [csd, z] = CurSrcDnsInverse(lfp, <elPos>, <Method>, <SamplingRate>, <Diam>, <GaussSigma>, <Cond>, <CondTop>)');
end

%Parse input parameters
[elPos, Method, SamplingRate, Diam, GaussSigma, Cond, CondTop ] = DefaultArgs(varargin,{ [0.1 : 0.05 : 1.65], 'spline', 1000, 0.5, 0.05, 0.3, 0.3 });


%Ensure that columns are data from individual channels
if size(lfp,1)<size(lfp,2)
    lfp = lfp';
end

%Number of channels
nCh = size(lfp,2);

if length(elPos) ~= nCh
    error('Number of electrode contacts in elPos must equal the number of columns of the LFP matrix!')
end


%Compute necessary parameters
%Time resolution=1/Fs (ms)
dt = 10^3/SamplingRate;
%Convert mm to m
Diam = Diam/10^3;
GaussSigma = GaussSigma/10^3;
elPos = elPos/10^3;


%Initialize constants
%Extent of the numeric spatial gaussian filter (for step- and spline iCSD)
FilterRange = 5*GaussSigma;
%Spatial three-points Hamming filter coefficients [b1 b0 b1]
b0 = 0.54;
b1 = 0.23;


% %Create time vector if not provided (s)
% if isempty(Times)
%     Times = [1:size(lfp,1)]/(SamplingRate);
% end


switch lower(Method)
    
    case 'delta' % delta iCSD
        
        CSD = F_delta(elPos, Diam, Cond, CondTop)^-1*lfp';
        if b1~=0 %filter iCSD
            [n1,n2]=size(CSD);
            CSD_add(1,:) = zeros(1,n2);   %add top and buttom row with zeros
            CSD_add(n1+2,:)=zeros(1,n2);
            CSD_add(2:n1+1,:)=CSD;        %CSD_add has n1+2 rows
            CSD = S_general(n1+2,b0,b1)*CSD_add; % CSD has n1 rows
        end
        %CSD = CSD(2:end-1,:);
        CSD = CSD/10^3; % A/m^3 -> muA/mm^3
        CSD = CSD';
        %output parameters
        csd = CSD;
        z = elPos;
        
        
    case 'step'
        
        CSD = F_const(elPos, Diam, Cond, CondTop)^-1*lfp';
        % make CSD continous (~200 points):
        le = length(elPos);
        h = elPos(2)-elPos(1);
        first_z = elPos(1)-h/2; %plot starts at z1-h/2;
        mfactor = ceil(200/le);
        minizs = 0:h/mfactor:(mfactor-1 )*h/mfactor;
        for i=1:size(CSD,1) % all rows
            zs((1:mfactor)+mfactor*(i-1)) = first_z+(i-1)*h+minizs;
            new_CSD_matrix((1:mfactor)+mfactor*(i-1),:) = repmat(CSD(i,:),mfactor,1);
        end
        %filter iCSD
        if GaussSigma~=0
            [zs, new_CSD_matrix] = gaussian_filtering(zs, new_CSD_matrix, GaussSigma, FilterRange);
        end;
        new_CSD_matrix = new_CSD_matrix/10^3; % A/m^3 -> muA/mm^3
        new_CSD_matrix = new_CSD_matrix';
        %output parameters
        csd = new_CSD_matrix;
        z = zs;
        
        
    case 'spline'
        
        %Creates the F matrix of the cubic spline method.
        Fcs = F_cubic_spline(elPos, Diam, Cond, CondTop);
        %LFP matrix must be arranged so: rows - signals from different electrodes
        [zs, CSD] = make_cubic_splines(elPos, lfp', Fcs);
        %filter iCSD
        if GaussSigma~=0
            [zs, CSD]=gaussian_filtering(zs, CSD, GaussSigma, FilterRange);
        end
        CSD = CSD/10^3; % A/m^3 -> muA/mm^3
        CSD = CSD';
        %output parameters
        csd = CSD;
        z = zs;
        
        
    otherwise
        error('Method must be either <delta> or <step> or <spline> !')
end %switch