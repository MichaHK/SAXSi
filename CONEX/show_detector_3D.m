function show_detector_3D(calibration_file,Theta,detector)

if detector==0
    show_cones_3D(Theta);
    return
end

F=calibration_file;
M=F(1); N=F(2); alpha_rad=F(3); d=F(4); Xd=F(5); Yd=F(6); beta_rad=F(7);
Ld=sqrt(M^2+N^2);
Nt=length(Theta);

%--------------------------------------------------------------------------
% Detector

    eX=[0 1 0];
    eY=[-sin(alpha_rad) 0 cos(alpha_rad)];

    ex=cos(beta_rad)*eX-sin(beta_rad)*eY;
    ey=-sin(beta_rad)*eX-cos(beta_rad)*eY;

    Detector=[d/cos(alpha_rad) 0 0]+[Xd*eX+Yd*eY];
    Angles(1,:)=[Detector];
    Angles(2,:)=Angles(1,:)+M*ey;
    Angles(3,:)=Angles(2,:)+N*ex;
    Angles(4,:)=Angles(1,:)+N*ex;

    XX=[Angles([1;2;3],1) Angles([1;3;4],1)];
    YY=[Angles([1;2;3],2) Angles([1;3;4],2)];
    ZZ=[Angles([1;2;3],3) Angles([1;3;4],3)];

    hold on;
    p=patch(XX,YY,ZZ,[0.25 0.25 0.25]);
    set(p,'EdgeColor','none');

Xmin_d=max([0 min(XX(:))-Ld/2]); 
Xmax_d=max(XX(:))+Ld/10;

%--------------------------------------------------------------------------
% Cones

Nx=5; xx=linspace(Xmin_d,Xmax_d,Nx)';
Nphi=30; pphi=linspace(-pi,pi,Nphi)';
NV=Nx*Nphi; VV=zeros(NV,3);
NF=(Nx-1)*(Nphi-1)*2; FF=zeros(NF,3);
XX=zeros(3,NF); YY=zeros(3,NF); ZZ=zeros(3,NF);

for t=1:Nt
    theta=Theta(t);
    
    %Vertices
    for nx=1:Nx
        R=xx(nx)*tan(theta);
        VV((nx-1)*Nphi+1:nx*Nphi,1)=xx(nx)*ones(Nphi,1);
        VV((nx-1)*Nphi+1:nx*Nphi,2)=R*cos(pphi);
        VV((nx-1)*Nphi+1:nx*Nphi,3)=R*sin(pphi);
    end

    %Faces
    cpt=0;
    for nx=1:Nx-1
       for np=1:Nphi-1
           cpt=cpt+1;
           FF(cpt,:)=[(nx-1)*Nphi+np (nx-1)*Nphi+np+1 nx*Nphi+np]; 
           cpt=cpt+1;
           FF(cpt,:)=[(nx-1)*Nphi+np+1 nx*Nphi+np nx*Nphi+np+1];            
       end
    end
    
    %Coordinates
    for nf=1:NF
        idx=FF(nf,:)';
        XX(:,nf)=VV(idx,1); YY(:,nf)=VV(idx,2); ZZ(:,nf)=VV(idx,3);        
    end
    
    hold on;
    p=patch(XX,YY,ZZ,[0.5 0.5 0.7]);
    set(p,'EdgeColor','none');
    alpha(p,0.5);

end

%--------------------------------------------------------------------------

axis('equal')
axis('tight')
view(75,25)
axis('off')

end