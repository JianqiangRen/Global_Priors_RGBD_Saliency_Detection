function [PixList,adjcMatrix,numClusters,totNeighborNum]=GetLabelsProp(labels)
    [h,w] = size(labels);
    totNeighborNum = 0;
    PixList = regionprops(labels,'PixelList'); 
    PixList =struct2cell(PixList).';
    numClusters = size(PixList,1);
    
    adjcMatrix = zeros(numClusters);
  
   B=[1 1 1 
      1 1 1 
      1 1 1 ];
       

   
   for i = 1:numClusters   
       PixList{i}=h*(PixList{i}(:,1)-1)+PixList{i}(:,2);      

       RegionMask = zeros(size(labels));
       RegionLocation = find(labels==i);
       RegionMask(RegionLocation) = 1;

       RegionMaskDilate = imdilate(RegionMask,B);
       RegionExtBound = logical(RegionMaskDilate -RegionMask);
       NeighborLabels = labels(RegionExtBound);
       NeighborLabels = unique(NeighborLabels);      
%        Neighborlist{i}=NeighborLabels;
       totNeighborNum = totNeighborNum + length(NeighborLabels);
       adjcMatrix(i,NeighborLabels) = 1;
       adjcMatrix(i,i) = 1;
   end
        adjcMatrix =sparse(adjcMatrix);
end