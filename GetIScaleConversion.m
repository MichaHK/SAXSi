function [conversionFunc, description] = GetIScaleConversion(DisplayOptions, CalibrationData)
switch (DisplayOptions.Displayed1dIntensityScaleType)
    case 1
        conversionFunc = @(I)I;
        description = '';
    case 2
        conversionFunc = @(I)I;
        description = '';
    otherwise
        conversionFunc = @(I)I;
        description = '';
end
end
