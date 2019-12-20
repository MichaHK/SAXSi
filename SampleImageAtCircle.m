function [values, X, Y, whichIncluded] = SampleImageAtCircle(image, validityMap, circleCenter, circleRadius, approxStep, shouldOutputFullMatrices)

persistent radius;
persistent step;

if (~exist('shouldOutputFullMatrices', 'var') || isempty(shouldOutputFullMatrices))
    shouldOutputFullMatrices = 0;
end

if (isempty(radius) || isempty(step) || (radius ~= circleRadius) || (step ~= approxStep))
    radius = circleRadius;
    step = approxStep;
end

numberOfPoints = round(2 * radius / step);
points = linspace(-radius, radius, numberOfPoints);
[X, Y] = meshgrid(points, points);
which = (X.^2 + Y.^2) <= (radius^2);

imageXValues = 1:size(image, 2);
imageYValues = 1:size(image, 1);

X = circleCenter(1) + X;
Y = circleCenter(2) + Y;
values = interp2(imageXValues, imageYValues, image, X, Y);

if (~isempty(validityMap))
    validityValues = interp2(imageXValues, imageYValues, validityMap, X, Y);
    which = which & (validityValues == 1);
end

%values(~which) = 0;

whichIncluded = which;
if (shouldOutputFullMatrices)
else
    values = values(which);
    X = X(which);
    Y = Y(which);
end


end
