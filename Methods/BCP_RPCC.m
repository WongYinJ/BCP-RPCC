function [A,R_CP,det_map] = BCP_RPCC(X,IniX,R_CP,shape_re,sigma,Pi0,a0,b0,c0,d0,alpha0,beta0,Pru_tol,MaxLoop,Con_tol)
%RPCC_CP 此处显示有关此函数的摘要
%   此处显示详细说明
%% Initialization
fprintf('========Initializing========\n');
I=size(X);
N=ndims(X);

% A=cp_als(tensor(IniX),R_CP);
A=cp_als(tensor(IniX),R_CP,'printitn',0);%for HAD
A = normalize(A,0);
Amu=cell(1,N);
Avar=cell(1,N);
AIni=cell(1,N);
for n=1:N
%     Amu{n}=randn(R_CP,I(n));
     AIni{n}=(A.U{n}(:,1:R_CP));
     Amu{n}=(A.U{n}(:,1:R_CP))';
    Avar{n}=repmat(eye(R_CP),1,1,I(n));
end
% X_Ini=ktensor(A);
% X_Ini=double(X_Ini);
% IniError=norm(Unfold(X_Ini-Xs,2))/norm(Unfold(Xs,2))
a=a0*ones(R_CP,1);b=b0*ones(R_CP,1);
Xg=BlockUnfold(X,shape_re);
[Ig,Ng]=size(Xg);
c=c0*ones(1,Ng);d=d0*ones(1,Ng);
Pi=Pi0*ones(1,Ng);
alpha=alpha0;beta=beta0;

% % omega_is=sparse(Ng,prod(I));
% % omega_xis=sparse(Ng,prod(I));
% % for ng=1:Ng
% %     aux=zeros(Ig,Ng);
% %     aux(:,ng)=logical(ones(Ig,1));
% %     omega_is(ng,:)=reshape(BlockFold(aux,shape_re),1,[]);
% %     omega_xis(ng,:)=sparse(reshape(BlockFold(aux,shape_re).*X,1,[]));
% % end

