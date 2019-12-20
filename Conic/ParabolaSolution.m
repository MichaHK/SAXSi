function [x] = ParabolaSolution(p)

x = [];
d = p(2)^2 - 4*p(3)*p(1);
if (d > 0)
    x(1) = (-p(2) + sqrt(d)) / (2*p(3));
    x(2) = (-p(2) - sqrt(d)) / (2*p(3));
elseif (d == 0)
    x(1) = (-p(2)) / (2*p(3));
end

end
