function [a,b,y0] = GeometryToEllipseParameters(alpha, theta)

% Code taken from the CONEX program code, with permission.
% C. J. Gommes and B. Goderis, ConeX: A program for angular calibration and averaging of 2D powder scattering patterns, Journal of Applied Crystallography 43 (2010), no. 2, 352-355

tanAlpha = tan(alpha);
tanThMinsAlDiv2 = tan((theta - alpha) / 2);
tanThPlusAlDiv2 = tan((alpha + theta) / 2);
cosAlpha = cos(alpha);
sinTheta = sin(theta);

fp = tanAlpha .*  sinTheta ./  (cosAlpha + sinTheta);
fm = tanAlpha .*  sinTheta ./  (cosAlpha - sinTheta);

vp = (tanAlpha + (1 + tanThMinsAlDiv2) ./  (1 - tanThMinsAlDiv2)) .*  sinTheta ./  (cosAlpha + sinTheta);
vm = (tanAlpha + (1 - tanThPlusAlDiv2) ./  (1 + tanThPlusAlDiv2)) .*  sinTheta ./  (cosAlpha - sinTheta);

a = 0.5 * (vp + vm);
b = 0.5 * sqrt((vp + vm).^2 - (fp + fm).^2);
y0 = 0.5 * (fp - fm);

end
