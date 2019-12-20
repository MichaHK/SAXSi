function [controlX, controlY] = FitConicToNearbyPeak2d(options, image, mask, controlX, controlY)
% [result] = FitConicToNearbyPeak2d(options, image, mask, x, y)
%

if (1)
    if (nargin == 0 && nargout == 0)
        load([mfilename '-state']);
    else
        save([mfilename '-state']);
    end
end

persistent calibrationTools;

if (0)
    if (isempty(calibrationTools))
        NET.addAssembly('C:\Files\The Lab (Synced)\Code\SAXSi Dev\SAS.Calibration\SAS.Calibration.Bridge\bin\Debug\SAS.Calibration.Bridge.dll');
        calibrationTools = SAS.Calibration.Bridge.CalibrationTools;
        %calibrationTools.Calibration2dScore(0, 0, 0);
    end
end

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

lambda = 1.543;
twoK = 4 * pi / lambda;
q = 0.1075;
twoTheta = 2 * asin(q / twoK);
optimizedCalibration = CalibrationFromConic(conic, twoTheta);

initialParameters = [deg2rad(-0.168) 2440.68 / 0.172 156.1086 523.0974 deg2rad(0.000941)];
CalibrationParametersScore(initialParameters);
[bestParameters, fval, exitflag, output] = fminsearch(@CalibrationParametersScore, initialParameters);
1;


controlPoints = [controlX(:), controlY(:)];
[bestControlPoints] = fminsearch(@(p)ConicControlPointsToScore(p(1:end/2), p(end/2+1:end)), ...
    controlPoints(:));
controlX = bestControlPoints(1:end/2);
controlY = bestControlPoints(end/2+1:end);

