function [type, numericType, d, M33, M12] = QuadraticFormGetConicType(obj)
% Returns one of:
%
%

[d, M33, M12] = obj.GetConicDeterminant();

if (d == 0) % Degenerate
    numericType = 0;
    
    if (M33 > obj.EffectiveZero)
        type = 'point';
    elseif (M33 < -obj.EffectiveZero)
        if (obj.QuadraticForm(1) + obj.QuadraticForm(3) == 0)
            type = 'two perpendicular lines';
        else
            type = 'two intersecting lines';
        end
    else
        if (M12 == 0)
            type = 'single line';
        else
            type = 'two parallel lines';
        end
    end
else % Ellipse, Circle, Parabola, Hyperbola
    if (M33 > obj.EffectiveZero)
        if (obj.QuadraticForm(1) * d > 0) % no solution
            type = 'invalid';
        else
            if (obj.QuadraticForm(1) == obj.QuadraticForm(3) &&...
                    obj.QuadraticForm(2) == 0)
                type = 'circle';
                numericType = 1;
            else
                type = 'ellipse';
                numericType = 2;
            end
        end
    elseif (M33 < -obj.EffectiveZero)
        type = 'hyperbola';
        numericType = 3;
    else
        type = 'parabola';
        numericType = 4;
    end
end
end
