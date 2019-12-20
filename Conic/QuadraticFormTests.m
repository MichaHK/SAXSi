
% [-14, 1, -0.1, 1, -58, 1];
%qf = [-14, 1, -0.1, 1, -58, 1];

qf = [1, 0, 4, 0, 0, -1];
c = ConicClass;
qf = QuadraticFormRotation(qf, 0.01);
qf = QuadraticFormTranslation(qf, [1, 2]);

c.SetQuadraticForm(qf);
%[qf, shift, angle, rotMatrix, eccentricity, foci, semiLatusRectum] = QuadraticFormStandardizeConic(qf);
1;



