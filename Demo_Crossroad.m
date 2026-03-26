clear all;
close all;
addpath(genpath('./Data'));
addpath(genpath('./Methods'));
load Crossroad

I=size(Xs);
Rlabel(1,:,:)=ROI;
Rlabel=repmat(Rlabel,[I(1),1,1]);
mask=mask&Rlabel;

mask_reshape = reshape(mask, 1, []);
fore_map = mask_reshape;                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           
back_map = ~mask_reshape;
back_map=back_map&Rlabel(:)';

%% RPCC
N=ndims(Xs);

std_inv=sqrt(1e3); 

shape_re=[1,I(1),1,I(2),1,I(3),I(4),1];
Xg=BlockUnfold(Xs,shape_re);
X_corrupted=Xs+std_inv^(-1)*randn(I);



R_CP=15;%%You need at least 30 to recreate the performance reported in the paper, 
%         which will cost around 100GB RAM, please get a prepared machine.



Pi0=0.5;
a0=1e-5;b0=1e-5;c0=1e-5;d0=1e-5;
alpha0=1;beta0=1;
MaxLoop=1e3;
Pru_tol=1e-5;
Con_tol=1e-5;%% Convergence Tolerance

[~,~,det_map] = BCP_RPCC(X_corrupted,Xs,R_CP,shape_re,std_inv^2,Pi0,a0,b0,c0,d0,alpha0,beta0,Pru_tol,MaxLoop,Con_tol);
% X_est=ktensor(A);
% X_est=double(X_est);


det_map=det_map&Rlabel(:)';
Pre= sum(det_map & fore_map)/sum(det_map);
Rec= sum(det_map & fore_map)/sum(fore_map);
F1Score=2*Pre*Rec/(Pre+Rec)
IoU=sum(det_map & fore_map)/sum(det_map | fore_map)
FalseAlarm=sum(det_map & back_map)/sum(back_map);