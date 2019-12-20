function [adjustedX, adjustedY] = FitPowerLaw2d(options, image, mask)

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
    options.MinMoveSize = 0.01;
    options.MaxMoveSize = 2;
    options.RelativeChangeThresholdToStop = 0.001;
    options.Alpha = 0;
    options.Beta = 0;
    options.SampleDetectorDist = 1;
    options.WavelengthAngstrom = 1;
    options.MinQ = 0;
    options.MaxQ = 1;
    options.InitialBeamX = 0;
    options.InitialBeamY = 0;
    
    adjustedX = options;
    return;
end

if (isempty(mask))
    mask = double(~isnan(image) & (image >= 0));
end
image(~mask) = 0;

BeamCenterScore([options.InitialBeamX options.InitialBeamY]);
[bestCenter, fval, exitflag, output] = fminsearch(@BeamCenterScore, [options.InitialBeamX options.InitialBeamY]);

adjustedX = bestCenter(1);
adjustedY = bestCenter(2);
1;

    function [score] = BeamCenterScore(beamCenter)
        
        d = options.SampleDetectorDist;
        alpha = options.Alpha;
        beta = options.Beta;
        [Xd,Yd]=find_Direct_Beam_conX(...
            beamCenter(1),...
            beamCenter(2), beta);
        
        lambda = options.WavelengthAngstrom;
        twoK = 4 * pi / lambda;
        
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
        imageToQMatrix = (twoK*sin(0.5.*acos(zz./Dist)));


        % Calculate power-law from the center
        [~, centerRow, centerCol] = MinRowCol(imageToQMatrix);
        wherePowerLaw = ((imageToQMatrix >= options.MinQ) & (imageToQMatrix <= options.MaxQ)) & mask;
        
        q1 = options.MinQ;
        q2 = options.MaxQ;
        
        pixels1 = ((imageToQMatrix > q1) & (imageToQMatrix < q1 * 1.1));
        pixels2 = ((imageToQMatrix > q2 * 0.9) & (imageToQMatrix < q2));

        meanVal1 = mean(image(pixels1 & mask));
        meanVal2 = mean(image(pixels2 & mask));
        
        powerLawPower = (log(meanVal2) - log(meanVal1)) / (log(q2 * 0.95) - log(q1 * 1.05));

        I0 = exp(log(meanVal1) - powerLawPower * log(q1));
        divImage = (log(image) - log(I0)) ./ log(imageToQMatrix);
        
        powerLawImage = I0 * (imageToQMatrix .^ powerLawPower);
        diffImage = image - powerLawImage;
        score = mean(diffImage(wherePowerLaw) .^ 2);
        
    end




end
