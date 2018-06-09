function [ContrastSaliency,DP_OP,FB,PR,MP,labels,RCmap,bpWeightedmap,Sample]=RegionLocalContrast(rawDepth,SmoothedDepth,Img,pcloud,normals,NFD,labels,GOP,PriorSel)
   [h,w,chn] = size(Img);
    Depth01 = SmoothedDepth./max(max(SmoothedDepth));

%% superpixel using SLIC
%   spnumber =250;
%   [labels, adjcMatrix, PixList] = SLIC_Split(Img, spnumber);
% 
%   AreaProb=cellfun(@length,PixList,'UniformOutput',false).';
%   AreaProb = cell2mat(AreaProb).';
%   AreaProb = AreaProb./max(AreaProb);
%   
%   numClusters = length(AreaProb);
%% superpixel using meanshift
if labels ==0
 SpatialBandwidth =6;%6 
 RangeBandwidth =4.5; %4.5
 MinimumRegionArea = 100; 
 
 [fimage, labels, modes, regSize]=edison_wrapper(Img,@RGB2Lab,'SpatialBandWidth',SpatialBandwidth,...
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
    % calculate suface normal for each region
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
    %get id of boundary-connected regions
    bdIds = GetBndPatchIds(labels);
    bdIds = [bdIds];
    meanrgbd = [meanLabCol,80.*depthProb];
    
    OrtDistM = GetDistanceMatrix(NFDf);
    rgbdDistM = GetDistanceMatrix(meanrgbd);
    posDistM = GetDistanceMatrix(meanPos);
    [clipVal, geoSigma, neiSigma] = EstimateDynamicParas(adjcMatrix, rgbdDistM);
% geoSigma = 7;
   neiSigma = 10;  
   [bgProb, bdCon, bgWeight] = EstimateBgProb(rgbdDistM, adjcMatrix, bdIds, clipVal, geoSigma);
   bgProb(bdIds) = 1;  
   [RC,BpWeightedMap,fgProb] = CalWeightedContrast(rgbdDistM, posDistM, bgProb,AreaProb, depthProb,NFDf,PriorSel);% fgProb是利用反差加先验得到的显著图

   MixPrior = sqrt(1 - depthProb).*NFDf.*(1-bgProb);
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

     
