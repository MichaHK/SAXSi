function [cropped, xInCropped, yInCropped] = CropImageAround(image, x, y, radius)
% [cropped] = CropImageAround(image, x, y, radius)

limits = [floor(x-radius),ceil(x+radius);floor(y-radius),ceil(y+radius)];
%cropped = image([floor(y-radius):ceil(y+radius)], [floor(x-radius):ceil(x+radius)]);
cropped = image([limits(2,1):limits(2,2)], [limits(1,1):limits(1,2)]);
xInCropped = x - limits(1, 1);
yInCropped = y - limits(2, 1);
end
