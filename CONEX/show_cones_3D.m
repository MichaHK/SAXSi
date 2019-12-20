function show_cones_3D(Theta)

Nt=length(Theta);

Xmin_d=max([0.1 min(1-0.5*tan(Theta))]); 
Xmax_d=1.1;

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