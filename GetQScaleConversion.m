function [conversionFunc, description] = GetQScaleConversion(DisplayOptions, CalibrationData)
switch (DisplayOptions.Displayed1dScaleType)
    case 1
        conversionFunc = @(q)q; % Scale in A^-1
        description = 'Momentum Transfer (A^-1)';
    case 2
        conversionFunc = @(q)q*10; % Scale in nm^-1
        description = 'Momentum Transfer (nm^-1)';
    case 3
        conversionFunc = @(q)(2 * pi()) ./ q; % Scale in A
        description = 'Real spacing (A)';
    case 4
        conversionFunc = @(q)(0.2 * pi()) ./ q; % Scale in nm
        description = 'Real spacing (nm)';
    case 5
        conversionFunc = @(q)CalibrationData.GetTwoThetaDegreesForQ(q); % Scale in nm
        description = '2Theta Angle (Degrees)';
    otherwise
        conversionFunc = @(q)q; % Do nothing
        description = 'Momentum Transfer (A^-1)';
end
end
