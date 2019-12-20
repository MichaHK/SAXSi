function [controlX, controlY] = FitConicToNearbyPeak(options, image, mask, controlX, controlY)
% [result] = FitConicToNearbyPeak(options, image, mask, x, y)
%

if (nargin == 0 && nargout == 1)
    controlX = struct();
    controlX.MaxIterations = 1000;
    controlX.MinMoveSize = 0.01;
    controlX.MaxMoveSize = 2;
    controlX.RelativeChangeThresholdToStop = 0.001;
    controlX.NumberOfPointsOnConic = 1000;
    return;
end



conic = ConicClass();
conic.SetSolutionOf5Points(controlX, controlY);

if (1)
    DebugPlotImageWithConic(image, [controlX(:), controlY(:)], conic);
    %DebugPlotImageWithConic(image ./ mask, [controlX(:), controlY(:)], conic);
    %ginput(1);
end

N = options.NumberOfPointsOnConic;
[values, x, y] = GetValuesOnConic(image, conic, N);
maskValues = GetValuesOnConic(mask, conic, N);

remove = isnan(values) | isnan(maskValues) | maskValues < (1 - 1e-6);
values(remove) = [];
maskValues(remove) = [];
x(remove) = [];
y(remove) = [];

values = values ./ maskValues;


%% Experimental
[gradX, gradY] = gradient(image);
gradientX = interp2(gradX, x, y);
gradientY = interp2(gradY, x, y);


gradXValues = GetValuesOnConic(gradX, conic, N);
gradYValues = GetValuesOnConic(gradY, conic, N);
gradXValues(remove) = [];
gradYValues(remove) = [];

gradientMagnitude = sqrt(gradXValues .^ 2 + gradYValues .^ 2);
[~, steepestIndex] = max(gradientMagnitude);
%[x(steepestIndex) y(steepestIndex)]

halfMaxValue = 0.5 * max(values);
twoMaxValue = 2.0 * max(values);
%currentScore = sum(gradientMagnitude) / (1 - sum(values < halfMaxValue | values > twoMaxValue) / numel(values));
currentScore = -mean(values);

%% Randomly try to find a combined move to minimize the gradient
bestScore = currentScore;
bestMoveX = [];
bestMoveY = [];

roundMoveMax = options.MaxMoveSize ./ [1, 2, 4];
roundMoveMin = max([roundMoveMax ./ 2; kron(options.MinMoveSize, [1 1 1])], [], 1);
roundMoveMin(3) = options.MinMoveSize;
roundMoveRanges = roundMoveMax - roundMoveMin;
roundMoveTrials = [7 7 7];
roundMoves = [25 20 15];

s = size(controlX);

for round = 1:numel(roundMoveTrials)
    
    for move = 1:roundMoves(round)
        
        conic = ConicClass();
        conic.SetSolutionOf5Points(controlX, controlY);
        
        if (1)
            if (~exist('imageForDisplay', 'var'))
                imageForDisplay = image;
                imageForDisplay(mask < 0.999) = nan;
            end
            
            DebugPlotImageWithConic(imageForDisplay, [controlX(:), controlY(:)], conic);
        end
        
        for trial = 1:roundMoveTrials(round)
            moveSize = rand(s) .* roundMoveRanges(round) + roundMoveMin(round);
            moveAngle = rand(s) .* (2 * pi);
            moveX = rand(s) .* sin(moveAngle) .* moveSize;
            moveY = rand(s) .* cos(moveAngle) .* moveSize;
            
            trialConic = ConicClass();
            trialConic.SetSolutionOf5Points(controlX + moveX, controlY + moveY);
            
            [values] = GetValuesOnConic(image, trialConic, N);
            maskValues = GetValuesOnConic(mask, trialConic, N);
            %gradXValues = GetValuesOnConic(gradX, trialConic, N);
            %gradYValues = GetValuesOnConic(gradY, trialConic, N);
            
            remove = isnan(values) | isnan(maskValues) | maskValues < (1 - 1e-6);
            values(remove) = [];
            %gradXValues(remove) = [];
            %gradYValues(remove) = [];
            %gradientMagnitude = sqrt(gradXValues .^ 2 + gradYValues .^ 2);
            
            %score = sum(gradientMagnitude) / (1 - sum(values < halfMaxValue | values > twoMaxValue) / numel(values));

            %score = mean(values) / (1 - sum(values < halfMaxValue | values > twoMaxValue);
            score = -mean(values);
            
            if (bestScore > score)
                bestScore = score;
                bestMoveX = moveX;
                bestMoveY = moveY;
            end
        end
        
        if (~isempty(bestMoveX))
            controlX = controlX + bestMoveX;
            controlY = controlY + bestMoveY;
            display(sprintf('Made another move, in round %d', round));
            bestMoveX = [];
            bestMoveY = [];
        end
        
        %ginput(1);
    end
    
end


1;



end