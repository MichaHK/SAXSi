
if (0)
%%
load('c:\Files\The Lab\Code\SAXSi sample images\calibration 20170714 adjusted mask, adjusted wavelength, adjusted center.sxs', '-mat');

originalMask = IntegrationParams.MaskBitmap;

%%
image = read2D('c:\Files\The Lab\Code\SAXSi sample images\b21-373419-Pilatus2M.h5');
end

%%
FastIntegrationCache = FastIntegrationCacheClass();

CalibrationData.BeamCenterX = 753.63;
CalibrationData.BeamCenterY = 137.31;

%CalibrationData.BeamCenterX = 754.4;
%CalibrationData.BeamCenterY = 141;

IntegrationParams.QMin = 0.0055; % A^-1
%IntegrationParams.QMax = 0.032; % A^-1
IntegrationParams.QMax = 0.015; % A^-1
IntegrationParams.QStepsCount = 50;

[integrated] = IntFast(image, CalibrationData, IntegrationParams, FastIntegrationCache);

%
figure(2);
loglog(integrated.Q, integrated.I);

%%
stepDirections = [1 0; -1 0; 0 1; 0 -1];
stepSize = 1;

bestDirectionIndex = [];
bestDirectionScore = [];

%%
center = [CalibrationData.BeamCenterX CalibrationData.BeamCenterY];

CalibrationData.BeamCenterX = center(1);
CalibrationData.BeamCenterY = center(2);
[integrated] = IntFast(image, CalibrationData, IntegrationParams, FastIntegrationCache);
s = sqrt(integrated.N(1:end-1)) .* integrated.IErr;
currentScore = mean(s)

%%

for stepSize = [1 0.5 0.25 0.1 0.05]
    display(sprintf('StepSize: %f', stepSize));
    
    %%
    for i = 1:10
        %%
        display('step');
        
        score = zeros(1, 4);
        for directionIndex = 1:4
            CalibrationData.BeamCenterX = center(1) + stepSize * stepDirections(directionIndex, 1);
            CalibrationData.BeamCenterY = center(2) + stepSize * stepDirections(directionIndex, 2);
            
            [integrated] = IntFast(image, CalibrationData, IntegrationParams, FastIntegrationCache);
            s = sqrt(integrated.N(1:end-1)) .* integrated.IErr;
            score(directionIndex) = mean(s)
        end
        
        [bestDirectionScore, bestDirectionIndex] = min(score);
        %%
        if (currentScore < bestDirectionScore)
            break;
        end
        
        %%
        currentScore = bestDirectionScore;
        center = center + stepSize * stepDirections(bestDirectionIndex, :)
    end
end

%%

maximalStep = 1;

stepSize21 = maximalStep*tanh(-mean(d21));
stepSize43 = maximalStep*tanh(-mean(d43));

step = stepSize21 * vec21 + stepSize43 * vec43

%
CalibrationData.BeamCenterX = CalibrationData.BeamCenterX + step(1);
CalibrationData.BeamCenterY = CalibrationData.BeamCenterY + step(2);
[CalibrationData.BeamCenterX CalibrationData.BeamCenterY]

