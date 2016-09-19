close all,clear,clc
addpath('..\edison_matlab_interface\');
addpath('..\Dataset\RGB\');
 addpath('Funcs\');

ImgIndex = '10_03-31-22';

%% Load RGB Image
img=imread(strcat(ImgIndex,'.jpg'));


%% Load Depth Image(Both smoothed and raw depth,we need estimate oriention prior for depth-lost regions)
    load(strcat('..\Dataset\smoothedDepth\',ImgIndex,'_Depth.mat'));
    DepthImage =double(smoothedDepth);
    DepthImage =DepthImage-min(min(DepthImage));  

    load(strcat('..\Dataset\rawDepth\',ImgIndex,'_Depth.mat'));

%% Load point cloud(previously convert depth image to point cloud)
     load(strcat('..\Dataset\RealCloudValue\',ImgIndex,'_DepthReal.mat'));
 
tic
   [salmap,labels] = myRGBDsal(img,rawDepth,smoothedDepth,pcloud,0,0,1,0,'PR+MRF','BDN111');
toc

 

