function [calibration] = CalibrationFromPoints(x, y, twoTheta, options)
% [calibration] = CalibrationFromPoints(x, y, twoTheta, initialParams)

% TODO: Make this code handle multiple "twoTheta" and multiple lines of XY

if (~exist('options', 'var') || isempty(options))
    options = struct();
    options.ShouldFitWithoutTiltFirst = 1;
    options.ShouldFitTilt = 1;
    options.DoNotChangeBeamCenter = 0;
    
    options.InitialBeamCenterX = [];
    options.InitialBeamCenterY = [];
    options.InitialAlpha = 0;
    options.InitialBeta = 0;
    options.InitialSample2DetectorDist = [];
    
    if (nargin == 0 && nargout == 1)
        calibration = options;
        return;
    end
end

calibration = [];

count = min(numel(x), numel(y));
switch count
    case 0
        return;
    case 1
        options.ShouldFitTilt = 0;
    case {2, 3, 4}
        options.DoNotChangeBeamCenter = 1;
    otherwise
end

if (count < 5 && (isempty(options.InitialBeamCenterX) || isempty(options.InitialBeamCenterY)))
    ME = MException('CalibrationFromPoints:BadInput', ...
        'Cannot fit less than 5 points without a given center');
    throw(ME);
end

%% Initialize as if the conic was simply a circle
% Code modified from CONEX

alpha = options.InitialAlpha(1);
beta = options.InitialBeta(1);

if (isempty(options.InitialBeamCenterX) || isempty(options.InitialBeamCenterY)) % Must specify both
    centerX = mean(x);
    centerY = mean(y);
    
    bestGuessedCenter = GuessCenterFromAssuminglyRadialPoints(x, y);
    centerX = bestGuessedCenter(1);
    centerY = bestGuessedCenter(2);
else
    centerX = options.InitialBeamCenterX(1);
    centerY = options.InitialBeamCenterY(1);
end

if (isempty(options.InitialSample2DetectorDist))
    radii = sqrt([x-centerX] .^ 2 + [y-centerY] .^ 2);
    radiusGuess = mean(radii);
    
    sample2DetDist = radiusGuess / sin(twoTheta);
    %sample2DetDist = radiusGuess / twoTheta; % This was in the original code
else
    sample2DetDist = options.InitialSample2DetectorDist(1);
end

[beamX, beamY] = find_Direct_Beam_conX(centerX, centerY, beta);
initialParams = [alpha sample2DetDist beamX beamY beta];

% The "sumabs" mimics the old minimization and at least for one image generates
% the correct calibration while "sumsqr" doesn't.
%ErrorSummationFunc = @sumsqr;
ErrorSummationFunc = @sumabs;

%% Fit the calibration parameters to the given points, without tilt
if (options.ShouldFitWithoutTiltFirst)
    if (options.DoNotChangeBeamCenter)
        finalParams = fminsearch(@(params)ErrorSummationFunc(GetTwoThetaForXYInRadians([0 params beamX beamY 0], x, y) - twoTheta), ...
            [sample2DetDist]);
    else
        finalParams = fminsearch(@(params)ErrorSummationFunc(GetTwoThetaForXYInRadians([0 params 0], x, y) - twoTheta), ...
            [sample2DetDist beamX beamY]);

        beamX = finalParams(2);
        beamY = finalParams(3);
    end
    
    sample2DetDist = finalParams(1);
end

%% Fit the calibration parameters to the given points
if (options.ShouldFitTilt)
    if (options.DoNotChangeBeamCenter)
        finalParams = fminsearch(@(params)ErrorSummationFunc(GetTwoThetaForXYInRadians([params(1:2) beamX beamY params(3)], x, y) - twoTheta), ...
            [alpha sample2DetDist beta]);
        beta = finalParams(3);
    else
        finalParams = fminsearch(@(params)ErrorSummationFunc(GetTwoThetaForXYInRadians(params, x, y) - twoTheta), ...
            [alpha sample2DetDist beamX beamY beta]);
        beamX = finalParams(3);
        beamY = finalParams(4);
        beta = finalParams(5);
    end
    
    alpha = finalParams(1);
    sample2DetDist = finalParams(2);
end

%% Construct the result structure
calibration = struct();
calibration.ParametersVector = [alpha sample2DetDist beamX beamY beta];
calibration.Alpha = alpha;
calibration.Beta = beta;
calibration.SampleToDetector = sample2DetDist;
[beamX, beamY] = find_Direct_Beam(beamX, beamY, calibration.Beta);
calibration.BeamX = beamX;
calibration.BeamY = beamY;

finalConic = ConicClass();
finalConic.SetConexParameters(alpha, sample2DetDist, beamX, beamY, beta, twoTheta);
calibration.FinalConic = finalConic;

end
