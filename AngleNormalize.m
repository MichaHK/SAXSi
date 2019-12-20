function [result] = AngleNormalize(a, flag)
% AngleNormalize(a, 0) -> Normalize to the range -pi..pi
% AngleNormalize(a, 1) -> Normalize to the range 0..2*pi
% AngleNormalize(a) -> AngleNormalize(a, 0)

if (nargin < 2)
    flag = 0;
end

twoPi = 2*pi;

result = mod(a, twoPi); % This is now in the range 0..2*pi

if (~flag) % flag == 0
    which = (result > pi);
    result(which) = result(which) - (twoPi);
end

end
