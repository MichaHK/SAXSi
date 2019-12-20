function [result] = AngleAdd(x, y)

twoPi = 2*pi;

result = mod(x + y, twoPi);

which = (result > pi);
result(which) = result(which) - (twoPi);

end
