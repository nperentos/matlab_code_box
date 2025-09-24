function [mu, C, nX] = smoothKNNgray(X,k,varargin)
% [mu, C, nX] = smoothKNNgray(X,k,[u_init,usesmooth])
% use only knn can already five nice results.
isprint = false;
isplot = false;
usesmooth = false;
if nargin>3 && ~isempty(varargin{2})
    usesmooth = varargin{2};
end
[ny, nx] = size(X);
%%
% 1. vector form of gradient. 
% Dx = spdiags([[-ones(nx-1,1) ones(nx-1,1)]; zeros(1,2)],[0 -1],nx, nx);
% Dx = kron(Dx', eye(ny));
% 
% Dy = spdiags([[-ones(nx-1,1) ones(nx-1,1)]; zeros(1,2)],[0 1],ny, ny);
% Dy = kron(eye(nx), Dy);

X = reshape(X, nx*ny, 1); 
% origninal ny*ny*ncolor
% working on the shape of npixel*ncolor

%%
lx = nx*ny;
% k = 5;
[IDX, C] = kmeans(X, k);
% onstruct the distance matrix from u to C
f = zeros(lx, k);
eps = .1;
tau = .25;
alpha = .01;
tol = 1e-6;
if nargin>2 && ~isempty(varargin{1})
%     initRand = false;
    u = varargin{1};
    if size(u,2)<2
        tmp = zeros(size(u,1),k);
        for kk = 1:k
            tmp(u==kk,kk) = 1;
        end
        u = tmp;
    end
else
    % initRand = 1;%1;%true; % use random initialization
    u = zeros(lx,k);% score matrix of npixel*ncluster
    for n = 1:k
        f(:,n) = sqrt(sum(bsxfun(@minus, X, C(n,:)).^2 , 2));
        u(IDX == n, n)=1; % initialize with the kmeans solution
    end
end
if usesmooth
nplotTol = 2;% plot difference every nplotTol steps. 
if initRand
    u = rand(lx, k); % initialize with random matrix...
    % comment: initialize with the kmeans solution converge very fast as
    % expect, initialize with random matrix converge to similar solution.
    % gradient of E and optimization
end
dDu = @(x)((Dx'*Dx+ Dy'*Dy ) *x)./sqrt(sum((Dx*x).*2 + (Dy*x).*2 +eps));
cont = 0;
distu = 100;
while cont < 2000 && distu >tol
    dEu = f ; % gradient of E: <u,f> term
    for kk = 1:k
        ss= sqrt((Dx*u(:,kk)).^2 + (Dy*u(:,kk)).^2 +eps);
        dEu(:,kk) = dEu(:,kk) + alpha *(Dx'*((Dx *u(:,kk))./ss) + Dy'*((Dy *u(:,kk))./ss));%  dDu(u(:,kk));
        % gradient of E: |Du| term
    end
    ou = u;
    u = projSimplex((ou - tau*dEu));% equ.(3)
    cont = cont+1;
    distu = ((ou(:)-u(:))'*(ou(:)-u(:))/lx);
    if isprint
        if ~mod(cont,nplotTol)
            fprintf('\ntol: %.6f', distu)
        end
    end
end
end
[dummy, mu]=max(u,[],2);
su = accumarray(mu,1);
C = accumarray(mu,X(:))./su;
% for kk = 1:k
%     C(kk) = mean(X(u(:,kk)>0));
% end
% lazy way to reorder, but doesn't take too long anyway
[C,idxC] = sort(C);
u = u(:,idxC);
[dummy, mu]=max(u,[],2);
nX = zeros(size(X));
for kk = 1:k
    km = mu == kk;
    nX(km,:) = repmat(C(kk,:),  sum(km),1); % recolor
end
nX = reshape(nX, ny,nx);
if isplot
%
figure(1);
subplot(1,3,3)
imshow(reshape(nX, ny,nx, 3))
fprintf('\nConverge with %d steps.', cont)
end
% fprintf('\nConverge with %d steps.', cont)
end
function u = projSimplex(f)
% projSimplexMatlab, project the rows of f onto the unit simplex 

N = size(f, 1);
L = size(f, 2);

y = sort(f, 2, 'descend');
tmpsum = zeros(N, 1);
active = logical(ones(N, 1));
for ii=1:L-1
    tmpsum(active) = tmpsum(active) + y(active, ii);
    tmax(active) = (tmpsum(active) - 1)/ii;
    active = (tmax' < y(:, ii + 1));
end
tmax(active) = (tmpsum(active) + y(active, L) - 1) / L;
u = max(reshape(f, [N L]) - repmat(tmax', 1, L), 0);

end