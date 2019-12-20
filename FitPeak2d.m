function [result] = FitPeak2d(options, image, mask, q, width, weight)
% [result] = FitPeak2d(options, image, mask, x, y)
%

if (1)
    if (nargin == 0 && nargout == 0)
        load([mfilename '-state']);
    else
        save([mfilename '-state']);
    end
end

if (nargin == 0 && nargout == 1)
    options = struct();
    options.MaxIterations = 1000;
    options.ShouldFitWithoutTiltFirst = 1;
    options.ShouldFitTilt = 1;
    options.DoNotChangeBeamCenter = 0;
    
    options.PeakAmplitude = 0;
    options.InitialBeamCenterX = 0;
    options.InitialBeamCenterY = 0;
    options.InitialAlpha = 0;
    options.InitialBeta = 0;
    options.InitialSample2DetectorDist = 1;
    options.TwoK = 1;
    
    result = options;
    return;
end

if (~exist('weight', 'var'))
    weight = (q .* 0) + 1;
end

if (isempty(mask))
    mask = double(~isnan(image) & (image >= 0));
end
image(~mask) = 0;


threeWidth = width * 3;
inverseWidth = 1.0 / width;
A = options.PeakAmplitude;
twoK = options.TwoK;
twoTheta = 2 * asin(q / twoK);
Lorentzian = @(x, xc, A, w)((A * w^2) ./ ((x - xc).^2 + w^2));

beamX = options.InitialBeamCenterX;
beamY = options.InitialBeamCenterY;
sample2DetDist = options.InitialSample2DetectorDist;
alpha = options.InitialAlpha;
beta = options.InitialBeta;

CalibrationParametersScore(options.InitialBeamCenterX, options.InitialBeamCenterY, ...
    options.InitialSample2DetectorDist, options.InitialAlpha, options.InitialBeta)

if (options.ShouldFitWithoutTiltFirst)
    if (options.DoNotChangeBeamCenter)
        finalParams = fminsearch(@(params)CalibrationParametersScore(beamX, beamY, params, 0, 0), ...
            [sample2DetDist]);
    else
        finalParams = fminsearch(@(params)CalibrationParametersScore(params(2), params(3), params(1), 0, 0), ...
            [sample2DetDist beamX beamY]);

        beamX = finalParams(2);
        beamY = finalParams(3);
    end
    
    sample2DetDist = finalParams(1);
end

%% Fit the calibration parameters to the given points
if (options.ShouldFitTilt)
    if (options.DoNotChangeBeamCenter)
        finalParams = fminsearch(@(params)CalibrationParametersScore(beamX, beamY, params(1), params(2), params(3)), ...
            [sample2DetDist alpha beta]);
    else
        finalParams = fminsearch(@(params)CalibrationParametersScore(params(4), params(5), params(1), params(2), params(3)), ...
            [sample2DetDist alpha beta beamX beamY]);
        beamX = finalParams(4);
        beamY = finalParams(5);
    end
    
    sample2DetDist = finalParams(1);
    alpha = finalParams(2);
    beta = finalParams(3);
    
    CalibrationParametersScore(beamX, beamY, ...
        sample2DetDist, alpha, beta)

end

result.Alpha = alpha;
result.Beta = beta;
result.SampleToDetDist = sample2DetDist;
result.BeamX = beamX;
result.BeamY = beamY;
1;

    function [score] = CalibrationParametersScore(beamCenterX, beamCenterY, sampleToDetDist, alpha, beta)
        
        [Xd,Yd]=find_Direct_Beam_conX(...
            beamCenterX,...
            beamCenterY, beta);
        
        %%%%%% calculate matries %%%%%%%
        N = size(image, 2);
        M = size(image, 1);
        [xx,yy]=meshgrid(1:N,1:M);
        
        XX=Xd+xx*cos(beta)-yy*sin(beta);
        YY=Yd-xx*sin(beta)-yy*cos(beta);
        
        clear xx; clear yy;
        
        xx=YY*cos(alpha);
        yy=-XX;
        zz=sampleToDetDist/cos(alpha)-YY*sin(alpha);
        
        Dist = sqrt(xx.^2+yy.^2+zz.^2);
        imageToQMatrix = (twoK * sin(0.5.*acos(zz./Dist)));
        weightMatrix = zeros(size(imageToQMatrix));
        which = mask & (abs(imageToQMatrix - q) < threeWidth);
        
        comparedImage = Lorentzian(imageToQMatrix, q, 1, 0.0033);
        
        diffImage = image - (A .* comparedImage);
        if (0)
            figure(2); imagesc(diffImage .* which);
        end
        
        weights = log(comparedImage * 1e3);
        weights(weights < 0) = 0;
        
        score = sum((diffImage(which) .^ 2) .* weights(which)) / sum(weights(which));
        %score = -mean(image(which) .* comparedImage(which));
    end

end
