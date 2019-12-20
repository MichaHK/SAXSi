function Theta = GetThetaForXY(x, y, DetectorPosition)
alpha=DetectorPosition(1); d=DetectorPosition(2); Xd=DetectorPosition(3);
Yd=DetectorPosition(4); beta=DetectorPosition(5);

XX=Xd+x*cos(beta)-y*sin(beta);
YY=Yd-x*sin(beta)-y*cos(beta);

xx=YY*cos(alpha);
yy=-XX;
zz=d/cos(alpha)-YY*sin(alpha);

Dist=sqrt(xx.^2+yy.^2+zz.^2);
%Theta=180*acos(zz./Dist)/pi;
Theta=acos(zz./Dist);
end
