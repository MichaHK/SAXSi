function [profile] = GetCentralProfile(image, angle, radii, interpolationType)
% [profile] = GetCentralProfile(image, angle, radii, interpolationType)

center = size(image) * 0.5;

if (nargin == 4)
    profile = interp2(image, radii * cos(angle) + center(2), radii * sin(angle) + center(1), interpolationType);
else
    profile = interp2(image, radii * cos(angle) + center(2), radii * sin(angle) + center(1));
end
end
