function [ContrastSaliency,DP_OP,FB,PR,MP,labels,RCmap,bpWeightedmap,Sample]=RegionLocalContrast(rawDepth,SmoothedDepth,Img,pcloud,normals,NFD,labels,GOP,PriorSel)
   [h,w,chn] = size(Img);
    Depth01 = SmoothedDepth./max(max(SmoothedDepth));


%% 进行SLIC图像分割，得到超像素图像 
%     spnumber =250;
%     [labels, adjcMatrix, PixList] = SLIC_Split(Img, spnumber);
% 
%   AreaProb=cellfun(@length,PixList,'UniformOutput',false).';
%   AreaProb = cell2mat(AreaProb).';
%   AreaProb = AreaProb./max(AreaProb);
%   
%   numClusters = length(AreaProb);
%% 进行meanshift图像分割，得到超像素图像 

if labels ==0

 SpatialBandwidth =6;%6 
 RangeBandwidth =4.5; %4.5
 MinimumRegionArea = 100; 
 

 [fimage labels modes regSize]=edison_wrapper(Img,@RGB2Lab,'SpatialBandWidth',SpatialBandwidth,...
     'RangeBandWidth',RangeBandwidth,'MinimumRegionArea',MinimumRegionArea,'synergistic',true,...
     'EdgeStrengthThreshold',0.1);
   labels = labels +1;
   AreaProb = double(regSize).';
   AreaProb = AreaProb./max(AreaProb);  

end


   [PixList,adjcMatrix,numClusters,totNeighborNum]=GetLabelsProp(labels);  

   if labels ~=0
     AreaProb=cellfun(@length,PixList,'UniformOutput',false).';
     AreaProb = cell2mat(AreaProb).';
     AreaProb = AreaProb./max(AreaProb);
   end
    
    meanRgbCol = GetMeanColor(Img, PixList);
    meanLabCol = colorspace('Lab<-', double(meanRgbCol)/255);
    [meanPos,CenterPos] = GetNormedMeanPos(PixList, h, w);
 
    
    

 
%% 载入Normal Flux Density  
if normals == 0 
    % 自己计算每个region的surface normal
%     tic
    [RegionNormal,RegionDepth] = GetRegionNormal(rawDepth,pcloud,CenterPos);
    NFDf = abs(RegionNormal(3,:))./sqrt(RegionNormal(1,:).^2 + RegionNormal(2,:).^2 +RegionNormal(3,:).^2 );
    NFDf = NFDf.';
    
    medianNfDf =0.5*( mean(mean(NFDf(RegionDepth<10)))+min(min(NFDf(RegionDepth<10))));
    NFDf(RegionDepth<10) = medianNfDf;
    
%     toc
else


    NFD = regionprops(labels,NFD,'PixelValues');
    NFDPixels =struct2cell(NFD);
    NFDf=cellfun(@mean,NFDPixels).';
    
 end

    
    DepthPixels= regionprops(labels,Depth01,'PixelValues');
    DepthPixels = struct2cell(DepthPixels);
    depthProb=cellfun(@mean,DepthPixels).';   
      


 %% Get super-pixel properties

    
    %寻找边缘Region 的IDs
    bdIds = GetBndPatchIds(labels);

%    bdIds = [bdIds;distIds];
     bdIds = [bdIds];

    meanrgbd = [meanLabCol,80.*depthProb];
    
    OrtDistM = GetDistanceMatrix(NFDf);
    rgbdDistM = GetDistanceMatrix(meanrgbd);
    posDistM = GetDistanceMatrix(meanPos);
    [clipVal, geoSigma, neiSigma] = EstimateDynamicParas(adjcMatrix, rgbdDistM);
% geoSigma = 7;
neiSigma = 10;
    
    
  %% 背景建模方法1： Robust Background 论文中利用无向图得到的背景先验    
    [bgProb, bdCon, bgWeight] = EstimateBgProb(rgbdDistM, adjcMatrix, bdIds, clipVal, geoSigma);

  %% 背景建模方法2： 构建背景GMM模型
