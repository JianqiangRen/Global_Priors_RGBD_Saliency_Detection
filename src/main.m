close all,clear,clc
addpath('..\edison_matlab_interface\');
addpath('..\dataset\RGB\');
addpath('Funcs\');

ImgIndex ='10_03-31-22';

%% load RGB image
img=imread(strcat(ImgIndex,'.jpg'));

%% load depth image(both smoothed and raw depth,we need estimate oriention prior for depth-lost regions)
load(strcat('..\dataset\smoothedDepth\',ImgIndex,'_Depth.mat'));
DepthImage =double(smoothedDepth);
DepthImage =DepthImage-min(min(DepthImage));  
load(strcat('..\dataset\rawDepth\',ImgIndex,'_Depth.mat'));    
pcloud = DepthToCloud(smoothedDepth);
     
tic
   [salmap,labels] = GPSaliency(img,rawDepth,smoothedDepth,pcloud,false,false,true,false,'PR+MRF','BDN111');
toc

 

