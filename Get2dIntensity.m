function [image] = Get2dIntensity(image, displayOptions)
    
    switch(displayOptions.Display2dLogarithmic)
        case 1
            logScaleFunc = @(x)log10(x .* (x >= 0) + 1);
        otherwise
            logScaleFunc = @(x)x;
    end
    
    switch(displayOptions.Display2dType)
        case 1
            postProcessFunc = @(x)GradientImageFunc(x);
        case 2
            postProcessFunc = @(x)log10(GradientImageFunc(x));
        otherwise
            postProcessFunc = @(x)x;
    end
    
    image = double(image);
    image = postProcessFunc(logScaleFunc(image));
    
    function [image] = GradientImageFunc(image)
        [gX, gY] = gradient(image);
        image = abs(gX) + abs(gY); % "abs", otherwise they might "destructively interfere"
    end

end
