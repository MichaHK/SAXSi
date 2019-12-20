function [avgValue, avgValueErr, numOfQPoints] = AverageOnQRange(image, CalibrationData, qMin, qMax)

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

while (change > 1e-3 && numOfQPoints <= 128)
    numOfQPoints = numOfQPoints * 2;
    
    points = linspace(qMin, qMax, numOfQPoints + 1);
    points(1) = [];
    
    values = zeros(size(points));
    valuesErr = zeros(size(points));
    
    for qIdx =1:numel( points)
        q = points(qIdx);
        [values(qIdx), valuesErr(qIdx)] = AverageOnQConic(image, lambda, alpha, beta, d, Xd, Yd, q);
    end
    
    avgValue = mean(values);
    avgValueErr = mean(valuesErr);

    change = abs(avgValue - prevValue) / abs(prevValue);
    prevValue = avgValue;
end

end
