function [diff] = AngleDiff(x, y)

twoPi = 2*pi;

diff = mod(x - y, twoPi);

which = (diff > pi);
diff(which) = diff(which) - (twoPi);

end
