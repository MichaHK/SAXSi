function [qf] = QuadraticFormTranslation(qf, translation)
% [qf] = QuadraticFormTranslation(qf, translation)

X0 = translation(1);
Y0 = translation(2);

A = qf(1); B = qf(2); C = qf(3); D = qf(4); E = qf(5); F = qf(6);

qf(4) = D - 2*A*X0 - B*Y0;
qf(5) = E - 2*C*Y0 - B*X0;
qf(6) = F + A*X0*X0 + C*Y0*Y0 ...
    - D*X0 - E*Y0 ...
    + B*X0*Y0;
end
