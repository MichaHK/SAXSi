function [avgValue, avgValueErr] = AverageOnQRangeLagrange(image, validPixelsMap, CalibrationData, qMin, qMax)

L = CalibrationData.SampleToDetDist;
pixsize = CalibrationData.PixelSize;
lambda = CalibrationData.Lambda;
twoK = (4 * pi) / lambda;
alpha = CalibrationData.AlphaRadians;
beta = CalibrationData.BetaRadians;

d=L/pixsize;
Xd = CalibrationData.BeamCenterX;
Yd = CalibrationData.BeamCenterY;

numOfQPoints = 8 / 2;
change = inf;
prevValue = 0;

avgValueErr = 0;

while (change > 1e-3)
    numOfQPoints = numOfQPoints * 2;
    
    AverageOnImage = @(q)AverageOnQConic(image, lambda, alpha, beta, d, Xd, Yd, q);
    AverageOnValidityMap = @(q)AverageOnQConic(validPixelsMap, lambda, alpha, beta, d, Xd, Yd, q);
    
    avgValue = GaussLegendreIntegration(@(q)arrayfun(AverageOnImage, q), qMin, qMax, numOfQPoints) / ...
        GaussLegendreIntegration(@(q)arrayfun(AverageOnValidityMap, q), qMin, qMax, numOfQPoints);
    
    change = abs(avgValue - prevValue) / abs(prevValue);
    prevValue = avgValue;
end

end
