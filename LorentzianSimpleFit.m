function [fitResult, gof, relativeCoeffErr] = LorentzianSimpleFit(x, y)

[yMax, yMaxIndex] = max(y);
ySortedIntensities = sort(y);
yBackground = ySortedIntensities(fix(end * 0.05));

startPoint = [(yMax-yBackground) x(yMaxIndex) 1 0 yBackground];
[fitResult, gof] = fit(x(:), y(:), 'a/((x-b)^2+c^2)/pi + d*x + e', 'StartPoint', startPoint); % Lorentzian + linear func

confidenceIntervals = confint(fitResult);
confidenceRange = abs(diff(confidenceIntervals, 1, 1)); % The "abs" is just in case
relativeCoeffErr = confidenceRange ./ (abs(coeffvalues(fitResult)) + eps);

end
