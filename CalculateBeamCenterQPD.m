function [curves] = CalculateBeamCenterQPD(image, originalCalibrationData, ...
    originalIntegrationParams, FastIntegrationCache, center)

IntegrationParams = IntegrationParamsClass();
IntegrationParams.CopyFrom(originalIntegrationParams);
originalMask = IntegrationParams.MaskBitmap;

CalibrationData = CalibrationDataClass();
CalibrationData.CopyFrom(originalCalibrationData);

if (~exist('center', 'var') || isempty(center))
    center = [CalibrationData.BeamCenterX CalibrationData.BeamCenterY];
end

CalibrationData.BeamCenterX = center(1);
CalibrationData.BeamCenterY = center(2);

%%
x = [1:size(image, 2)] - center(1);
y = [1:size(image, 1)] - center(2);

%figure(2);
%imagesc(x, y, image);

%
[X, Y] = meshgrid(x, y);

if (0)
    %%
    mask1 = (X < 0 & Y < 0) & originalMask;
    mask2 = (X >= 0 & Y < 0) & originalMask;
    mask3 = (X >= 0 & Y >= 0) & originalMask;
    mask4 = (X < 0 & Y >= 0) & originalMask;
else
    mask1 = (X < 0) & originalMask;
    mask2 = (X >= 0) & originalMask;
    mask3 = (Y < 0) & originalMask;
    mask4 = (Y >= 0) & originalMask;
    %imagesc(mask3)
end

IntegrationParams.MaskBitmap = mask1;
[integrated1] = IntFast(image, CalibrationData, IntegrationParams, FastIntegrationCache);
%integrated1.QpdSegment = [-1 -1];
integrated1.QpdSegment = [-1 0];

IntegrationParams.MaskBitmap = mask2;
[integrated2] = IntFast(image, CalibrationData, IntegrationParams, FastIntegrationCache);
%integrated2.QpdSegment = [1 -1];
integrated2.QpdSegment = [1 0];

IntegrationParams.MaskBitmap = mask3;
[integrated3] = IntFast(image, CalibrationData, IntegrationParams, FastIntegrationCache);
%integrated3.QpdSegment = [1 1];
integrated3.QpdSegment = [0 -1];

IntegrationParams.MaskBitmap = mask4;
[integrated4] = IntFast(image, CalibrationData, IntegrationParams, FastIntegrationCache);
%integrated4.QpdSegment = [-1 1];
integrated4.QpdSegment = [0 1];

curves = [integrated1 integrated2 integrated3 integrated4];

end
