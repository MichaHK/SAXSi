function [result] = SumImageAtCircle(image, validityMap, circleCenter, circleRadius, approxStep)

values = SampleImageAtCircle(image, validityMap, circleCenter, circleRadius, approxStep);
result = sum(values(:));
1;

end
