function twoTheta=GetTwoThetaForXYInRadians(DetectorPosition, x, y)

        alpha=DetectorPosition(1);
        d=DetectorPosition(2);
        Xd=DetectorPosition(3); 
        Yd=DetectorPosition(4);
        beta=DetectorPosition(5);

        XX = Xd + [x * cos(beta)] - [y * sin(beta)];
        YY = Yd - [x * sin(beta)] - [y * cos(beta)];

        xx = YY * cos(alpha);
        yy = -XX;
        zz = d/cos(alpha) - YY*sin(alpha);

        Dist = sqrt(xx.^2 + yy.^2 + zz.^2);
        twoTheta = acos(zz ./ Dist);
%        Phi=180*atan(yy./xx)/pi;
end
    