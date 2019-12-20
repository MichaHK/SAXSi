function [qvec, Ivec] = IntegrateAccurate(...
    image, maskIn, CalibrationData, IntegrationParams, method)
% IntegrateAccurate(image, maskIn, CalibrationData, IntegrationParams)

addpath('Integration');

tStarted = tic;
tLastNotification = 0;

L = CalibrationData.SampleToDetDist;
pixsize = CalibrationData.PixelSize;
lambda = CalibrationData.Lambda;
twoK = (4 * pi) / lambda;
alpha = CalibrationData.AlphaRadians;
beta = CalibrationData.BetaRadians;
d=L/pixsize;
Xd = CalibrationData.BeamCenterX;
Yd = CalibrationData.BeamCenterY;


imageSize=size(image);
maskIn = (maskIn ~= 0); % Accept only binary values
image = double(image);
image(maskIn) = 0; % Zero masked values

binsizeInt = IntegrationParams.QStepsCount;
qmin = IntegrationParams.QMin;
qmax = IntegrationParams.QMax;
doxhi = IntegrationParams.shouldDoXhi;

difq = (qmax-qmin)/binsizeInt;
qvec = qmin:difq:qmax;
Ivec = qvec .* 0;

for i = 1:numel(qvec)
    if (method == 3)
        [Ivec(i), avgValueErr, numOfQPoints] = AverageOnQConic(image, lambda, alpha, beta, d, Xd, Yd, qvec(i));
    elseif (method == 2)
        Ivec(i) = AverageOnQRangeLagrange(image, double(~maskIn), CalibrationData, qvec(i) - difq / 2, qvec(i) + difq / 2);
    elseif (method == 1)
        [Ivec(i), avgValueErr, numOfQPoints] = AverageOnQRange(image, CalibrationData, qvec(i) - difq / 2, qvec(i) + difq / 2);
    else
    end
    
    tElapsed = toc(tStarted);
    
    if ((tElapsed - tLastNotification) >= 1)
        display(sprintf('%0.1f seconds have elapsed, I''m in bin %i/%i...', tElapsed, i, numel(qvec)));
        tLastNotification = tElapsed;
    end
end

toc(tStarted);

end
