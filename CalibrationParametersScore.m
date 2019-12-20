function [score] = CalibrationParametersScore(image, mask, q, lambda, beamCenterX, beamCenterY, sampleToDetDist, alpha, beta, A)

width = 0.033;
threeWidth = width * 3;
inverseWidth = 1.0 / width;

twoK = (4 * pi) / lambda;
twoTheta = 2 * asin(q / twoK);
Lorentzian = @(x, xc, A, w)((A * w^2) ./ ((x - xc).^2 + w^2));

[Xd,Yd]=find_Direct_Beam_conX(...
    beamCenterX,...
    beamCenterY, beta);

%%%%%% calculate matries %%%%%%%
N = size(image, 2);
M = size(image, 1);
[xx,yy]=meshgrid(1:N,1:M);

XX=Xd+xx*cos(beta)-yy*sin(beta);
YY=Yd-xx*sin(beta)-yy*cos(beta);

clear xx; clear yy;

xx=YY*cos(alpha);
yy=-XX;
zz=sampleToDetDist/cos(alpha)-YY*sin(alpha);

Dist = sqrt(xx.^2+yy.^2+zz.^2);
imageToQMatrix = (twoK * sin(0.5.*acos(zz./Dist)));
weightMatrix = zeros(size(imageToQMatrix));
which = mask & (abs(imageToQMatrix - q) < threeWidth);

comparedImage = Lorentzian(imageToQMatrix, q, 1, 0.033);

diffImage = image - (A .* comparedImage);
if (0)
    figure(2); imagesc(diffImage .* which);
end

if (0)
    weights = log(comparedImage * 1e3);
    weights(weights < 0) = 0;
    
    score = sum((diffImage(which) .^ 2) .* weights(which)) / sum(weights(which));
else
    score = mean((diffImage(which) .^ 2));
end

%score = -mean(image(which) .* comparedImage(which));
end
