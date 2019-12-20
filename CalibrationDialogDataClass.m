classdef CalibrationDialogDataClass < handle

    properties
        Image = [];
        ImageMask = [];
        
        DisplayLogScale = 1;
        DisplayType = 1; % 1 - intensity, 2 - X gradient, 3 - X gradient, 4 - X+Y gradient, 5 - Laplacian
        Colormap = colormap('gray');
        ShowColorbar = 0;
        BlurSize = 0;
        
        IntensityMin = 0;
        IntensityMax = 0;
        DisplayedImageMin = 0;
        DisplayedImageMax = 0;
        
        DrawQ = [];
        DrawQColor = {};
        
        CalibrationStep = 0;

        ClickedXY = [0,0];
        ClickedProfileSigma = 1;
        ClickedProfileAngle = 0;
        SmoothedImage = [];
        SmoothedMask = [];
        
        WasCalibrationAccepted = 0;
        WasInitialCalibrationGiven = 0;
        
        ShouldAnimate = 1;
    end

end
