function [calibration detailedResults] = SingleClickCalibrationProcedure(image, mask, initialPoint, twoTheta, options)

% Debug
%initialPoint = [ 303.1951  135.4103];
shouldPlotForDebug = 0;

if (1)
    if (nargin > 1)
        save('SingleClickCalibrationProcedure_debug.mat');
    elseif (nargin == 1 && ischar(image) && strcmp(image, '-debug'))
        load('SingleClickCalibrationProcedure_debug.mat');
    end
end

%% Handle getting the default options
if (nargin == 0)
    options = struct();
    options.ShouldPlot = 0;
    options.ShouldAnimate = 1;
    options.OptimizedSquareHalfWidth = 15;
    options.OptimizedPointRadius = [9 6 4];
    options.NextPointStep = options.OptimizedPointRadius * 1.5;
    
    options.SquareOptimizationMinChange = 0.5;
    options.SquareOptimizationMaxIterations = 50;
    options.SquareOptimizationMaxMovement = 50;
    
    options.CircleOptimizationMinChange = 0.01;
    options.CircleOptimizationMaxIterations = 50;
    options.CircleOptimizationMaxMovement = 5;
    
    options.ShouldTrySmallJump = 1;
    options.MaxSmallJumps = 5;
    options.SmallJumpInUnitsOfSteps = 7;
    
    options.ShouldTryLongJump = 0;
    
    options.MaxPortionOfMaskedPixels = 0.2; % This includes masking due to symmetrization
    
    options.PreviousPoints = [];
    options.PreviousPointsSize = [];
    
    options.MaximalChangeInSingleStepIntensity = 0.8;
    
    calibration = options;
    return;
end


calibration = [];
detailedResults = struct();
detailsResults.AllPoints = [];
detailsResults.AllPointsSize = [];
detailsResults.AddedPoints = [];
detailsResults.AddedPointsSize = [];

points = [];
pointsSize = [];

imageWidth = size(image, 2);
imageHeight = size(image, 1);

imageWithNans = image;
imageWithNans(~mask) = nan;

MaxPortionOfMaskedPixels = options.MaxPortionOfMaskedPixels;
nextPointStep = options.NextPointStep(1);
pointRadius = options.OptimizedPointRadius(1);
squareHalfWidth = options.OptimizedSquareHalfWidth;
optimizedPointBigRadius = 1.3 * pointRadius;

options.OptimizedPointRadius = sort(options.OptimizedPointRadius, 'descend');
options.NextPointStep = sort(options.NextPointStep, 'descend');

bigStep = options.NextPointStep(1);
bigPointRadius = options.OptimizedPointRadius(1);
smallPointRadius = options.OptimizedPointRadius(end);
smallPointStep = options.NextPointStep(end);
meanStep = mean(options.NextPointStep);
meanPointRadius = mean(options.OptimizedPointRadius);

%% Initialize the coarse-grained points map
coarseMapPadding = 3;
coarsePointsMapWidth = min(ceil(imageWidth / bigStep), 200) + coarseMapPadding;
coarsePointsMapHeight = min(ceil(imageHeight / bigStep), 200) + coarseMapPadding;
coarsePointsMap = cell(coarsePointsMapHeight, coarsePointsMapWidth);

coarseGridCellWidth = imageWidth / (coarsePointsMapWidth - coarseMapPadding);
coarseGridCellHeight = imageHeight / (coarsePointsMapHeight - coarseMapPadding);

%% Add previous points
numOfPreviousPoints = size(options.PreviousPoints, 1);
for i = 1:numOfPreviousPoints
    AddMarkedPoint(options.PreviousPoints(i, :), options.PreviousPointsSize(i));
end

%% Improve selected point (square)

centerX = initialPoint(1);
centerY = initialPoint(2);
optimizedPoint = initialPoint;

MaxMovement = options.SquareOptimizationMaxMovement; % pixels
MaxIterations = options.SquareOptimizationMaxIterations;
MinChange = options.SquareOptimizationMinChange;

