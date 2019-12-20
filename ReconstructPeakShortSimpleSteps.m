function [curve] = ReconstructPeakShortSimpleSteps(image, mask, x, y, profileAngle, peakSigma, options)

%% Handle input checks
if (nargin < 7)
    options = GenerateDefaultOptions();
    
    if (nargin < 6)
        if (nargout == 1)
            curve = options; % Return the default options struct as the first output
            return;
        else
            %load([mfilename '-state']); % For debug
            error('Bad number of inputs/outputs in call');
        end
    end
else
    %save([mfilename '-state']); % For debug
end

curve = struct();

%%
if (0)
    figure(2);
    imagesc(log(image + 1));
end

%%

if (0) % Experimental
    a = rand(1, 2) * 2 * pi();
    r = 10;
    
    x1 = r * cos(a(1)) + x;
    y1 = r * sin(a(1)) + y;
    x2 = r * cos(a(2)) + x;
    y2 = r * sin(a(2)) + y;
    
    ppX = spline([-1 0 1], [x1 x x2]);
    ppY = spline([-1 0 1], [y1 y y2]);
    %ppval(ppX, t)
    
    t = -1:0.1:1;
    xx = ppval(ppX, t);
    yy = ppval(ppY, t);
    hold on;
    plot(xx, yy, '*r');
    hold off;
    
    return;
end

imageWithNansForMask = image;
imageWithNansForMask(mask < 0.999) = nan;

if (1)
    
    stepSize = 10;
    rMax = max(size(image)) / 2;
    maxSteps = min((2 * pi * rMax) / stepSize, options.MaxSteps);
    
    [pointsX pointsY stepAngles wasLoopClosed] = WalkThePeak(stepSize, x, y, profileAngle + pi / 2, maxSteps);
    curve.WasLoopClosed = wasLoopClosed;
    
    if (0) % plot for debug
        hold on;
        plot(pointsX, pointsY, '*y', 'MarkerSize', 10);
        hold off;
    end
    
    pointsForFitX = pointsX;
    pointsForFitY = pointsY;
    allStepAnglesInFit = stepAngles;
    
    if (~wasLoopClosed)
        [otherWayPointsX otherWayPointsY otherWayStepAngles wasLoopClosed] = WalkThePeak(stepSize, x, y, profileAngle - pi / 2, maxSteps);
        
        % Add the new points
        pointsForFitX = [pointsForFitX otherWayPointsX(2:end)];
        pointsForFitY = [pointsForFitY otherWayPointsY(2:end)];
        allStepAnglesInFit = [allStepAnglesInFit otherWayStepAngles(2:end)];
        
        if (0)
            hold on;
            plot(otherWayPointsX, otherWayPointsY, '*g', 'MarkerSize', 10);
            hold off;
        end
    end
    
    curve.X = pointsForFitX;
    curve.Y = pointsForFitY;
    curve.StepAngles = allStepAnglesInFit;
    
    if (0)
        % Fit a conic to the given points
        conic = ConicClass();
        centerX = mean(pointsForFitX);
        centerY = mean(pointsForFitY);
        hold on;
        plot(centerX, centerY, '*b', 'MarkerSize', 20);
        hold off;
        radius = mean(sqrt((pointsForFitX - centerX) .^ 2 + (pointsForFitY - centerY) .^ 2));
        
        % Initially generate a circle coarsely fitting the points
        conic.SetCircle(radius);
        conic.Move(centerX, centerY);
        qf = conic.GetQuadraticForm();
        %conic.DebugPlotInRect([1, 1, size(image, 2), size(image, 1)], 'Blue');
    end
    
    lambda = 1.543;
    twoK = 4 * pi / lambda;
    q = 0.1075;
    twoTheta = 2 * asin(q / twoK);
    calibration = CalibrationFromPoints(pointsForFitX, pointsForFitY, twoTheta);
    %calibration.FinalConic.DebugPlotInRect([1, 1, size(image, 2), size(image, 1)], 'Red');
    
    curve.Conic = calibration.FinalConic;
    curve.Calibration = calibration;
    
    1;
    
end


%%
    function [options] = GenerateDefaultOptions()
        options = struct();
        options.MaxSteps = 1000;
    end

    function [pointsX pointsY stepAngles wasLoopClosed] = WalkThePeak(stepSize, x, y, firstStepAngle, maxSteps)
        twoStepSize = 2 * stepSize;
        r = [1:stepSize];
        stepAngle = firstStepAngle;
        wasLoopClosed = 0;
        
        stepAngles = [0];
        pointsX = [x];
        pointsY = [y];
        
        for step = 1:maxSteps
            % Try a spread of angles around the forward angle
            angles = stepAngle + linspace(-pi/3, pi/3, 30);
            
            % Find the step angle with maximal intensity
            ValuesFunc = @(a)mean(interp2(imageWithNansForMask, pointsX(end) + r .* cos(a), pointsY(end) + r .* sin(a)));
            values = arrayfun(ValuesFunc, angles);
            
            % Bad step. Too close to masked-out areas.
            if (any(isnan(values)))
                break;
            end
            
            [~, maxIndex] = max(values);
            
            % Set the current step angle
            stepAngle = angles(maxIndex);
            
            % TODO: Have the step size adaptive. (Something like: increase step
            % size as long as the mean intensity doesn't go down too much)
            
            % Add the point to list of points
            pointsX(end + 1) = pointsX(end) + r(end) .* cos(stepAngle);
            pointsY(end + 1) = pointsY(end) + r(end) .* sin(stepAngle);
            stepAngles(end + 1) = stepAngle;
            
            if (0)
                hold on;
                plot(pointsX(end), pointsY(end), '*g', 'MarkerSize', 10);
                hold off;
                drawnow();
                pause(0.1);
            end
            
            % Have we stepped outside the image?
            if (any([pointsX(end) pointsY(end)] <= [0 0]) || any([pointsX(end) pointsY(end)] >= (size(image) + 1)))
                break;
            end
            
            % Have we closed a loop?...
            if (step > 2 && norm([pointsX(end) pointsY(end)] - [pointsX(1) pointsY(1)]) < twoStepSize)
                wasLoopClosed = 1;
                break;
            end
            
        end
    end

end
