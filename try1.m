

figure(9); plot(q, I ./ (q.^-3.7), '-k')

Lorentzian1 = @(x, xc, A, w)((A * w^2) ./ ((x - xc).^2 + w^2));
Lorentzian2 = @(x, xc, A, w)(A ./ (1 + ((x - xc) ./ w) .^ 2));

Qc = 0.1075;
A = 6.3e-3;
w = 0.0033;

hold on;
plot(q, Lorentzian1(q, Qc, A, w), '.g');
%plot(q, Lorentzian2(q, Qc, A, w), '--b');
hold off;


