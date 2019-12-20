function [qf] = QuadraticFormFlipY(qf)
% [qf] = QuadraticFormFlipY(qf)

which = [2, 5]; % B, E
qf(which) = -qf(which);

end
