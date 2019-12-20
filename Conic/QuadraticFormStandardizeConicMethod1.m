function [qf, shift, angle, rotMatrix, eccentricity, foci, semiLatusRectum] = ...
    QuadraticFormStandardizeConicMethod1(obj)

qf = obj.QuadraticForm;
A = qf(1); B = qf(2); C = qf(3); D = qf(4); E = qf(5); F = qf(6);

foci = [];
eccentricity = 0;
semiLatusRectum = 0;

% Calculate the angle to turn back!
if (A == C)
    angle = pi() * 0.25;
else
    angle = 0.5 * atan(B / (A - C));
end

[qf, rotMatrix] = QuadraticFormRotation(qf, angle);
qf(2) = 0; % Just in case (might be numerically almost zero instead of actual zero)

Ar = qf(1); Br = qf(2); Cr = qf(3); Dr = qf(4); Er = qf(5); Fr = qf(6);
quadformBeforeShift = qf;
qf(4) = 0;
qf(5) = 0;

[~, type] = obj.GetConicType();

if (type == 1 || type == 2) % Circle, Ellipse
    
    Xo = -Dr / (2*Ar);
    Yo = -Er / (2*Cr);
    shift = [Xo, Yo];
    
    qf(1) = Ar / (Ar*Xo*Xo + Cr*Yo*Yo - Fr);
    qf(3) = Cr / (Ar*Xo*Xo + Cr*Yo*Yo - Fr);
    qf(6) = -1.0;
    
    if (type == 1)
        eccentricity = 0;
    end
    
    if (abs(qf(1)) < abs(qf(3))) % foci on x-axis for ellipse
        a2 = abs(1 / qf(1));
        b2 = abs(1 / qf(3));
        
        if (type == 2) % ellipse
            C = sqrt(a2 - b2);
            foci = [C, 0; -C, 0];
            eccentricity = C / sqrt(a2);
        end
    else % foci on y-axis for ellipse
        a2 = abs(1 / qf(3));
        b2 = abs(1 / qf(1));
        
        if (type == 2) % ellipse
            C = sqrt(a2 - b2);
            foci = [0, C; 0, -C];
            eccentricity = C / sqrt(a2);
        end
    end
    
    semiLatusRectum = b2 / sqrt(a2);
    
elseif (type == 3) % Hyperbola
    
    % circle, ellipse, or hyperbola
    Xo = -Dr / (2*Ar);
    Yo = -Er / (2*Cr);
    
    qf(1) = Ar / (Ar*Xo*Xo + Cr*Yo*Yo - Fr);
    qf(3) = Cr / (Ar*Xo*Xo + Cr*Yo*Yo - Fr);
    qf(6) = -1.0;
    
    if (qf(1) > qf(3)) % foci on x-axis
        a2 = abs(1 / qf(1));
        b2 = abs(1 / qf(3));
        
        C = sqrt( a2 + b2 );
        foci = [C 0; -C 0];
        eccentricity = C / sqrt(a2);
    else % foci on y-axis
        a2 = abs(1 / qf(3));
        b2 = abs(1 / qf(1));
        C = sqrt( a2 + b2 );
        foci = [0 C; 0 -C];
        eccentricity = C / sqrt(a2);
    end
    
    semiLatusRectum = b2 / sqrt(a2);
    shift = [Xo, Yo];
    
else %if (type == 4) % Parabola
    
    if (abs(Ar) > abs(Cr)) % form: x² - 4·p·y = 0
        Xo = Dr/(2*Ar);
        Yo = (Fr - Dr*Dr/(4*Ar))/Er;
        
        qf(1) = 1;
        qf(5) = Er / Ar;
        p = -qf(5) / 4;
        foci = [0, p];
        
    else % form: y² - 4·p·x = 0
        Xo = (Fr - Er*Er/(4*Cr))/Dr;
        Yo = Er/(2*Cr);
        
        qf(3) = 1;
        qf(4) = Dr / Cr;
        p = -qf(4) / 4;
        foci = [p, 0];
    end
    
    semiLatusRectum = p;
    shift = [Xo, Yo];
    eccentricity = 1; % for all parabolas
end
end
