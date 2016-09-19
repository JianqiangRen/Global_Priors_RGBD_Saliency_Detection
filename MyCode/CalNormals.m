clc,clear,close all
addpath('..\Dataset\RealCloudValue\');
addpath('..\Dataset\RGB\');
ImgIndex = '1_02-02-40';
img = imread(strcat(ImgIndex,'.jpg'));
[r,c,d]=size(img);

load(strcat(ImgIndex,'_DepthReal.mat'));
points =double(points);

normals = points2normals(points);
NormFluxDensity = abs(normals(3,:))./sqrt(sum(normals.*normals,1));
NormFluxDensity = reshape(NormFluxDensity,r,c);
savepath = strcat('E:\Study\CVPR2015NEW\Dataset\NormFluxDensity\',ImgIndex,'_NormFluxDsty.mat');
 save (savepath, 'NormFluxDensity');