ELB=[0];
%% Main Loop
fprintf('========Main Loop Starts========\n');
for loop=1:MaxLoop
    %%Posterior of A
    PI=repmat(Pi,[Ig,1]);
    for n=1:N
        EZis_=Unfold(BlockFold(PI,shape_re),n);
        Xis_=Unfold(X,n);
        AuxCell=cell(1,N);
        AmuT=cell(1,N);
        for m=[1:n-1,n+1:N]
                AuxCell{m}=(khatrirao(Amu{m},Amu{m})+Unfold(Avar{m},3)')';
                AmuT{m}=Amu{m}';
        end
        AuxCell=AuxCell(1,[1:n-1,n+1:N]);
        AmuT=AmuT(1,[1:n-1,n+1:N]);
        for i=1:I(n) 
            EZis=EZis_(i,:);
            Xis=Xis_(i,:);
            Avar{n}(:,:,i)=(sigma*reshape((1-EZis)*khatrirao(AuxCell,'r'),R_CP,R_CP)+diag(a./b))^(-1);
            Avar{n}(:,:,i)=Avar{n}(:,:,i)+10^(log(realmin)/log(10)/R_CP)*eye(R_CP);%% For numerical stability
            Amu{n}(:,i)=sigma*Avar{n}(:,:,i)*khatrirao(AmuT,'r')'*((1-EZis).*Xis)';
        end
    end
    %%Posterior of lambda
    a=(a0+sum(I)/2)*ones(R_CP,1);
    Aux=0;
    for n=1:N
        Aux=Aux+diag(Amu{n}*Amu{n}')+diag(sum(Avar{n},3));
    end
    b=b0+Aux/2;
    %%Posterior of tau_is
    c=c0+Ig*Pi/2;
    d=d0+Pi.*sum(Xg.^2,1)/2;
    %%Posterior of Z_is
    omega1=-sum(Xg.^2,1)/2.*c./d+Ig/2*log(2*pi)+Ig/2*(psi(c)-log(d))+psi(alpha)-psi(alpha+beta);
    AuxCell=cell(1,N);
    AmuT=cell(1,N);
    for m=[1:N]
       AuxCell{m}=(khatrirao(Amu{m},Amu{m})+Unfold(Avar{m},3)')';
       AmuT{m}=Amu{m}';
    end
    omega2=-sigma/2*(sum(BlockUnfold(reshape(sum(khatrirao(AuxCell,'r'),2),I),shape_re),1)-...
        2*sum(BlockUnfold(reshape(sum(khatrirao(AmuT,'r'),2),I),shape_re).*Xg,1)+sum(Xg.^2,1))...
        +Ig*log(2*pi*sigma)/2+psi(beta)-psi(alpha+beta);
%      Pi=exp(omega1)./(exp(omega1)+exp(omega2));
    Pi=1./(1+exp(omega2-omega1));
    omega2_elb1=omega2-psi(beta)+psi(alpha+beta);
    %%Posterior of Pi
    alpha=alpha0+sum(Pi);
    beta=beta0+Ng-sum(Pi);
    
    %%ELB
    elb1=omega2_elb1*(1-Pi)'+...
        (-sum(Xg.^2,1)/2.*c./d+Ig/2*log(2*pi)+Ig/2*(psi(c)-log(d)))*Pi';%%term1
    aux=0;
    for n=1:N
        aux=aux+Amu{n}*(Amu{n})'+sum(Avar{n},3);
    end
    elb2=-trace(diag(a./b)*aux)/2+sum(I)/2*sum(psi(a)-log(b));
    elb3=sum(Pi.*(psi(alpha)-psi(alpha+beta))+(1-Pi).*(psi(beta)-psi(alpha+beta)));
    elb4=sum((a-1).*(psi(a)-log(b))-a);
    elb5=sum((c-1).*(psi(c)-log(d))-c);
    elb6=(alpha-1)*(psi(alpha)-psi(alpha+beta))+(beta-1)*(psi(beta)-psi(alpha+beta));
    
    elb_entropy1=0;
    for n=1:N
        for in=1:I(n)
            elb_entropy1=elb_entropy1+log(det(Avar{n}(:,:,in)));
        end
    end
    elb_entropy1=elb_entropy1+R_CP*sum(I)*(1+log(2*pi))/2;
    elb_entropy2=sum(a-log(b)+gammaln(a)+(1-a).*psi(a));
    elb_entropy3=sum(c-log(d)+gammaln(c)+(1-c).*psi(d));
    elb_entropy4=sum(-xlnx(Pi,1e-20)-xlnx(1-Pi,1e-20));
    elb_entropy5=(gammaln(alpha)+gammaln(beta)-gammaln(alpha+beta))-(alpha-1)*(psi(alpha)-psi(alpha+beta))...
        -(beta-1)*(psi(beta)-psi(alpha+beta));
    ELB=[ELB,elb1+elb2+elb3+elb4+elb5+elb6+elb_entropy1+elb_entropy2+elb_entropy3+elb_entropy4+elb_entropy5];
    %%Rank Pruning
    Pru_c=b./a;
    Pru_ind=Pru_c/sum(Pru_c)<Pru_tol;
    if sum(Pru_ind)>0
    for n=1:N
        Amu{n}(Pru_ind,:)=[];
        Avar{n}(Pru_ind,:,:)=[];
        Avar{n}(:,Pru_ind,:)=[];
    end
    a(Pru_ind)=[];
    b(Pru_ind)=[];
    end
    R_CP=sum(1-Pru_ind);
    
    A=cell(1,N);
    for n=1:N
     A{n}=Amu{n}';
    end
    X_est=ktensor(A);
    X_est=double(X_est);
    if mod(loop, 5) == 0 | loop==1
        fprintf('Iteration No.%d, Evidence Lower Bound=%.4e, ELBO Updating Stride=%.4e\n', loop, ...
            ELB(end),abs((ELB(end-1)-ELB(end))/ELB(end)));
    end
    if loop>=2
    if abs((ELB(end-1)-ELB(end))/ELB(end-1))<Con_tol
        fprintf('========Iteration No.%d，Algorithm Converges========\n', loop);
        break
    end
    end
end
A=cell(1,N);
for n=1:N
    A{n}=Amu{n}';
end
det_map=logical(Pi);
% det_map=Pi;
end

