% labels: 超像素分割后得到的labels
function [RegionNormal,RegionDepth] = GetRegionNormalandDepth(rawDepth,pcloud,CenterPos)

    pcloud =double(pcloud);
    rows = size(pcloud,1);
    
    
    RegionDepth = zeros(size(CenterPos,1),1);
    
  
    CenterIndex = zeros(size(CenterPos,1),1);
    
    for i=1:size(CenterPos,1)
        CenterIndex(i) = CenterPos(i,1) +(CenterPos(i,2) - 1).*rows; 
        
        RegionDepth(i) = rawDepth(CenterPos(i,1),CenterPos(i,2));
    end
    
    
    x =pcloud(:,:,1);
    y =pcloud(:,:,2);
    z =pcloud(:,:,3);
    x=x(:);
    y=y(:);
    z=z(:);
    points = [x,y,z];


   if size(points,2)==3 && size(points,1)~=3
        points = points';
    end
    
    RegionNormal = lsqnormest(points, 200,CenterIndex);%原来是100

 


function n = lsqnormest(p, k, CenterIndex)
m = size(CenterIndex,1);
n = zeros(3,m);

v = ver('stats');
if str2double(v.Version) >= 7.5 
    neighbors = transpose(knnsearch(transpose(p), transpose(p), 'k', k+1));
else
    neighbors = k_nearest_neighbors(p, p, k+1);
end


for i = 1:m
    x = p(:,neighbors(2:end, CenterIndex(i)));
    p_bar = 1/k * sum(x,2);
    
    P = (x - repmat(p_bar,1,k)) * transpose(x - repmat(p_bar,1,k)); %spd matrix P
    %P = 2*cov(x);
    
    [V,D] = eig(P);
    
    [~, idx] = min(diag(D)); % choses the smallest eigenvalue
    
    n(:,i) = V(:,idx);   % returns the corresponding eigenvector   
end