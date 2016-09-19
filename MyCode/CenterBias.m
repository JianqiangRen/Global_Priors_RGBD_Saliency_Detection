function B=CenterBias(A,CenterBiasValue)

[p,q]=size(A);
Mask=fspecial('gaussian',127,CenterBiasValue);
Mask=imresize(Mask,[p,q]);
Mask=Mask/max(Mask(:));
% figure,imshow(Mask,[]);
B=A.*Mask;