function [rgb, I] = Matrix2Image(m, limLow, limHigh, map)
% Ram Avinery - writes a matrix as an image, similar to the displayed image
% using "iamgesc"
%
% WriteMatrixAsImage(m, filename[, map, limLow, limHigh])

if (nargin < 3)
    limHigh = max(m(:));
end

if (nargin < 2)
    limLow = min(m(:));
end

if (nargin < 4)
    map = jet(256);
end

m(m > limHigh) = limHigh;
m(m < limLow) = limLow;

m = (m - limLow) / (limHigh - limLow);

%[I, ~] = gray2ind(m, size(map, 1));
I = floor(m * (size(map, 1)-1) + 1);
rgb = ind2rgb(I, map);

end