1;

    function [score] = ConicControlPointsToScore(controlX, controlY)
        % Given the control points, construct a conic
        lambda = 1.543;
        twoK = 4 * pi / lambda;
        q = 0.1075;
        sigma = 0.002;
        threeSigma = sigma * 3;
        inverseSigma = 1.0 / sigma;
        twoTheta = 2 * asin(q / twoK);
        optimizedConic = ConicClass();
        optimizedConic.SetSolutionOf5Points(controlX, controlY);
        
        % Translate conic to calibration parameters
        calibration = CalibrationFromConic(optimizedConic, twoTheta);
        
        if (1)
            d = calibration.SampleToDetector;
            alpha = calibration.Alpha;
            beta = calibration.Beta;
            [Xd,Yd]=find_Direct_Beam_conX(...
                calibration.BeamX,...
                calibration.BeamY, beta);
            
            fourPiOverLamda=12.56637061435917/lambda;
            
            %%%%%% calculate matries %%%%%%%
            N = size(image, 2);
            M = size(image, 1);
            [xx,yy]=meshgrid(1:N,1:M);
            
            XX=Xd+xx*cos(beta)-yy*sin(beta);
            YY=Yd-xx*sin(beta)-yy*cos(beta);
            
            clear xx; clear yy;
            
            xx=YY*cos(alpha);
            yy=-XX;
            zz=d/cos(alpha)-YY*sin(alpha);
            
            Dist=sqrt(xx.^2+yy.^2+zz.^2);
            imageToQMatrix = (fourPiOverLamda*sin(0.5.*acos(zz./Dist)));
            weightMatrix = zeros(size(imageToQMatrix));
            which = mask & (abs(imageToQMatrix - q) < threeSigma);
            %weightMatrix(which) = exp(- (imageToQMatrix(which) .* inverseSigma) .^ 2)
            
            %score = -(weightMatrix .* image .* inclusionMask);
            
            % 2013-03-24
            %score = -sum(image(which) .* exp(- ((imageToQMatrix(which) - q) .* inverseSigma) .^ 2));
            
            Lorentzian = @(x, xc, A, w)((A * w^2) ./ ((x - xc).^2 + w^2));
            
            comparedImage = Lorentzian(imageToQMatrix, q, 1, 0.0033);
            A = median(comparedImage(which) ./ image(which));
            
            diffImage = image - (A .* comparedImage);
            score = sumsqr(diffImage(which));
        end
        
        1;
        
        %p = [calibration.SampleToDetector calibration.BeamX-1 calibration.BeamY-1 calibration.Alpha calibration.Beta];
        %         score = -calibrationTools.Calibration2dScore(...
        %             p, image, mask);
    end


    function [score] = CalibrationParametersScore(parameters)
        
        d = parameters(2);
        alpha = parameters(1);
        beta = parameters(5);
        [Xd,Yd]=find_Direct_Beam_conX(...
            parameters(3),...
            parameters(4), beta);
        
        lambda = 1.543;
        twoK = 4 * pi / lambda;
        q = 0.1075;
        sigma = 0.002;
        threeSigma = sigma * 3;
        inverseSigma = 1.0 / sigma;
        twoTheta = 2 * asin(q / twoK);
        
        fourPiOverLamda=12.56637061435917/lambda;
        
        %%%%%% calculate matries %%%%%%%
        N = size(image, 2);
        M = size(image, 1);
        [xx,yy]=meshgrid(1:N,1:M);
        
        XX=Xd+xx*cos(beta)-yy*sin(beta);
        YY=Yd-xx*sin(beta)-yy*cos(beta);
        
        clear xx; clear yy;
        
        xx=YY*cos(alpha);
        yy=-XX;
        zz=d/cos(alpha)-YY*sin(alpha);
        
        Dist=sqrt(xx.^2+yy.^2+zz.^2);
        imageToQMatrix = (fourPiOverLamda*sin(0.5.*acos(zz./Dist)));
        weightMatrix = zeros(size(imageToQMatrix));
        which = mask & (abs(imageToQMatrix - q) < threeSigma);
        %weightMatrix(which) = exp(- (imageToQMatrix(which) .* inverseSigma) .^ 2)
        
        %score = -(weightMatrix .* image .* inclusionMask);
        
        % 2013-03-24
        %score = -sum(image(which) .* exp(- ((imageToQMatrix(which) - q) .* inverseSigma) .^ 2));
        
        Lorentzian = @(x, xc, A, w)((A * w^2) ./ ((x - xc).^2 + w^2));
        
        comparedImage = Lorentzian(imageToQMatrix, q, 1, 0.0033);
        %A = median(comparedImage(which) ./ image(which));
        A = 63.6;
        
        diffImage = image - (A .* comparedImage);
        if (0)
            figure(2); imagesc(diffImage .* which);
        end
        
        weights = log(comparedImage * 1e3);
        weights(weights < 0) = 0;
        
        score = sum((diffImage(which) .^ 2) .* weights(which)) / sum(weights(which));
        %score = -mean(image(which) .* comparedImage(which));
        
        % Calculate power-law from the center
        [~, centerRow, centerCol] = MinRowCol(imageToQMatrix);
        wherePowerLaw = (imageToQMatrix < (q/3)) & mask;
        
        q1 = q / 10;
        q2 = q / 2;
        
        pixels1 = ((imageToQMatrix > q1) & (imageToQMatrix < q1 * 1.1));
        pixels2 = ((imageToQMatrix > q2) & (imageToQMatrix < q2 * 1.1));

        meanVal1 = mean(image(pixels1 & mask));
        meanVal2 = mean(image(pixels2 & mask));
        
        powerLawPower = (log(meanVal2) - log(meanVal1)) / (log(q2) - log(q1));

        I0 = exp(log(meanVal1) - powerLawPower * log(q1));
        divImage = (log(image) - log(I0)) ./ log(imageToQMatrix);
        
        powerLawPower = mean(divImage(wherePowerLaw));
        meanVal1 = mean(image(pixels1 & mask));
        I0 = exp(log(meanVal1) - powerLawPower * log(q1));

        powerLawImage = I0 * (imageToQMatrix .^ powerLawPower);
        diffImage = image - powerLawImage;
        score = score + mean(diffImage(wherePowerLaw) .^ 2);
        
    end

end