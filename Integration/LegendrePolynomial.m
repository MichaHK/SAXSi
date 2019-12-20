function p = LegendrePolynomial(N) %Legendre polynomial
if N <= 0, p = 1; %n*Ln(t) = (2n - 1)t Ln - 1(t)-(n - 1)Ln-2(t) Eq.(5.9.6b)
elseif N == 1, p = [1 0];
else p = ((2*N - 1)*[LegendrePolynomial(N - 1) 0]-(N - 1)*[0 0 LegendrePolynomial(N - 2)])/N;
end
