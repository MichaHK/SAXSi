function [curve, xhiCurve, wasRead, fileNameActuallyRead] = readOrIntigrate (...
    filepath, GeneralOptions, CalibrationData, IntegrationParams, shouldReintegrate, ...
    FastIntegrationCache)

Thresholding = IntegrationParams.Threshold;
im = [];
q = [];
I = [];

wasRead = false;

[fileFolder, fileName, fileExt] = fileparts(filepath);

persistent loadingMethods;

if (IsExtensionOf1dCurve(fileExt))
    
    if (shouldReintegrate && GeneralOptions.ReintegrateTracesBackToImages)
        extensions = GetCommonImageExtensions();
        whichExist = logical(cellfun(@(ext)exist([fileFolder '\' fileName ext], 'file'), extensions));
        
        if (nnz(whichExist) > 1)
            error(['Traced back "' [fileName, fileExt] '" to more than one image...']);
        end
        
        fileExt = extensions{whichExist};
        filepath = [fileFolder filesep fileName fileExt];
        
        if (nnz(whichExist) == 0)
            error(['Could not trace back "' [fileName, fileExt] '" to any image.']);
        end
    else
        [curve, xhiCurve, wasRead] = Read1D(filepath);
    end
end

% Has to be here, in case of "retintegration traces back to images"
fileNameActuallyRead = [fileName fileExt];

if (wasRead)
    return;
end

if (IsExtensionOfImage(fileExt))
    
    fileWithoutExt = ReplaceFileExtension(filepath, '');

    if (~shouldReintegrate && GeneralOptions.ShouldLoadIntegratedFileInsteadOfIntegrating)
        try
            if (exist([fileWithoutExt, '.dat'], 'file'))
                [curve, xhiCurve, wasRead] = Read1D([fileWithoutExt, '.dat']);
                fileNameActuallyRead = [fileName, '.dat'];
            elseif (exist([fileWithoutExt, '.fsi'], 'file'))
                [curve, xhiCurve, wasRead] = Read1D([fileWithoutExt, '.fsi']);
                fileNameActuallyRead = [fileName, '.fsi'];
            end
        catch exception
            1;
        end
    end
    
    if (~wasRead)
        disp('started reading')
        im = read2D(filepath, true);
        
        im = squeeze(double(im));
        
        if (1 && ndims(im) == 3)
            im = squeeze(mean(double(im), 1));
        end
        
        %Thresholding=0;
        %disp('started intigrating.... please wait')

        if (ndims(im) == 2)
            [curve, xhiCurve] = Integrate(im, CalibrationData, IntegrationParams, FastIntegrationCache);
        elseif (ndims(im) == 3)
            for i = 1:size(im, 1)
                display(sprintf('%d/%d', i, size(im, 1)));
                
                [c, xhi] = Integrate(squeeze(im(i, :, :)), CalibrationData, IntegrationParams, FastIntegrationCache);
                curve(i) = c;
                xhiCurve(i) = xhi;
            end
        end

    end
end



