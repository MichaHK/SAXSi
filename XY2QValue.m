function [q, theta] = XY2QValue(x, y, CalibrationData)

fourPiOverLambda = 12.56637061435917 / CalibrationData.Lambda;

alpha = CalibrationData.AlphaRadians;
% Convert to "pixel units"
d = CalibrationData.SampleToDetDist / CalibrationData.PixelSize;
beta = CalibrationData.BetaRadians;

[Xd,Yd]=find_Direct_Beam_conX(...
    CalibrationData.BeamCenterX,...
    CalibrationData.BeamCenterY, beta);

XX = Xd + x*cos(beta) - y*sin(beta);
YY = Yd - x*sin(beta) - y*cos(beta);

xx = YY*cos(alpha);
yy = -XX;
zz = d/cos(alpha) - YY*sin(alpha);

Dist = sqrt(xx.^2 + yy.^2 + zz.^2);
theta = acos(zz./Dist);
q = fourPiOverLambda * sin(0.5 .* theta);


end
