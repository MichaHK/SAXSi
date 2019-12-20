function [qf, correspondingRotationMatrix, inverseRotationMatrix] = QuadraticFormRotation(qf, angle)
% [qf, correspondingRotationMatrix, inverseRotationMatrix] = QuadraticFormRotation(qf, angle)

A = qf(1); B = qf(2); C = qf(3); D = qf(4); E = qf(5); F = qf(6);

% Convert to rotated quadratic form ...

u = cos(angle);
v = sin(angle);

Ar = A*u*u + B*u*v + C*v*v;
Cr = C*u*u - B*u*v + A*v*v;
Br = B*(u*u - v*v) - 2*A*u*v + 2*C*u*v;
Dr = D*u + E*v;
Er = E*u - D*v;
Fr = F;

qf = [Ar, Br, Cr, Dr, Er, Fr];

if (nargout >= 1)
    correspondingRotationMatrix = [u -v; v u];
end

if (nargout >= 2)
    u = cos(-angle);
    v = sin(-angle);
    inverseRotationMatrix = [u -v; v u];
end

end
