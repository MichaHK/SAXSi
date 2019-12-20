function [avgValue, avgValueErr,numOfPoints] = AverageOnQConic(image, ...
    lambda, alpha, beta, d, Xd, Yd, q)

%tic

imageSize=size(image);

% L = CalibrationData.SampleToDetDist;
% pixsize = CalibrationData.PixelSize;
% lambda = CalibrationData.Lambda;
% alpha = CalibrationData.AlphaRadians;
% beta = CalibrationData.BetaRadians;
% 
% d=L/pixsize;
% Xd = CalibrationData.BeamCenterX;
% Yd = CalibrationData.BeamCenterY;

twoK = (4 * pi) / lambda;
theta = asin(q / twoK);
conic = ConicClass();
conic.SetConexParameters(alpha, d, Xd, Yd, beta, theta * 2.0);

numOfPoints = 0;
prevValue = 0;
avgValue = 0;
avgValueErr = 0;

initialPointsCount = 100;

for pointsCountExponent = 1:8
    [segments, segmentsSum] = conic.GetSegmentsWithinRect([1,1,imageSize(2)-1,imageSize(1)-1]);
    segmentsLengths = diff(segments, 1, 2);
    
    numOfPoints = (2^pointsCountExponent) * initialPointsCount;
    
    unitedValues = [];
    
    if (size(segments, 1) > 1)
        1;
    end
    
    for segIdx = 1:size(segments, 1)
        portion = segmentsLengths(segIdx) / segmentsSum;
        [x, y] = conic.GetPointsFromParametricForm(...
            linspace(segments(segIdx, 1), segments(segIdx, 2), ...
            floor(portion * numOfPoints)));
        
        % TODO: To avoid NaN values, expand the image to [0..W+1] x [0..H+1]
        
        values = interp2(image, x, y);
        unitedValues = [unitedValues values(~isnan(values))];
    end
    
    avgValue = mean(unitedValues);
    avgValueErr = std(unitedValues);
    
    change = abs(avgValue - prevValue) / abs(prevValue);
    %display(change);
    
    if (isnan(change))
        1;
    end
    
    if (change < 1e-3)
        break;
    end
    
    prevValue = avgValue;
end

%toc

end
