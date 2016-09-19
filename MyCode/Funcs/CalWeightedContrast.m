function [ RC,BpWeightedMap,wCtr] = CalWeightedContrast(colDistM, posDistM, bgProb,AreaProb,depthProb,NormProb,PriorSel)
% Calculate background probability weighted contrast
 

spaSigma = 0.3;     %sigma for spatial weight 0.2ÈÝÒ×È¥³ýµ××ù£¬
posWeight = Dist2WeightMatrix(posDistM, spaSigma);

%bgProb weighted contrast
if strcmp(PriorSel,'BDN000')==1
    wCtr = colDistM .* posWeight * (AreaProb);
end
if strcmp(PriorSel,'BDN001')==1
    wCtr = colDistM .* posWeight * (AreaProb) .*NormProb;
end
if strcmp(PriorSel,'BDN010')==1
    wCtr = colDistM .* posWeight * (AreaProb) .*sqrt(1-depthProb);
end
if strcmp(PriorSel,'BDN011')==1
    wCtr = colDistM .* posWeight * (AreaProb) .*sqrt(1-depthProb).*NormProb;
end
if strcmp(PriorSel,'BDN100')==1
    wCtr = colDistM .* posWeight * (AreaProb.*bgProb) ;
end
if strcmp(PriorSel,'BDN101')==1
    wCtr = colDistM .* posWeight * (AreaProb.*bgProb)  .*NormProb;
end
if strcmp(PriorSel,'BDN110')==1
    wCtr = colDistM .* posWeight * (AreaProb.*bgProb) .*sqrt(1-depthProb);
end
if strcmp(PriorSel,'BDN111')==1
    wCtr = colDistM .* posWeight * (AreaProb.*bgProb) .* sqrt(1-depthProb).*NormProb;
end

RC = colDistM .* posWeight * (AreaProb);
BpWeightedMap =  colDistM .* posWeight * (AreaProb.*bgProb) ;


wCtr = (wCtr - min(wCtr)) / (max(wCtr) - min(wCtr) + eps);

%post-processing for cleaner fg cue
removeLowVals = true;
if removeLowVals
    thresh = graythresh(wCtr);  %automatic threshold
    wCtr(wCtr < thresh) = 0;
end