for i = 1:MaxIterations
    if (options.ShouldPlot && options.ShouldAnimate)
        PlotSquareOnTop([centerX centerY], squareHalfWidth, 'red', 1);
        pause(0.01);
    end
    
    x = centerX+[-squareHalfWidth:squareHalfWidth];
    y = centerY+[-squareHalfWidth:squareHalfWidth];
    x = x(x > 0 & x <= size(image, 2));
    y = y(y > 0 & y <= size(image, 1));
    
    [X, Y] = meshgrid(x, y);
    MaxNumOfValidValues = numel(X);
    
    imagePart = interp2(imageWithNans, X, Y);
    whichMaskedOut = isnan(imagePart);
    whichMaskedOut = whichMaskedOut | whichMaskedOut'; % Make the masked pixels symmetric to avoid bias
    numValidValues = nnz(~whichMaskedOut);
    
    if ((nnz(whichMaskedOut) / MaxNumOfValidValues) > MaxPortionOfMaskedPixels)
        % Give these a zero vote so that the iterations would turn away from this position
        imagePart(whichMaskedOut) = 0;
    else
        % Few enough... so remove these masked-out points
        imagePart(whichMaskedOut) = [];
        X(whichMaskedOut) = [];
        Y(whichMaskedOut) = [];
    end
    
    sumOfImagePart = sum(imagePart(:));
    centerX = (X(:)' * imagePart(:)) / sumOfImagePart;
    centerY = (Y(:)' * imagePart(:)) / sumOfImagePart;
    
    wasThresholdMet = norm([centerX centerY] - optimizedPoint) < MinChange;
    optimizedPoint = [centerX centerY];
    
    if (norm([centerX centerY] - initialPoint) >= MaxMovement || wasThresholdMet)
        break;
    end
end

%save([mfilename 'state']); %  debug debug debug

%% 
%load([mfilename 'state']); %  debug debug debug

WalkAndMark(optimizedPoint);

shouldTrySmallJump = options.ShouldTrySmallJump;
numberOfJumps = 0;

while (shouldTrySmallJump)
    shouldTrySmallJump = 0; % Would be turned to 1 later if something changed
    
    % Not enough points?...
    if (size(points, 1) < 5)
        break;
    end
    
    %% Calculate initial calibration
    calibrationOptions = CalibrationFromPoints();
    [calibration] = CalibrationFromPoints(points(:, 1), points(:, 2), twoTheta, calibrationOptions);
    
    conic = ConicClass();
    conic.SetConexParameters(calibration.Alpha, calibration.SampleToDetector, calibration.BeamX, calibration.BeamY, calibration.Beta, twoTheta);
    
    boundingRect = [0 0 size(image, 2)+0.5 size(image, 1)+0.5];
    %boundingRect = [1 1 size(image, 2) size(image, 1)];
    
    if (options.ShouldPlot)
        hold on;
        conic.DebugPlotInRect(boundingRect, 'black');
        %conic.DebugPlot2();
        hold off;
    end
    
    %% Find unmarked/unadjusted regions on the conic
    
    % Generate a map of existing marks and find when the conic doesn't go
    % through it...
    
    pointsConicParameter = conic.GetParameterFromPoint(points(:, 1), points(:, 2));
    pointsConicParameter = AngleNormalize(pointsConicParameter(:));

    segments = conic.GetSegmentsAndPointsWithinRect(boundingRect, 1);
    
    for segIndex = 1:numel(segments)
        segments(segIndex).Thetas = AngleNormalize(segments(segIndex).Thetas);
        
        segments(segIndex).StartAngle = segments(segIndex).Thetas(1);
        segments(segIndex).AngularRange = AngleNormalize(segments(segIndex).Thetas(end) - segments(segIndex).Thetas(1), 1);
        segments(segIndex).RelativeThetas = AngleNormalize(segments(segIndex).Thetas - segments(segIndex).Thetas(1), 1);
        segments(segIndex).Steps = sqrt(diff(segments(segIndex).X).^2 + diff(segments(segIndex).Y).^2);
        segments(segIndex).WalkingDistances = [0; cumsum(segments(segIndex).Steps)];
        
        % Generate bins with width slightly bigger than "bigStep"
        segments(segIndex).HistogramsDistanceEdgesN = floor(segments(segIndex).WalkingDistances(end)/(bigStep*1.1));
        segments(segIndex).HistogramsDistanceEdges = linspace(0, segments(segIndex).WalkingDistances(end)+1e-2, segments(segIndex).HistogramsDistanceEdgesN+1);

        walkingDistancesForInterpolation = segments(segIndex).WalkingDistances;
        relativeThetasForInterpolation = segments(segIndex).RelativeThetas;
        if (1)
            % extend "walking distances" and corresponding angles to ensure valid
            % interpolation at the edges

            pointsForExtrapolation = 5;
            
            which = 1:pointsForExtrapolation;
            % Linear extrapolation
            pStart = polyfit(relativeThetasForInterpolation(which), walkingDistancesForInterpolation(which), 1);
            which = numel(relativeThetasForInterpolation)+1-which;
            % Linear extrapolation
            pEnd = polyfit(relativeThetasForInterpolation(which), walkingDistancesForInterpolation(which), 1);
            
            % Update the vectors
            relativeThetasForInterpolation = [-deg2rad(0.1); relativeThetasForInterpolation; 2*pi+deg2rad(0.1)];
            walkingDistancesForInterpolation = [polyval(pStart, relativeThetasForInterpolation(1)); ...
                walkingDistancesForInterpolation; polyval(pEnd, relativeThetasForInterpolation(end))];
        end
        
        InterpolateThetaForWalkingDistance = @(dist)spline(walkingDistancesForInterpolation, relativeThetasForInterpolation, dist);
        
        segments(segIndex).HistogramsRelativeThetaEdges = InterpolateThetaForWalkingDistance(segments(segIndex).HistogramsDistanceEdges);
        
        whichRelevantPoints = AngleNormalize(pointsConicParameter - segments(segIndex).Thetas(1), 1) <= segments(segIndex).AngularRange;
        pointsConicParameterRelative = AngleNormalize(pointsConicParameter - segments(segIndex).Thetas(1), 1);
        
        % Sample values every 2 pixels
        dPixelsToSample =  smallPointRadius / 2;
        numberOfSamplePoints = ceil(segments(segIndex).WalkingDistances(end)/dPixelsToSample);
        distancesToSample = linspace(0, segments(segIndex).WalkingDistances(end), numberOfSamplePoints);
        thetasToSample = AngleNormalize(InterpolateThetaForWalkingDistance(distancesToSample) + segments(segIndex).StartAngle);

        % Points to sample
        [x, y] = conic.GetPointsFromParametricForm(thetasToSample);
        
        % Expand each point to a disc around that point
        if (1)
            %%
            numberOfDiscPoints = round(2 * smallPointRadius / 0.25) + 1;
            
            discPointsVec = linspace(-smallPointRadius, smallPointRadius, numberOfDiscPoints);
            [discX, discY] = meshgrid(discPointsVec, discPointsVec);
            whichDiscPoints = (discX .^ 2 + discY .^ 2) <= smallPointRadius^2;
            discX = discX(whichDiscPoints);
            discY = discY(whichDiscPoints);
            
            x = bsxfun(@plus, x, discX);
            y = bsxfun(@plus, y, discY);
            
            distancesToSample = bsxfun(@times, distancesToSample, ones(size(x)));
        end
        
        valuesOnConic = interp2(imageWithNans, x, y);
    
        segments(segIndex).HistogramsDistanceMean = 0.5*(segments(segIndex).HistogramsDistanceEdges(1:end-1)+segments(segIndex).HistogramsDistanceEdges(2:end));
        segments(segIndex).HistogramsMidleTheta = InterpolateThetaForWalkingDistance(segments(segIndex).HistogramsDistanceMean);
        [markingHistogram, bin] = histc(pointsConicParameterRelative(whichRelevantPoints), segments(segIndex).HistogramsRelativeThetaEdges);
        [invalidHistogram, bin] = histc(distancesToSample(isnan(valuesOnConic)), segments(segIndex).HistogramsDistanceEdges);
        
        % Ignore last bin, it should always contain 0
        markingHistogram(end) = [];
        invalidHistogram(end) = [];
        
        
        1;
        
        if (0)
            % Find regions which are both valid and unmarked
            unmarkedValidBins = (~markingHistogram(:)).*(~invalidHistogram(:));
            
            %TODO: Deviations from the actual underlying conic would be minimal as close
            % as possible to already marked points, so start from there...
            markedBins = (markingHistogram~=0);
            
            % For each bin, create a vector of the first previously marked bin and
            % the first next marked bin
            
            % Take all edges of consecutive unmarked&valid bins
            unmarkedValidUpsAndDowns = [unmarkedValidBins(1)>0 ; diff(unmarkedValidBins>0)];
            whichUps = find((unmarkedValidUpsAndDowns == 1));
            whichDowns = find((unmarkedValidUpsAndDowns == -1))-1;
        end
        
        histogramUpsAndDowns = [markingHistogram(1)>0 ; diff(markingHistogram>0)];
        
        prevFirstMarkedIndex = 0;
        firstMarkedIndex = FindInArray(histogramUpsAndDowns == 1, 1, prevFirstMarkedIndex);
        prevFirstMarkedIndex = firstMarkedIndex;
        
        while (~isempty(firstMarkedIndex))
            firstUnmarkedBinAfter = FindInArray(histogramUpsAndDowns == -1, 1, firstMarkedIndex);
            searchEnd = FindInArray(histogramUpsAndDowns == 1, 1, firstUnmarkedBinAfter);
            if (isempty(searchEnd)); searchEnd = numel(histogramUpsAndDowns)+1; end
            
            selectedBin = [];
            for i = firstUnmarkedBinAfter:min(searchEnd-1, firstUnmarkedBinAfter+options.SmallJumpInUnitsOfSteps-1)
                if (~invalidHistogram(i))
                    selectedBin = i;
                    break;
                end
            end
            
            % Search backwards
            if (isempty(selectedBin))
                searchEndBackwards = FindInArray(histogramUpsAndDowns == -1, 1, -firstMarkedIndex);
                if (isempty(searchEndBackwards)); searchEndBackwards = 0; end
                
                for i = firstMarkedIndex-1:-1:max([searchEndBackwards,firstMarkedIndex-options.SmallJumpInUnitsOfSteps, 1])
                    if (~invalidHistogram(i))
                        selectedBin = i;
                        break;
                    end
                end
            end
            
            if (~isempty(selectedBin))
                
                validAndUnmarked = [(~markingHistogram(:)) & (~invalidHistogram(:))]';
                
                
                if (shouldPlotForDebug)
                    %%
                    figure(101);
                    bar(validAndUnmarked);
                    
                    while (waitforbuttonpress() ~= 0); end;
                end
                
                % Stay away from invalid points if possible
                if (selectedBin > 1 && selectedBin < numel(markingHistogram) && ...
                        invalidHistogram(selectedBin-1) && ~invalidHistogram(selectedBin+1))
                    selectedBin = selectedBin + 1;
                end
                
                % Get the angle (conic parameter) corresponding to the selected bin
                selectedTheta = AngleNormalize(segments(segIndex).StartAngle + segments(segIndex).HistogramsRelativeThetaEdges(selectedBin));
                
                if (~isnan(selectedTheta))
                    numberOfJumps = numberOfJumps + 1;
                    
                    selectedPoint = conic.GetPointsFromParametricForm(selectedTheta);
                    
                    oldNumOfPoints = size(points, 1);
                    WalkAndMark(selectedPoint);
                    
                    if (oldNumOfPoints ~= size(points, 1) && numberOfJumps < options.MaxSmallJumps) % Something was marked?
                        shouldTrySmallJump = 1; % Try more jumps after re-calibration
                        break;
                    end
                end
            end
            
            firstMarkedIndex = FindInArray(histogramUpsAndDowns == 1, 1, prevFirstMarkedIndex);
            prevFirstMarkedIndex = firstMarkedIndex;
        end
    end
    
end

1;

%% Done with marking the ring
1;

%for xxx = 1:100
if (0) % TODO

    %% Calculate initial calibration
    calibrationOptions = CalibrationFromPoints();
    [calibration] = CalibrationFromPoints(points(:, 1), points(:, 2), twoTheta, calibrationOptions);
    
    conic = ConicClass();
    conic.SetConexParameters(calibration.Alpha, calibration.SampleToDetector, calibration.BeamX, calibration.BeamY, calibration.Beta, twoTheta);
    
    pointsConicParameter = conic.GetParameterFromPoint(points(:, 1), points(:, 2));
    pointsConicParameter = AngleNormalize(pointsConicParameter(:));
    
    dL = conic.GetWalkDeriv(pointsConicParameter);
    
    [~, order] = sort(pointsConicParameter);

    boundingRect = [0 0 size(image, 2)+0.5 size(image, 1)+0.5];

    for i = 1:size(points, 1)
    %if (1)
        %i = 5;
        p = points(i, :);
        ps = pointsSize(i, :);
        dTheta = ps ./ dL(i);
        dR = ps;
        
        thetaValues = linspace(-1, 1, 50) * dTheta;
        rValues = linspace(-1, 1, 70) * dR;

        [X, Y] = conic.GetPointsFromParametricForm(thetaValues);

        % TODO: Take each x,y from thetas and generates point on the line from
        % the beam center to this x,y and go [-r..r] on it.
        lineAngles = atan2(Y - calibration.BeamY, X - calibration.BeamX);
        dx = rValues' * cos(lineAngles);
        dy = rValues' * sin(lineAngles);

        x = p(1) + dx;
        y = p(2) + dy;
        
        values = interp2(imageWithNans, x, y);
        
        if (any(isnan(values)))
            continue;
        end
        
        meanRShift = mean(rValues * values ./ sum(values, 1));
        
        if (~isnan(meanRShift))
            a = atan2(points(i, 2) - calibration.BeamY, points(i, 1) - calibration.BeamX);
            points(i, :) = points(i, :) + meanRShift * [cos(a) sin(a)];
        end
    end
    
    %% Calculate initial calibration
    calibrationOptions = CalibrationFromPoints();
    [calibration] = CalibrationFromPoints(points(:, 1), points(:, 2), twoTheta, calibrationOptions);
    
    conic = ConicClass();
    conic.SetConexParameters(calibration.Alpha, calibration.SampleToDetector, calibration.BeamX, calibration.BeamY, calibration.Beta, twoTheta);
    
    boundingRect = [0 0 size(image, 2)+0.5 size(image, 1)+0.5];
    %boundingRect = [1 1 size(image, 2) size(image, 1)];
    
    if (options.ShouldPlot)
        hold on;
        conic.DebugPlotInRect(boundingRect, 'yellow');
        %conic.DebugPlot2();
        hold off;
    end
    
    calibration.SampleToDetector * 0.172
    1;
    
end
1;


    function [] = WalkAndMark(optimizedPoint)
        values = SampleImageAtCircle(image, [], optimizedPoint, pointRadius, 0.25);
        MaxNumOfValidValues = numel(values);
        
        MaxMovement = options.CircleOptimizationMaxMovement; % pixels
        MaxIterations = options.CircleOptimizationMaxIterations;
        MinChange = options.CircleOptimizationMinChange;
        firstCenter = optimizedPoint;
        
        for i = 1:MaxIterations
            if (0 && options.ShouldPlot && options.ShouldAnimate)
                PlotCircleOnTop([centerX centerY], pointRadius, 'green', 1);
            end
            
            [imagePart, X, Y, which] = SampleImageAtCircle(imageWithNans, [], optimizedPoint, pointRadius, 0.25, 1);
            %numValidValues = numel(imagePart);
            whichMaskedOut = isnan(imagePart);
            
            if (nnz(isnan(imagePart)) > 0)
                1;
            end
            
            % Extend the masked out pixels to the symmetric counterparts to
            % remove any possible bias
            whichMaskedOut = whichMaskedOut | whichMaskedOut';
            
            imagePart = imagePart(which);
            X = X(which);
            Y = Y(which);
            whichMaskedOut = whichMaskedOut(which);
            
            numValidValues = nnz(~whichMaskedOut);
            
            if (nnz(whichMaskedOut) > 0)
                1;
            end
            
            if ((nnz(whichMaskedOut) / MaxNumOfValidValues) > MaxPortionOfMaskedPixels)
                % Give these a zero vote so that the iterations would turn away from this position
                imagePart(whichMaskedOut) = 0;
            else
                % Few enough... so remove these masked-out points
                imagePart(whichMaskedOut) = [];
                X(whichMaskedOut) = [];
                Y(whichMaskedOut) = [];
            end
            
            sumOfImagePart = sum(imagePart(:));
            centerX = (X(:)' * imagePart(:)) / sumOfImagePart;
            centerY = (Y(:)' * imagePart(:)) / sumOfImagePart;
            
            % Make sure the points have valid values
            if (any(~isfinite([centerX centerY])))
                return;
            end
            
            wasChangeThresholdMet = (norm([centerX centerY] - optimizedPoint) < MinChange);
            optimizedPoint = [centerX centerY];
            
            if (norm(optimizedPoint - firstCenter) >= MaxMovement || wasChangeThresholdMet)
                break;
            end
            
            if (0 && options.ShouldPlot && options.ShouldAnimate)
                pause(0.01);
            end
        end
        
        lower5thPercentileIntensity = Percentile(imagePart, 0.05);
        upper5thPercentileIntensity = Percentile(imagePart, 0.95);
        maxIntentisy = max(imagePart);
        
        % Too noisy?... stop marking
        % TODO: Come up with a better "too-much-noise" detection
%         if (upper5thPercentileIntensity / lower5thPercentileIntensity < 1.3)
%             return;
%         end

        firstMarkedUpper5thPercentileIntensity = upper5thPercentileIntensity;
        
        if (options.ShouldPlot)
            PlotCircleOnTop([centerX centerY], pointRadius, 'blue', 2);
        end
        1;
        
        %% Determine first direction to walk towards
        
        % Generate a polar grid
        r = linspace(0, optimizedPointBigRadius, round(optimizedPointBigRadius / 0.5));
        theta = linspace(0, 2*pi, 73);
        theta(end) = []; % Remove the last point
        
        % Sample the image on a polar grid
        [R, Theta] = meshgrid(r, theta);
        [X, Y] = pol2cart(Theta, R);
        X = X + centerX;
        Y = Y + centerY;
        %which = interp2(mask, X, Y);
        imagePart = interp2(imageWithNans, X, Y);
        whichToExclude = isnan(imagePart);
        imagePart(whichToExclude) = 0; % TODO: Rectify this bad solution for masked-out pixels
        % imagePart(whichToExclude) = [];
        % X(whichToExclude) = [];
        % Y(whichToExclude) = [];
        % R(whichToExclude) = [];
        % Theta(whichToExclude) = [];
        
        % Find direction with maximal intensity (after some smoothing)
        intensityPerAngle = sum(imagePart, 2)';
        intensityPerAngle = [intensityPerAngle intensityPerAngle]; % Give the overlap a chance
        intensityPerAngle = conv(intensityPerAngle, gausswin(13), 'same');
        [~, idx] = max(intensityPerAngle);
        theta = [theta, theta];
        theta = theta(idx);
        
        % Set the current parameters
        prevPoint = [centerX centerY];
        AddMarkedPoint(prevPoint, pointRadius);
        walkStartIndex = size(points, 1);
        firstStepAngle = theta;
        prevStepAngle = theta;
        
        %% Walk the selected peak
        
        stepNum = 0;
%         breakAtStepNum = 20; % For debug
        
        for direction = [1, -1]
            if (direction == -1)
                prevPoint = points(walkStartIndex, :);
                theta = AngleAdd(firstStepAngle, pi); % Reverse direction
                prevStepAngle = theta;
            end
            
            % Try a radii and step sizes in decreasing order
            for pointRadiusIndex = 1:numel(options.OptimizedPointRadius)
                pointRadius = options.OptimizedPointRadius(pointRadiusIndex);
                
                if (numel(options.NextPointStep) > 1)
                    nextPointStep = options.NextPointStep(pointRadiusIndex);
                else
                    nextPointStep = options.NextPointStep;
                end
                
                if (size(points, 1) == 1)
                    prevStepAngle = theta;
                end
                
                [optimizedPoint, stepAngle, lower5thPercentileIntensity, upper5thPercentileIntensity, maxIntensity] = ...
                    OptimizeNextPoint(prevStepAngle, prevPoint, pointRadius, nextPointStep);
                
                if (isempty(optimizedPoint) || ClosestExistingPoint(optimizedPoint) < (nextPointStep * 0.999))
                    continue; % Stop the walk in this direction
                end
                
                while (~isempty(optimizedPoint) && ClosestExistingPoint(optimizedPoint) >= (nextPointStep * 0.999))
                    [upper5thPercentileIntensity / lower5thPercentileIntensity upper5thPercentileIntensity / firstMarkedUpper5thPercentileIntensity]
                    if (upper5thPercentileIntensity / lower5thPercentileIntensity < 1.3 || ... % Not enough above background?
                        upper5thPercentileIntensity / firstMarkedUpper5thPercentileIntensity < 0.5) % Intensity decreased to much relative to starting point?
                        break; % Stop the walk in this direction
                    end
                    
                    AddMarkedPoint(optimizedPoint, pointRadius);
                    stepNum = stepNum + 1;
                    
%                     if (stepNum == breakAtStepNum)
%                         1;
%                     end
                    
                    prevPoint = optimizedPoint;
                    prevStepAngle = stepAngle;
                    
                    [optimizedPoint, stepAngle, lower5thPercentileIntensity, upper5thPercentileIntensity, maxIntensity] = ...
                        OptimizeNextPoint(prevStepAngle, prevPoint, pointRadius, nextPointStep);
                end
            end
        end
    end

%% Cover the conic with small circles centered on the currently calibrated
%  conic and optimize position along the normal to the conic
if (1)
end

    function AddMarkedPoint(point, pointRadius)
        points(end+1, :) = point;
        pointsSize(end+1, :) = pointRadius;
        
        if (options.ShouldPlot && options.ShouldAnimate)
            PlotCircleOnTop(point, pointRadius, 'red', 2);
            pause(0.01);
        end
        
        coarseGridCol = 2 + floor(point(1) / coarseGridCellWidth);
        coarseGridRow = 2 + floor(point(2) / coarseGridCellHeight);
        
        coarsePointsMap{coarseGridRow, coarseGridCol} = [coarsePointsMap{coarseGridRow, coarseGridCol}; point];
    end

    function [nearbyPoints, distances] = GetNearbyPoints(point)
        coarseGridCol = 2 + floor(point(1) / coarseGridCellWidth);
        coarseGridRow = 2 + floor(point(2) / coarseGridCellHeight);
        
        colsToGet = coarseGridCol + kron([-1 0 1], [1; 1; 1]);
        rowsToGet = coarseGridRow + kron([-1 0 1]', [1, 1, 1]);
        
        indexesToGet = sub2ind(size(coarsePointsMap), rowsToGet(:), colsToGet(:));
        nearbyPoints = vertcat(coarsePointsMap{indexesToGet});
        
        if (~isempty(nearbyPoints))
            distances = sqrt(sum(bsxfun(@minus, nearbyPoints, point) .^ 2, 2));
            [distances, order] = sort(distances);
            nearbyPoints = nearbyPoints(order, :);
        else
            distances = [];
        end
    end

    function [distance, closePoint] = ClosestExistingPoint(point)
        [nearbyPoints, distances] = GetNearbyPoints(point);
        
        if (~isempty(nearbyPoints))
            distance = distances(1);
            closePoint = nearbyPoints(1, :);
        else
            distance = inf;
            closePoint = [];
        end
    end

    function [optimizedPoint, stepAngle, lower5thPercentileIntensity, upper5thPercentileIntensity, maxIntensity] = ...
            OptimizeNextPoint(initialTheta, prevPoint, pointRadius, nextPointStep)
        MaxMovement = options.CircleOptimizationMaxMovement; % pixels
        MaxIterations = options.CircleOptimizationMaxIterations;
        MinChange = options.CircleOptimizationMinChange;
        
        lower5thPercentileIntensity = [];
        upper5thPercentileIntensity = [];
        maxIntensity = [];
        
        [nextPointX, nextPointY] = pol2cart(initialTheta, nextPointStep);
        optimizedPoint = prevPoint + [nextPointX, nextPointY];
        
        if (0 && options.ShouldPlot && options.ShouldAnimate)
            PlotCircleOnTop(optimizedPoint, pointRadius, 'green', 1);
        end
        
        PointBeforeOptimization = optimizedPoint;
        stepAngle = initialTheta;
        
        %% Optimized selected angle
        for i = 1:MaxIterations
            if (0 && options.ShouldPlot && options.ShouldAnimate)
                PlotCircleOnTop(optimizedPoint, pointRadius, 'green', 1);
            end
            
            % Sample circle on image
            [imagePart, X, Y, which] = SampleImageAtCircle(imageWithNans, [], optimizedPoint, pointRadius, 0.25, 1);
            whichMaskedOut = isnan(imagePart);

            % Extend the masked out pixels to the symmetric counterparts to
            % remove any possible bias
            whichMaskedOut = whichMaskedOut | whichMaskedOut';
            
            imagePart = imagePart(which);
            X = X(which);
            Y = Y(which);
            whichMaskedOut = whichMaskedOut(which);
            
            maskedOutPortion = nnz(whichMaskedOut) / numel(imagePart);
            
            if (maskedOutPortion > MaxPortionOfMaskedPixels)
                optimizedPoint = [];
                return;
            else
                imagePart(whichMaskedOut) = [];
                X(whichMaskedOut) = [];
                Y(whichMaskedOut) = [];
            end
            
            % Calculate angle per sampled position
            X = X - prevPoint(1);
            Y = Y - prevPoint(2);
            Theta = cart2pol(X, Y);
            
            % This avoids zero-crossing issues
            Theta = AngleDiff(Theta, stepAngle);
            
            % Calculate weighed-mean of angle to adjust
            sumOfImagePart = sum(imagePart(:));
            weighedMeanTheta = (Theta(:)' * imagePart(:)) / sumOfImagePart;
            stepAngle = stepAngle + weighedMeanTheta;
            
            [nextPointX, nextPointY] = pol2cart(stepAngle, nextPointStep);
            prevIterationOptimizedPoint = optimizedPoint;
            optimizedPoint = prevPoint + [nextPointX, nextPointY];
            
            wasChangeThresholdMet = norm(prevIterationOptimizedPoint - optimizedPoint) < MinChange;
            
            % Check that there is enough change to justify continuing
            if (wasChangeThresholdMet)
                break;
            end
            
            if (0 && options.ShouldPlot && options.ShouldAnimate)
                pause(0.01);
            end
        end
        
        lower5thPercentileIntensity = Percentile(imagePart, 0.05);
        upper5thPercentileIntensity = Percentile(imagePart, 0.95);
        maxIntensity = max(imagePart);
    end

    detailsResults.AllPoints = points;
    detailsResults.AllPointsSize = pointsSize;
    detailsResults.AddedPoints = points(numOfPreviousPoints+1:end, :);
    detailsResults.AddedPointsSize = pointsSize(numOfPreviousPoints+1:end);

end