%   BgPixIdx = [];
%   for k=1:length(bdIds)
%       BgPixIdx = [BgPixIdx;PixList{k}];
%   end
%     tmpImg = RGB2Lab(Img);
%     tmpImg=reshape(double(tmpImg), h*w, chn);
%     bStripArr = [tmpImg(BgPixIdx,:),Depth(BgPixIdx).*100].';
% %     bStripArr = [tmpImg(BgPixIdx,:)].';  
%   %     AllArr = [meanLabCol];
%      AllArr = [meanLabCol,depthProb.*100];   
%     
%   
%     nComponents = 3;
% 
%     AllArr = meanrgbd;
%     bStripArr = meanrgbd(bdIds,:).';
%      
%     bgProb = zeros(numClusters,1);
%     
%     if length(bStripArr)>5
%             [bPriors, bMu, bSigma] = EM_init_kmeans(bStripArr, nComponents);
%         %     [bPriors, bMu, bSigma] = EM(bStripArr, bPriors, bMu, bSigma);
% 
%                 btmp = zeros(numClusters, nComponents);
%         %             s = (2*pi)^(3/2); 
%                       s = (2*pi)^(4/2); 
%              for ii = 1 : nComponents
%                 bDiff(:, 1) = AllArr(:, 1) - bMu(1, ii);
%                 bDiff(:, 2) = AllArr(:, 2) - bMu(2, ii);
%                 bDiff(:, 3) = AllArr(:, 3) - bMu(3, ii);
%                 bDiff(:, 4) = AllArr(:, 4) - bMu(4, ii);
% 
%                 btmp(:, ii) =  -log(( bPriors(ii) / (s * sqrt(det(bSigma(:, :, ii))))) ...
%                                     * exp(-sum((bDiff * inv(bSigma(:, :, ii)) .* bDiff), 2) /2) ...
%                                     + 1e-100);
%             end
% 
%             bPr = min(btmp, [], 2);
%             bPr = bPr-min(min(bPr));
%             bPr = bPr./max(bPr);
%             bgProb = 1-bPr;    
%     end


    bgProb(bdIds) = 1;
  %%  基于背景先验，计算反差    

  [ RC,BpWeightedMap,fgProb] = CalWeightedContrast(rgbdDistM, posDistM, bgProb,AreaProb, depthProb,NFDf,PriorSel);% fgProb是利用反差加先验得到的显著图

   MixPrior =   sqrt(1 - depthProb).*NFDf.*(1-bgProb);
   
   MixPrior = (MixPrior - min(MixPrior))./(max(MixPrior)-min(MixPrior));
   
   
   [optwCtr,PRvalue,SampleIdx] = GlobalOptimization(adjcMatrix, bdIds, rgbdDistM, OrtDistM, neiSigma, bgProb, fgProb,GOP);


%% 
    RCmap= zeros(size(labels));
    bpWeightedmap= zeros(size(labels));
    MP = zeros(size(labels));
    DP=zeros(size(labels));
    OP=zeros(size(labels));
    PR=zeros(size(labels));
    Sample = zeros(size(labels));
    
    ContrastSaliency=zeros(size(labels));
    bgPrior = zeros(size(labels));
    fgPrior = zeros(size(labels));

     for k=1:numClusters  
        regionMap=(labels==k);
        fgPrior(regionMap) = fgProb(k);
        bgPrior(regionMap) = bgProb(k);
        ContrastSaliency(regionMap) = optwCtr(k);
        DP(regionMap) = 1-depthProb(k);
        OP(regionMap) = NFDf(k);
        PR(regionMap) = PRvalue(k);
        MP(regionMap) = MixPrior(k);

        
        RCmap(regionMap) = RC(k);
        bpWeightedmap(regionMap) = BpWeightedMap(k);
        
        if ~isempty(find(SampleIdx==k,1))
        Sample(regionMap) = 1;
        else 
            Sample(regionMap)=0;
        end
     end
      FB = cat(3,fgPrior,bgPrior);
      DP_OP = cat(3,DP,OP);  

     
