function Theta=Theta_xy(xy,DetectorPosition)

 %       M=DetectorPosition(1); N=DetectorPosition(2); 
        alpha=DetectorPosition(1); d=DetectorPosition(2); Xd=DetectorPosition(3); 
        Yd=DetectorPosition(4); beta=DetectorPosition(5);

        XX=Xd+xy(:,1)*cos(beta)-xy(:,2)*sin(beta);
        YY=Yd-xy(:,1)*sin(beta)-xy(:,2)*cos(beta);

        xx=YY*cos(alpha);
        yy=-XX;
        zz=d/cos(alpha)-YY*sin(alpha);

        Dist=sqrt(xx.^2+yy.^2+zz.^2);
        Theta=180*acos(zz./Dist)/pi;
%        Phi=180*atan(yy./xx)/pi;
    end