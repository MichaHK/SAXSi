

Dm = 3;
r0 = 10;
xi = 50;


q = linspace(0.004, 3, 3000);

s = 1 + ((q .* r0) .^ -Dm) .* (Dm .* gamma(Dm-1)) .* ((1 + (q .* xi).^-2) .^ ((1-Dm)/2)) .* sin((Dm-1) .* atan(q .* xi));

figure(1);
loglog(q, s)