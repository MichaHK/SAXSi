function [a,b,y0] = GeometryToHyperbolaParameters(alpha,theta)

% Code taken from the CONEX program code, with permission.
% C. J. Gommes and B. Goderis, ConeX: A program for angular calibration and averaging of 2D powder scattering patterns, Journal of Applied Crystallography 43 (2010), no. 2, 352-355

tanAlpha = tan(alpha);
tanDiff = tan(theta-alpha);

cosAlpha = cos(alpha);
sinAlpha = sin(alpha);
sinTheta = sin(theta);

f = tanAlpha .* sinTheta ./ (cosAlpha+sinTheta); % Focus
v = (tanAlpha + tanDiff); % Vertex
d = sinTheta .* (1 + sinTheta .* cosAlpha) ./ ((sinTheta + cosAlpha) .* cosAlpha .* sinAlpha); 

e = (v-f) ./ (d-v);

a = e .* (d-f) ./ (e.^2-1);
b = e .* (d-f) ./ (e.^2-1) .^ 0.5;
y0 = f + a .* e;

end
