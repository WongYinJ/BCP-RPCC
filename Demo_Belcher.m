clear all;
close all;
addpath(genpath('./Data'));
addpath(genpath('./Methods'));

load Belcher.mat
Xs=data;
mask=map;

[H,W,Dim]=size(Xs);
num=H*W;

for i=1:Dim
    Xs(:,:,i) = (Xs(:,:,i)-min(min(Xs(:,:,i)))) / (max(max(Xs(:,:,i))-min(min(Xs(:,:,i)))));
end

mask_reshape = reshape(mask, 1, []);
anomaly_map = mask_reshape;                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           
normal_map = ~mask_reshape;
%% RPCC
Xp = PCA_img(Xs, 5);
N=ndims(Xp);
I=size(Xp);
for i=1:I(3) 
    Xp(:,:,i) = (Xp(:,:,i)-min(min(Xp(:,:,i)))) / (max(max(Xp(:,:,i))-min(min(Xp(:,:,i)))));
end 

std_inv=sqrt(3e2);


shape_re=[1,I(1),1,I(2),I(3),1];
% Xg=BlockUnfold(Xp,shape_re);
X_corrupted=Xp+std_inv^(-1)*randn(I);


R_CP=35;
Pi0=0.5;
a0=1e-5;b0=1e-5;c0=1e-5;d0=1e-5;
alpha0=1;beta0=1;
MaxLoop=1e3;
Pru_tol=1e-5;
Con_tol=1e-5;

[~,~,det_map] = BCP_RPCC(X_corrupted,Xp,R_CP,shape_re,std_inv^2,Pi0,a0,b0,c0,d0,...
    alpha0,beta0,Pru_tol,MaxLoop,Con_tol);


Pre= sum(det_map & anomaly_map)/sum(det_map);
Rec= sum(det_map & anomaly_map)/sum(anomaly_map);
F1Score=2*Pre*Rec/(Pre+Rec)
IoU=sum(det_map & anomaly_map)/sum(det_map | anomaly_map)
FalseAlarm=sum(det_map & normal_map)/sum(normal_map)