function [fitResult, gof, relativeCoeffErr] = GaussianSimpleFit(x, y)

[yMax, yMaxIndex] = max(y);
ySortedIntensities = sort(y);
yBackground = ySortedIntensities(fix(end * 0.05));

expression = 'a*exp(-((x-b)/(c*2))^2) + d*x + e'; % Gaussian + linear func
startPoint = [(yMax-yBackground) x(yMaxIndex) 1 0 yBackground];
[fitResult, gof] = fit(x(:), y(:), expression, 'StartPoint', startPoint);

confidenceIntervals = confint(fitResult);
confidenceRange = abs(diff(confidenceIntervals, 1, 1)); % The "abs" is just in case
relativeCoeffErr = confidenceRange ./ (abs(coeffvalues(fitResult)) + eps);

end
