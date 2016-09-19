close all,clear,clc
addpath('..\edison_matlab_interface\');


SpatialBandwidth =6; 
 RangeBandwidth =4.5; 
 MinimumRegionArea = 100; 
 
 path = 'E:\Study\CVPR2015NEW\Dataset\RGB\';
 
  DepthMat_list = dir(strcat(path,'*.jpg'));%获取该文件夹中所有jpg格式的图像
    mat_num = length(DepthMat_list);%获取图像总数量


    tr=0;
    for j = 1:mat_num %逐一读取图像

         img_name = DepthMat_list(j).name;% 图像名  
 
         ImgIndex = img_name(1:end-4);
              fprintf('%d %s\n',j,strcat(path,img_name));% 显示正在处理的图像名
              
              
         Img=imread(strcat(path,ImgIndex,'.jpg')); 
              
              
 [fimage labels modes regSize]=edison_wrapper(Img,@RGB2Lab,'SpatialBandWidth',SpatialBandwidth,...
     'RangeBandWidth',RangeBandwidth,'MinimumRegionArea',MinimumRegionArea,'synergistic',true,...
     'EdgeStrengthThreshold',0.1);
 
  B=[1 1 1 
    1 1 1 
    1 1 1 ];
    A2=imdilate(labels,B);%图像A1被结构元素B膨胀
   diff = A2-labels;
   a=zeros(size(diff));
   a(diff>0)=1;
   a = uint8(a);
   r = Img(:,:,1);
   g = Img(:,:,2);
   b = Img(:,:,3);
   
   r(a==1)=255;
   g(a==1)=0;
   b(a==1)=0;
   ImgSeg = cat(3,r,g,b);
   
 figure,imshow(ImgSeg,[]);
 savepath = strcat(path,ImgIndex,'_seg.png');
%  imwrite(ImgSeg,savepath);
              
              
    end

 