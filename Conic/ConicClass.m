classdef ConicClass < handle
    properties(Access=private)
        quadraticForm = zeros(1, 6);
    end
    
    properties(SetAccess=private)
        Eccentricity
        Foci
        QuadraticForm
        Translation
        AlignedQuadraticForm
        RotationMatrix
        RotationAngle
        SemiLatusRectum
    end
    
    properties(Access=public)
        EffectiveZero = 0;%1e-16;
    end
    
    properties(Dependent=true)
        
    end
    
    methods (Access=public)
        
        function c = ConicClass(qf)
            if (nargin == 1)
                c.SetQuadraticForm(qf);
            end
        end
        
        function [] = DebugPlot(obj, t)
            %[x, y] = obj.GetPointsFromPolarForm(linspace(0, 2 * pi(), 1000));
            
            if (nargin < 2)
                t = linspace(0, 2 * pi(), 1000);
            end
            
            [x, y] = obj.GetPointsFromParametricForm(t);
            figure;
            plot(x,y);
            axis equal;
        end
        
        function [] = DebugPlotUsingRandomSolutions(obj)
            
            N = 1000;
            points = [];
            qf = obj.QuadraticForm;
            xmin = -20; xmax = 20;
            ymin = -20; ymax = 20;
            
            x = xmin + (xmax-xmin) .* rand(N, 1);
            for i = 1:numel(x)
                p = [qf(1)*(x(i)^2) + qf(4)*x(i) + qf(6), qf(5) + qf(2)*x(i), qf(3)];
                y = ParabolaSolution(p);
                
                if (numel(y) == 1)
                    points(end+1, :) = [x(i), y];
                elseif (numel(y) == 2)
                    points(end+1:end+2, :) = [[x(i);x(i)], y(:)];
                end
                
                %p = [qf(3)*(y^2) + qf(5)*y + qf(6), qf(4) + qf(2)*y, qf(1)];
            end
            
            y = ymin + (ymax-ymin) .* rand(N, 1);
            for i = 1:numel(y)
                p = [qf(3)*(y(i)^2) + qf(5)*y(i) + qf(6), qf(4) + qf(2)*y(i), qf(1)];
                x = ParabolaSolution(p);
                
                if (numel(x) == 1)
                    points(end+1, :) = [x, y(i)];
                elseif (numel(x) == 2)
                    points(end+1:end+2, :) = [x(:), [y(i);y(i)]];
                end
            end

            plot(points(:, 1), points(:, 2), '*k');
            axis equal;
        end
        
        function [] = DebugPlot2(obj)
            %[x, y] = obj.GetPointsFromPolarForm(linspace(0, 2 * pi(), 1000));
            [x, y] = obj.GetPointsFromParametricForm(linspace(0, 2 * pi(), 1000));
            
            hold on;
            plot(x,y, '-k');
            %axis equal;
            hold off;
        end
        
        function [x, y, thetas] = GetPointsInParametricFormWithinInRect(obj, rect, N)
            
            [segments] = obj.GetSegmentsWithinRect(rect);
            segmentPortions = diff(segments, 1, 2);
            segmentPortions = segmentPortions ./ sum(segmentPortions);
            
            x = [];
            y = [];
            thetas = [];
            
            if (size(segments, 1) == 1 && abs(segments(1)) <= 1e-5 && abs(segments(2) - 2*pi) < 1e-5)
                    thetas = linspace(segments(1), segments(2), round(N)+1);
                    thetas(end) = [];
                    [x, y] = obj.GetPointsFromParametricForm(thetas);
                    thetas = thetas(:);
                    x = x(:);
                    y = y(:);
            else
                for seg = 1:size(segments, 1)
                    portion = segmentPortions(seg);
                    
                    tmpThetas = linspace(segments(seg, 1), segments(seg, 2), round(N * portion));
                    [tmpX, tmpY] = obj.GetPointsFromParametricForm(tmpThetas);
                    
                    x = [x; tmpX(:)];
                    y = [y; tmpY(:)];
                    thetas = [thetas; tmpThetas(:)];
                end
            end
            
            if (nargout == 1)
                x = [x, y, thetas];
            end
        end
        
        function [segmentsAndPoints] = GetSegmentsAndPointsWithinRect(obj, rect, dThetaDegrees)
            % [segmentsAndPoints] = obj.GetSegmentsAndPointsWithinRect(rect, dThetaDegrees)
            
            dTheta = deg2rad(dThetaDegrees);
            
            segmentsAndPoints = [];
            
            [segments] = obj.GetSegmentsWithinRect(rect);
            segmentPortions = diff(segments, 1, 2);
            segmentPortions = segmentPortions ./ sum(segmentPortions);
            
            % Is it one segment that effectively is entirely within the
            % rectangle? If so, the first and last point are the same (2*pi equals 0)
            if (size(segments, 1) == 1 && abs(segments(1)) <= 1e-5 && abs(segments(2) - 2*pi) < 1e-5)
                    N = ceil(diff(segments)/dTheta);
                    thetas = linspace(segments(1), segments(2), N+1);
                    thetas(end) = []; % remove the redundant last point
                    [x, y] = obj.GetPointsFromParametricForm(thetas);
                    segmentsAndPoints(end+1).SegmentBoundaries = segments;
                    segmentsAndPoints(end).N = N;
                    segmentsAndPoints(end).Thetas = thetas(:);
                    segmentsAndPoints(end).X = x(:);
                    segmentsAndPoints(end).Y = y(:);
            else % End points of the segments are not going to be the same
                for seg = 1:size(segments, 1)
                    N = ceil(diff(segments(seg, :))/dTheta);
                    thetas = linspace(segments(seg, 1), segments(seg, 2), N);
                    [x, y] = obj.GetPointsFromParametricForm(thetas);
                    
                    segmentsAndPoints(end+1).SegmentBoundaries = segments(seg, :);
                    segmentsAndPoints(end).N = N;
                    segmentsAndPoints(end).Thetas = thetas(:);
                    segmentsAndPoints(end).X = x(:);
                    segmentsAndPoints(end).Y = y(:);
                end
            end
        end
        
        function [] = DebugPlotInRect(obj, rect, color)
            % obj.DebugPlotInRect();
            
            if (nargin < 3)
                color = 'Red';
            end
            
            [segments] = obj.GetSegmentsWithinRect(rect);
            segmentPortions = diff(segments, 1, 2);
            segmentPortions = segmentPortions ./ sum(segmentPortions);
            
            hold on;
            for seg = 1:size(segments, 1)
                portion = segmentPortions(seg);
                [x,y] = obj.GetPointsFromParametricForm(...
                    linspace(segments(seg, 1), segments(seg, 2), floor(1e3 * portion)));
                plot(x, y, '-', 'LineWidth', 2, 'Color', color);
            end
            
            axis equal;
            hold off;
        end
        
        function SetSolutionOf5Points(obj, x, y)
            if (nargin < 2), error('Not enough paramters!'); end
            if (nargin == 2)
                if (size(x, 1) == 2)
                    y = x(2, :); x = x(1, :);
                else
                    y = x(:, 2); x = x(:, 1);
                end
            else
                x = x(:); y = y(:);
            end
            
            m = [x .^ 2, x .* y, y .^ 2, x, y];
            qf = linsolve(m, ones(5, 1));
            qf = [qf(:)', -1];
            obj.SetQuadraticForm(qf);
        end
        
        function [f] = IsValidForParametricForm(obj)
            [~, type] = obj.GetConicType();
            f = (type == 1 || type == 2 || type == 3);
        end
        
        function [t] = GetParameterFromPoint(obj, x, y)
            
            [~, type] = obj.GetConicType();
            
            x = x - obj.Translation(1);
            y = y - obj.Translation(2);
            
            xy = obj.RotationMatrix' * [x(:), y(:)]';
            
            if (type == 1 || type == 2)
                a = (obj.AlignedQuadraticForm(1) / -obj.AlignedQuadraticForm(6))^-0.5;
                b = (obj.AlignedQuadraticForm(3) / -obj.AlignedQuadraticForm(6))^-0.5;
                %xy = [a .* cos(thetas); b .* sin(thetas)];
                t = atan2(xy(2, :) / b, xy(1, :) / a);
            elseif (type == 3)
                qf = obj.AlignedQuadraticForm;
                qf = qf / -qf(6);
                
                if (qf(3) < 0)
                    a = qf(1)^-0.5;
                    b = (-qf(3))^-0.5;
                    %xy = [a .* sec(thetas); b .* tan(thetas)];
                    t = atan2((xy(2, :) ./ b) ./ (xy(1, :) ./ a), a ./ xy(1, :));
                else
                    a = (-qf(1))^-0.5;
                    b = qf(3)^-0.5;
                    %xy = [a .* tan(thetas); b .* sec(thetas)];
                    t = atan2((xy(1, :) ./ a) ./ (xy(2, :) ./ b), b ./ xy(2, :));
                end
                
                [dbgX, dbgY] = obj.GetPointsFromParametricForm(t);
                % debug
                %display([dbgX - x', dbgY - y']);
                1;
            else
                error('Unhandled conic type!');
            end
            
        end
        
        function [dl, dx, dy] = GetWalkDeriv(obj, thetas)
            [dx, dy] = obj.GetDerivativeFromParametricForm(thetas);
            dl = sqrt(dx .^ 2 + dy .^ 2);
        end
        
        function [x, y] = GetDerivativeFromParametricForm(obj, thetas)
            % [x,y] = obj.GetPointsFromParametricForm(thetas)
            thetas = thetas(:);
            
            [~, type] = obj.GetConicType();
            
            if (type == 1 || type == 2)
                a = (obj.AlignedQuadraticForm(1) / -obj.AlignedQuadraticForm(6))^-0.5;
                b = (obj.AlignedQuadraticForm(3) / -obj.AlignedQuadraticForm(6))^-0.5;
                xy = [a .* sin(thetas), -b .* cos(thetas)];
            elseif (type == 3)
                qf = obj.AlignedQuadraticForm;
                qf = qf / -qf(6);
                
                if (qf(3) < 0)
                    a = qf(1)^-0.5;
                    b = (-qf(3))^-0.5;
                    %xy = [a .* sec(thetas); b .* tan(thetas)];
                    s = sec(thetas);
                    xy = [a .* s .* tan(thetas), b .* (s.^2)];
                else
                    a = (-qf(1))^-0.5;
                    b = qf(3)^-0.5;
                    % xy = [a .* tan(thetas); b .* sec(thetas)];
                    s = sec(thetas);
                    xy = [a .* (s.^2), b .* s .* tan(thetas)];
                end
            else
                error('Unhandled conic type!');
                xy = [];
            end
            
            xy = (obj.RotationMatrix * xy')';
            
            if (nargout == 1)
                x = xy;
            else
                x = xy(:, 1);
                y = xy(:, 2);
            end
        end
        
        function [x,y] = GetPointsFromParametricForm(obj, thetas)
            % [x,y] = obj.GetPointsFromParametricForm(thetas)
            
            [~, type] = obj.GetConicType();
            
            if (type == 1 || type == 2)
                a = (obj.AlignedQuadraticForm(1) / -obj.AlignedQuadraticForm(6))^-0.5;
                b = (obj.AlignedQuadraticForm(3) / -obj.AlignedQuadraticForm(6))^-0.5;
                xy = [a .* cos(thetas); b .* sin(thetas)];
            elseif (type == 3)
                qf = obj.AlignedQuadraticForm;
                qf = qf / -qf(6);
                
                if (qf(3) < 0)
                    a = qf(1)^-0.5;
                    b = (-qf(3))^-0.5;
                    xy = [a .* sec(thetas); b .* tan(thetas)];
                else
                    a = (-qf(1))^-0.5;
                    b = qf(3)^-0.5;
                    xy = [a .* tan(thetas); b .* sec(thetas)];
                end
            else
                error('Unhandled conic type!');
                xy = [];
            end
            
            xy = obj.RotationMatrix * xy;
            
            x = xy(1, :) + obj.Translation(1);
            y = xy(2, :) + obj.Translation(2);
            
            if (nargout == 1)
                x = [x, y];
            end
        end
        
        function [x,y] = GetPointsFromPolarForm(obj, thetas)
            l = obj.SemiLatusRectum;
            e = obj.Eccentricity;
            r = l  ./ (1 - e * cos(thetas));
            
            xy = [r .* cos(thetas); r .* sin(thetas)];
            xy = obj.RotationMatrix * xy;
            
            x = xy(1, :) + obj.Translation(1);
            y = xy(2, :) + obj.Translation(2);
        end
        
        function [x,y] = GetPointsFromPolarForm2(obj, zeroToOne)
            % [x,y] = GetPointsFromPolarForm2(zeroToOne)
            
            %             l = obj.SemiLatusRectum;
            %             e = obj.Eccentricity;
            %
            %             % 0..1 -> 0..4 ->
            %             zeroToOne = mod(zeroToOne, 1);
            %             quadrant = fix(zeroToOne .* 4);
            %             cosValues = mod(zeroToOne .* 4, 1);
            %             sinValues = sqrt(1 - (cosValues .^ 2));
            %
            %             which = (quadrant > 1);
            %             cosValues(which) = 1-cosValues(which);
            %             which = mod(quadrant, 2) == 0;
            %             cosValues(which) = -cosValues(which);
            %             which = mod(quadrant, 2) == 0;
            %             sinValues(which) = 1-sinValues(which);
            %             which = (quadrant > 1);
            %             sinValues(which) = -sinValues(which);
            %
            %             r = l  ./ (1 - e * cosValues);
            %             x = r .* cosValues;
            %             y = r .* sinValues;
        end
        
        function SetHyperbola(obj, a, b, translation, rotationAngle)
            % The hyperbola has the form: x^2/a^2 - y^2/b^2 = 1
            
            if (nargin < 4)
                translation = [0 0];
            end
            
            if (nargin < 5)
                rotationAngle = 0;
            end
            
            qf = [a^-2, 0, -b^-2, 0, 0, -1];
            qf = QuadraticFormRotation(qf, rotationAngle);
            qf = QuadraticFormTranslation(qf, translation);
            obj.SetQuadraticForm(qf);
        end
        
        function SetEllipseStandardForm(obj, a, b)
            % The ellipse has the form: x^2/a^2 + y^2/b^2 = 1
            obj.SetEllipse(a, b, [0, 0], 0);
        end
        
        function SetEllipse(obj, a, b, translation, rotationAngle)
            % obj.SetEllipse(a, b, translation, rotationAngle)
            %
            % The ellipse has the form: x^2/a^2 + y^2/b^2 = 1
            
            if (nargin < 4)
                translation = [0 0];
            end
            
            if (nargin < 5)
                rotationAngle = 0;
            end
            
            qf = [a^-2, 0, b^-2, 0, 0, -1];
            qf = QuadraticFormRotation(qf, rotationAngle);
            qf = QuadraticFormTranslation(qf, translation);
            obj.SetQuadraticForm(qf);
        end
        
        function SetCircle(obj, radius)
            % The ellipse has the form: x^2/a^2 + y^2/b^2 = 1
            obj.SetQuadraticForm(1,0,1,0,0,-radius^2);
        end
        
        function SetQuadraticForm(obj, a,b,c,d,e,f)
            % Use either:
            % c.SetQuadraticForm(a,b,c,d,e,f)
            % c.SetQuadraticForm([a,b,c,d,e,f])
            %
            % Assuming the form: a*xx + b*xy + c*yy + d*x + e*y + f = 0
            
            assert(nargin == 7 || (nargin == 2 && numel(a) == 6));
            
            if (nargin == 7)
                obj.quadraticForm = [a,b,c,d,e,f];
            else
                obj.quadraticForm = a(:);
            end
            
            obj.QuadraticForm = obj.quadraticForm;
            
            [qf, shift, angle, rotMatrix, eccentricity, foci, semiLatusRectum] = ...
                obj.GetStandardizedConic();
            obj.Eccentricity = eccentricity;
            obj.Foci = foci;
            obj.Translation = shift;
            obj.AlignedQuadraticForm = qf;
            obj.RotationMatrix = rotMatrix;
            obj.RotationAngle = angle;
            obj.SemiLatusRectum = semiLatusRectum;
            
        end
        
        function [M] = GetConicMatrix(obj)
            % Returns
            % [
            % A   B/2 D/2;
            % B/2 C   E/2;
            % D/2 E/2 F  ;
            % ]
            
            qf = obj.quadraticForm;
            M = [...
                qf(1)  , qf(2)/2, qf(4)/2;...
                qf(2)/2, qf(3)  , qf(5)/2;...
                qf(4)  , qf(5)/2, qf(6)  ;...
                ];
        end
        
        function [d, M33, M12] = GetConicDeterminant(obj)
            M = obj.GetConicMatrix();
            
            M33 = det(M(1:2, 1:2));
            M12 = det(M([2,3], [1,3]));
            d = det(M);
        end
        
        function [numericType] = GetConicTypeNumeric(obj)
            [~, numericType, ~, ~, ~] = obj.GetConicType();
        end
            
        function [type, numericType, d, M33, M12] = GetConicType(obj)
            % Returns one of:
            %
            %
            
            [d, M33, M12] = obj.GetConicDeterminant();
            
            if (d == 0) % Degenerate
                numericType = 0;
                
                if (M33 > obj.EffectiveZero)
                    type = 'point';
                elseif (M33 < -obj.EffectiveZero)
                    if (obj.quadraticForm(1) + obj.quadraticForm(3) == 0)
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
                    
                    % TODO: Understand this condition (should I uncomment
                    % it?...)
                    %                     if (obj.quadraticForm(1) * d > 0) % no solution
                    %                         type = 'invalid';
                    %                         numericType = -1;
                    %                     else
                    if (obj.quadraticForm(1) == obj.quadraticForm(3) &&...
                            obj.quadraticForm(2) == 0)
                        type = 'circle';
                        numericType = 1;
                    else
                        type = 'ellipse';
                        numericType = 2;
                    end
                    %                     end
                elseif (M33 < -obj.EffectiveZero)
                    type = 'hyperbola';
                    numericType = 3;
                else
                    type = 'parabola';
                    numericType = 4;
                end
            end
        end
        
        function [qf] = GetQuadraticForm(obj)
            qf = obj.quadraticForm;
        end
        
        function [qf, shift, angle, rotMatrix, eccentricity, foci, semiLatusRectum] = ...
                GetStandardizedConic(obj)
            
            [qf, shift, angle, rotMatrix, eccentricity, foci, semiLatusRectum] = QuadraticFormStandardizeConic(obj);
        end
        
        function [] = SetConexParameters(obj, alpha, d0, Xd0, Yd0, beta, coneAngle)
            % [] = obj.SetConexParameters(alpha, d0, Xd0, Yd0, beta, coneAngle)
            % 
            
            coneAngleLimit = pi/2 - alpha;
            
            % From "find_Direct_Beam_conX"
            XY0 = [-cos(beta), sin(beta);sin(beta), +cos(beta)]*[Xd0;Yd0];
            
            if (coneAngle < (coneAngleLimit - 0.0005))
                
                % The ellipse returned has its major axis on the Y axis.
                % Y0 is the offset of the focus.
                [b,a,Y0] = GeometryToEllipseParameters(alpha, coneAngle);

                obj.SetEllipseStandardForm(a*d0, b*d0);
                
            elseif (coneAngle > (coneAngleLimit + 0.0005))
                
                [b,a,Y0] = GeometryToHyperbolaParameters(alpha, coneAngle);
                
                obj.SetHyperbola(a*d0, b*d0);
                
            else
                % TODO: Theta equals Alpha !!! Why didn''t I handle this???
                error('Theta equals Alpha !!! Why didn''t I handle this???');
            end
            
                qf = obj.QuadraticForm;

                % The original transformation (in CONEX) was:
                % Shift by Y0
                % Shift by [-Xd0, -Yd0]
                % Rotate beta
                % Flip Y sign

                qf = QuadraticFormTranslation(qf, [0, Y0*d0]);
                qf = QuadraticFormTranslation(qf, -XY0);
                qf = QuadraticFormRotation(qf, -beta);
                qf = QuadraticFormFlipY(qf);
                obj.SetQuadraticForm(qf);

        end
        
        function Move(obj, xShift, yShift)
            if (nargin <2)
                xyShift = xShift;
            else
                xyShift = [xShift, yShift];
            end
            
            qf = obj.QuadraticForm;
            qf = QuadraticFormTranslation(qf, xyShift);
            obj.SetQuadraticForm(qf);
        end
        
        function Rotate(obj, angle)
            qf = obj.QuadraticForm;
            qf = QuadraticFormRotation(qf, angle);
            obj.SetQuadraticForm(qf);
        end
        
        function FlipY(obj)
            qf = obj.QuadraticForm;
            qf = QuadraticFormFlipY(qf);
            obj.SetQuadraticForm(qf);
        end
        
        function [result] = SquareParameterDistanceFromConexConic(obj, alpha, d0, Xd0, Yd0, beta, coneAngle)
            conic = ConicClass();
            conic.SetConexParameters(alpha, d0, Xd0, Yd0, beta, coneAngle);
            
            result = sumsqr([obj.QuadraticForm / obj.QuadraticForm(6)] - [conic.QuadraticForm / conic.QuadraticForm(6)]);
        end
        
        function [alpha, d0, Xd0, Yd0, beta, squareDistance] = GetConexParametersThroughNonLinearMinimzationOfQuadraticForm(obj, coneAngle, alpha, d0, Xd0, Yd0, beta)
            conic = ConicClass();
            
            if (numel(nargin) < 3), alpha = 0; end
            if (numel(nargin) < 4), d0 = 1e3; end
            if (numel(nargin) < 5), Xd0 = 0; end
            if (numel(nargin) < 6), Yd0 = 0; end
            if (numel(nargin) < 7), beta = 0; end
            
            initialParams = [alpha, d0, Xd0, Yd0, beta];
            
            [bestParams, squareDistance] = fminsearch(@(p)obj.SquareParameterDistanceFromConexConic(p(1), p(2), p(3), p(4), p(5), coneAngle), initialParams);
            alpha = bestParams(1);
            d0 = bestParams(2);
            Xd0 = bestParams(3);
            Yd0 = bestParams(4);
            beta = bestParams(5);
        end
        
        function [result] = SquareDistanceOfSelectedPointsFromConexConic(obj, alpha, d0, Xd0, Yd0, beta, coneAngle, angles)
            conic = ConicClass();
            conic.SetConexParameters(alpha, d0, Xd0, Yd0, beta, coneAngle);
            
            result = sumsqr(obj.GetPointsFromParametricForm(angles) - conic.GetPointsFromParametricForm(angles));
        end
        
        function [alpha, d0, Xd0, Yd0, beta, squareDistance] = GetConexParametersThroughNonLinearMinimzation(obj, coneAngle, alpha, d0, Xd0, Yd0, beta)
            conic = ConicClass();
            
            if (numel(nargin) < 3), alpha = 0; end
            if (numel(nargin) < 4), d0 = 1e3; end
            if (numel(nargin) < 5), Xd0 = 0; end
            if (numel(nargin) < 6), Yd0 = 0; end
            if (numel(nargin) < 7), beta = 0; end
            
            initialParams = [alpha, d0, Xd0, Yd0, beta];
            
            angles = [rand() + linspace(0, 1, 100)] * 2 * pi;
            [pointsX, pointsY] = obj.GetPointsFromParametricForm([rand() + linspace(0, 1, 100)] * 2 * pi);
            
            while (~all(isfinite(pointsX) & isfinite(pointsY)))
                angles = [rand() + linspace(0, 1, 100)] * 2 * pi;
                [pointsX, pointsY] = obj.GetPointsFromParametricForm([rand() + linspace(0, 1, 100)] * 2 * pi);
            end
            
            [bestParams, squareDistance] = fminsearch(@(p)obj.SquareDistanceOfSelectedPointsFromConexConic(p(1), p(2), p(3), p(4), p(5), coneAngle, angles), initialParams);
            
            alpha = bestParams(1);
            d0 = bestParams(2);
            Xd0 = bestParams(3);
            Yd0 = bestParams(4);
            beta = bestParams(5);
        end
        
        function [segments, segmentsSum] = GetSegmentsWithinRect(obj, rect)
            % [segments, segmentsSum] = obj.GetSegmentsWithinRect(rect)
            
            [~, ~, t, out] = obj.GetIntersectionWithRect(rect);

            segments = [];
            if (numel(t) == 0) % Either entirely contained or no overlap at all
                [x0, y0] = obj.GetPointsFromParametricForm(0);
                if (WithinRect(rect, x0, y0))
                    segments = [0, 2*pi];
                end
            elseif (any(out == 1))
                % Look for consecutive in-out pairs (cyclic)
                which = ([diff(out) out(1)-out(end)] == 1);
                
                which = find(which);
                which = which(:);
                startAngle = which;
                endAngle = which + 1;
                if (endAngle(end) > numel(t)), endAngle(end) = 1; end;
                segments = t([startAngle, endAngle]);
                
                need2pi = segments(:, 1) > segments(:, 2);
                segments(need2pi, 2) = segments(need2pi, 2) + 2*pi;
            end
            
            segmentsSum = sum(diff(segments, 1, 2));
        end
        
        function [y, t] = GetYForX(obj, x)
            [~, type] = obj.GetConicType();
            if (type > 3)
                error('Only implemented for Circle, Ellipse & Hyperbola!');
            end;
            
            qf = obj.QuadraticForm;
            poly = [qf(1)*(x^2) + qf(4)*x + qf(6), qf(5) + qf(2)*x, qf(3)];
            y = ParabolaSolution(poly);
            t = obj.GetParameterFromPoint(kron(x, ones(numel(y), 1)), y(:));
        end
            
        function [x, t] = GetXForY(obj, y)
            [~, type] = obj.GetConicType();
            if (type > 3)
                error('Only implemented for Circle, Ellipse & Hyperbola!');
            end;
            
            qf = obj.QuadraticForm;
            poly = [qf(3)*(y^2) + qf(5)*y + qf(6), qf(4) + qf(2)*y, qf(1)];
            x = ParabolaSolution(poly);
            t = obj.GetParameterFromPoint(x(:), kron(y, ones(numel(x),1)));
        end
            
        function [x, y, t, isOutward] = GetIntersectionWithRect(obj, rect)
            if (numel(rect) ~= 4), error('Should have 4 numbers!'); end
            
            [~, type] = obj.GetConicType();
            if (type > 3)
                error('Only implemented for Circle, Ellipse & Hyperbola!');
            end;
            
            x1 = rect(1);
            y1 = rect(2);
            x2 = x1 + rect(3);
            y2 = y1 + rect(4);
            
            qf = obj.QuadraticForm;
            poly1 = [qf(3)*(y1^2) + qf(5)*y1 + qf(6), qf(4) + qf(2)*y1, qf(1)];
            poly2 = [qf(3)*(y2^2) + qf(5)*y2 + qf(6), qf(4) + qf(2)*y2, qf(1)];
            
            poly3 = [qf(1)*(x1^2) + qf(4)*x1 + qf(6), qf(5) + qf(2)*x1, qf(3)];
            poly4 = [qf(1)*(x2^2) + qf(4)*x2 + qf(6), qf(5) + qf(2)*x2, qf(3)];
            
            points = [];
            x = ParabolaSolution(poly1);
            points(end+1:end+numel(x), :) = [x(:), kron(y1, ones(numel(x),1))];
            x = ParabolaSolution(poly2);
            points(end+1:end+numel(x), :) = [x(:), kron(y2, ones(numel(x),1))];
            y = ParabolaSolution(poly3);
            points(end+1:end+numel(y), :) = [kron(x1, ones(numel(y),1)), y(:)];
            y = ParabolaSolution(poly4);
            points(end+1:end+numel(y), :) = [kron(x2, ones(numel(y),1)), y(:)];
            
            if (isempty(points))
                x = [];
                y = [];
                t = [];
                isOutward = [];
                return;
            end
            
            x = points(:, 1);
            y = points(:, 2);
            
            which = WithinRect(rect, x, y);
            x = x(which);
            y = y(which);
            isOutward = false(size(x));
            t = obj.GetParameterFromPoint(x, y);
            
            if (numel(x) > 0)
                [t, order] = sort(t);
                x = x(order);
                y = y(order);

                dt = diff(t);
                dt(end+1) = abs(t(1) - t(end));
                if (dt(end) > pi); dt(end) = 2*pi - dt(end); end;

                % This is crucial in case of a hyperbola
                dt = min(dt, 2e-3);
               
                testedAngles = t + dt/2;
                [testedX, testedY] = obj.GetPointsFromParametricForm(testedAngles);
            
                % For debug:
                %hold on; plot(testedX, testedY, 'ok'); hold off;

                % Check if the arc between the intersections is outside the
                % rectangle
                isOutward = ~WithinRect(rect, testedX, testedY);
            end
        end
    end
    
end