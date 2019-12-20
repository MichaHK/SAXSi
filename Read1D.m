function [curve, xhiCurve, wasRead] = Read1D (filepath, shouldAddFilenameToCurve)

if (~exist('shouldAddFilenameToCurve', 'var'))
    shouldAddFilenameToCurve = 0;
end

curve = struct('Q', [], 'I', [], 'IErr', [], 'QScale', 'A');
xhiCurve = struct('Angle', [1:360], 'I', [1:360] .* 0, 'IErr', [1:360] .* 0);

wasRead = false;

[fileFolder, fileName, fileExt] = fileparts(filepath);

if (shouldAddFilenameToCurve)
    curve.FilePath = filepath;
    curve.FileName = [fileName fileExt];
    curve.FileNameWithoutExt = fileName;
end

persistent loadingMethods;

if (~IsExtensionOf1dCurve(fileExt)) % If no recognizable extension, assume "fsi"
    fileExt = '.fsi';
end

switch (fileExt)
    case '.chi'
        [q, I] = readchifilenew(filepath, 3);
        curve.Q = q;
        curve.I = I;
        curve.IErr = curve.I .* 0.05; % Arbitrary
        wasRead = true;
        
    case '.dat'
        success = 0;
        
        if (~exist('loadingMethods', 'var') || isempty(loadingMethods))
            loadingMethods = [1:2];
        end
        
        % This is a method to first try the last method that worked
        % next time this function is called
        for loadingMethodIndex = loadingMethods
            switch loadingMethodIndex
                case 1
                    try
                        [mat, metadata] = ReadP12Dat(filepath);
                        success = 1;
                    catch ex
                        ex
                    end
                    
                case 2
                    try
                        %                             mat = load(filepath, '-ascii');
                        mat = ReadLinesOfXNumbers(filepath, [], 0);
                        metadata = struct();
                        success = double(~isempty(mat));
                    catch ex
                        ex
                    end
                    
                otherwise
                    success = 0;
            end
            
            if (success && loadingMethodIndex ~= numel(loadingMethods)) % Do not make the "last resort" one the default
                % Cycle the loading methods
                loadingMethods = [[loadingMethodIndex:numel(loadingMethods)] [1:loadingMethodIndex-1]];
                break;
            end
        end
        
        
        %             if (~success)
        %                 try
        %                     mat = load(filepath, '-ascii');
        %                     success = 1;
        %                 catch
        %                 end
        %             end
        
        if (success)
            wasRead = true;
            
            try
                fileQScale = metadata.Parsed.Q_Scale;
                if (strcmpi(fileQScale, 'nm^-1'))
                    curve.QScale = 'nm';
                elseif (strcmpi(fileQScale, 'nm^-1'))
                    curve.QScale = 'A';
                end
            catch
                curve.QScale = 'nm'; % typically "dat" files are in nm^-1
            end
            
            curve.Q = mat(:, 1);
            curve.I = mat(:, 2);
            
            if (size(mat, 2) >= 3)
                curve.IErr = mat(:, 3);
            else
                curve.IErr = curve.I .* 0.05; % Arbitrary
            end
            
            curve.Metadata = metadata;
        end
        
    case '.fsi'
        mat = load(filepath, '-ascii');
        curve.Q = mat(:, 1);
        curve.I = mat(:, 2);
        
        if (~size(mat, 2) == 3)
            curve.IErr = mat(:, 3);
        else
            curve.IErr = curve.I .* 0.05; % Arbitrary
        end
        
        xhiCurveFilename = ReplaceFileExtension(filepath, '.fsx');
        if (exist(xhiCurveFilename, 'file'))
            mat = load(xhiCurveFilename, '-ascii');
            xhiCurve.Angle = mat(:, 1);
            xhiCurve.I = mat(:, 2);
            
            if (~size(mat, 2) == 3)
                xhiCurve.IErr = mat(:, 3);
            else
                xhiCurve.IErr = xhiCurve.I .* 0.05; % Arbitrary
            end
        end
        wasRead = true;
        
    case '.fsx'
        mat = load(filepath, '-ascii');
        xhiCurve.Angle = mat(:, 1);
        xhiCurve.I = mat(:, 2);
        
        if (~size(mat, 2) == 3)
            xhiCurve.IErr = mat(:, 3);
        else
            xhiCurve.IErr = xhiCurve.I .* 0.05; % Arbitrary
        end
        
        curveFilename = ReplaceFileExtension(filepath, '.fsi');
        if (exist(curveFilename, 'file') & ~shouldReintegrate)
            mat = load(curveFilename, '-ascii');
            curve.Q = mat(:, 1);
            curve.I = mat(:, 2);
            
            if (~size(mat, 2) == 3)
                curve.IErr = mat(:, 3);
            else
                curve.IErr = curve.I .* 0.05; % Arbitrary
            end
        end
        wasRead = true;
        
    otherwise
        1;
end



