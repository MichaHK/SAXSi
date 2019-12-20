function [calibration] = CalibrationFromConic(conic, twoTheta, initialParams)

N = 300;

% Sample the conic's points
%conic = ConicClass; % for debug
t = linspace(0, 2 * pi, N + 1);
t(end) = [];
[x, y] = conic.GetPointsFromParametricForm(t);

if (nargin < 3)
    calibration = CalibrationFromPoints(x, y, twoTheta);
else
    calibration = CalibrationFromPoints(x, y, twoTheta, initialParams);
end

end
