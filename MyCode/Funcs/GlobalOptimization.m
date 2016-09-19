function [optwCtr,PRvalue,SampleIdx] = GlobalOptimization(adjcMatrix, bdIds, colDistM, OrtDistM , neiSigma, bgWeight, fgWeight,GOP)
% Solve the Global Optimization

% Code Author: Jianqiang Ren
% Email: rjq@zju.edu.cn
% Date: 11/18/2014

adjcMatrix_nn = LinkNNAndBoundary(adjcMatrix, bdIds);
colDistM(adjcMatrix_nn == 0) = Inf;
Wn = Dist2WeightMatrix(colDistM, neiSigma);      %smoothness term
Wd = Dist2WeightMatrix(OrtDistM, 1);      %smoothness term
mu = 0.1;                                                   %small coefficients for regularization term
W = Wn + adjcMatrix * mu;                                   %add regularization term
D = diag(sum(W));

bgLambda =5;   %global weight for background term, bgLambda > 1 means we rely more on bg cue than fg cue.
E_bg = diag(bgWeight * bgLambda);       %background term
E_fg = diag(fgWeight);          %foreground term


spNum = length(bgWeight);

%% local
if strcmp(GOP,'Local')==1
    optwCtr = fgWeight;
end


%% RobustBg
if strcmp(GOP,'RobustBg')==1
    optwCtr =(D - W + E_bg + E_fg) \ (E_fg * ones(spNum, 1));
end


%% MRF
if strcmp(GOP,'MRF')==1
  cvx_begin quiet
    variable MRFSal(spNum)
        minimize(          norm((MRFSal-fgWeight) +  (D-W) * MRFSal,2)              )

 cvx_end
    optwCtr=MRFSal;
end

%% 计算Page Rank
PRMatrix =  adjcMatrix_nn.*Wd;
PRMatrix = PRMatrix-diag(diag(PRMatrix)-diag(0)); 
PRMatrix = PRMatrix./repmat(sum(PRMatrix),size(PRMatrix,1),1);
PRvalue = PRMatrix * fgWeight;
PRvalue=min(PRvalue,fgWeight);
PRvalue = (PRvalue-min(PRvalue))./(max(PRvalue)-min(PRvalue));

%% PR
if strcmp(GOP,'PR')==1
    optwCtr = PRvalue;
    SampleIdx = 0;
end


%% PR + MRF
if strcmp(GOP,'PR+MRF')==1

    %%计算采样矩阵M（选取最亮的10%和最暗的%10）
    sortPRvalue = sort(PRvalue(PRvalue > 0),'descend');
    up_thres = sortPRvalue(ceil(length(sortPRvalue).*0.5));
    low_thres = 0;
    SampleIdx =[find(PRvalue>=up_thres);find(PRvalue<=low_thres)];


    M = sparse(SampleIdx,SampleIdx,ones(length(SampleIdx),1),size(adjcMatrix,1),size(adjcMatrix,2));
    
    
  cvx_begin quiet
    variable MRFSal(spNum)

        minimize(      norm(M*(MRFSal-PRvalue) +  1.*(D-W) * MRFSal,2)              )

  cvx_end


    optwCtr=MRFSal;
end
 



 
 