function [qf] = QuadraticFormFlipX(qf)
% [qf] = QuadraticFormFlipX(qf)

which = [2, 4]; % B, D
qf(which) = -qf(which);

end
