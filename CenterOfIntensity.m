function [x, y] = CenterOfIntensity(image)

[meshX, meshY] = meshgrid(1:size(image, 2), 1:size(image, 1));

imageSum = sum(image(:));
image = image / imageSum;
meshX = meshX .* image;
meshY = meshY .* image;

x = sum(meshX(:));
y = sum(meshY(:));

end
