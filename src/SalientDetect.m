function [salmap,labels] = SalientDetect(img255,rawDepth,SmoothedDepthImage,pcloud,normals,NFDSmoothed,showfigure,labels,GOP,PriorSel)

SmoothedDepthImage =double(SmoothedDepthImage);

%% calculate salient-map via global priors method
[ContrastSaliency,DP_OP,FB,PR,MP,labels,RCmap,bpWeightedmap,sample]=GPSal(rawDepth,SmoothedDepthImage,img255,pcloud,normals,NFDSmoothed,labels,GOP,PriorSel);
salmap = ContrastSaliency;

salmap = salmap - min(min(salmap));
salmap = salmap./max(max(salmap));
salmap = salmap.*salmap;

%% show figure or not
if showfigure == 1
   B=[1 1 1 1 1
    1 1 1 1 1
    1 1 1 1 1
    1 1 1 1 1
    1 1 1 1 1];

   A2=imdilate(labels,B);
   diff = A2-labels;
   a=zeros(size(diff));
   a(diff>0)=1;
   a = uint8(a);
   r = img255(:,:,1);
   g = img255(:,:,2);
   b = img255(:,:,3);
   
   r(a==1)=255;
   g(a==1)=0;
   b(a==1)=0;
   ImgSeg = cat(3,r,g,b);

   
%% save intermediate result
RCmap = RCmap-min(min(RCmap));
bpWeightedmap = bpWeightedmap - min(min(bpWeightedmap));
DP_OP(:,:,2) = DP_OP(:,:,2) - min(min(DP_OP(:,:,2)));
DP_OP(:,:,1) = DP_OP(:,:,1) - min(min(DP_OP(:,:,1)));

%% imshow
%figure,imshow(ImgSeg,[]);title('RGB Img');
figure,
subplot(2,5,1),imshow(ImgSeg,[]);title('RGB Img');
subplot(2,5,2),imshow(SmoothedDepthImage,[]);title('Depth');
subplot(2,5,3),imshow(DP_OP(:,:,1),[]);title('DepthPrior');
subplot(2,5,4),imshow(DP_OP(:,:,2),[]);title('OrientationPrior');
subplot(2,5,5),imshow(1-FB(:,:,2),[]);title('BgPrior');
subplot(2,5,6),imshow(MP,[]);title('mixPrior(DP*OP*BP)');
subplot(2,5,7),imshow(FB(:,:,1),[]);title('PriorCombinedContrast');
subplot(2,5,8),imshow(PR,[]);title('PageRanking');
subplot(2,5,9),imshow(ContrastSaliency,[]);title('NoSquaredSaliency');
subplot(2,5,10),imshow(salmap,[]);title('SquaredSaliency');
end