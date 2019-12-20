function [qf, shift, angle, rotMatrix, eccentricity, foci, semiLatusRectum] = ...
    QuadraticFormStandardizeConic(obj)
% [qf, shift, angle, rotMatrix, eccentricity, foci, semiLatusRectum] = QuadraticFormStandardizeConic(qf)

qf = obj.QuadraticForm;

foci = [];
eccentricity = 0;
semiLatusRectum = 0;

[alignedQF, shift, angle, rotMatrix, eccentricity, foci, semiLatusRectum] = ...
    QuadraticFormStandardizeConicMethod1(obj);

% Calculate center in the original coordinates
center = (rotMatrix * shift')';

shift = center;
qf = QuadraticFormTranslation(qf, -center);

A = qf(1); B = qf(2); C = qf(3); D = qf(4); E = qf(5); F = qf(6);

% Calculate turn back angle
if (A == C)
    angle = pi() * 0.25;
else
    angle = 0.5 * atan(B / (A - C));
end

[qf, rotMatrix, inverseRotMatrix] = QuadraticFormRotation(qf, angle);
angle = -angle;

% Just in case it's not EXACTLY zero after the transformations
qf(2) = 0;
qf(4) = 0;
qf(5) = 0;

end