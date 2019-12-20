function [data meta] = ReadEsrf1D(filepath)

f = fopen(filepath);

try
    delimiter = ' ';
    whitespace  = setdiff(sprintf(' \b\t'), delimiter);
    conc = 0;
    code = '';
    measurementTemp = 0;
    storageTemp = 0;
    frameExposureTime = 0;
    frameIndex = 0;
    framesCount = 0;
    commentLines = {};
    
    tline = fgetl(f);
    while ischar(tline)
        if (tline(1) == '#')
            commentLines{end + 1} = tline;
        end
        
        if (tline(1) ~= '#')
            result  = textscan(tline, '  %f   %f   %f');
            data = [result{:}];
            
            meta = struct();
            meta.CommentLines = commentLines;
            meta.Conc = conc;
            meta.Code = code;
            meta.MeasurementTemp = measurementTemp;
            meta.StorageTemp = storageTemp;
            meta.FrameExposureTime = frameExposureTime;
            meta.FrameIndex = frameIndex;
            meta.FramesCount = framesCount;
            
            if (exist('diodeCurrent', 'var') && ~isempty(diodeCurrent))
                meta.DiodeCurrent = diodeCurrent;
            else
                meta.DiodeCurrent = 1;
            end;
            
            if (exist('machineCurrent', 'var') && ~isempty(machineCurrent))
                meta.MachineCurrent = machineCurrent;
            else
                meta.MachineCurrent = 1;
            end;
            
            break;
        elseif (strfind(tline, '# Sample c= ') == 1)
            conc = sscanf(tline, '# Sample c= %f');
        elseif (strfind(tline, '# Code: ') == 1)
            code = sscanf(tline, '# Code: %s');
        elseif (strfind(tline, '# Measurement Temperature (degrees C): ') == 1)
            measurementTemp = sscanf(tline, '# Measurement Temperature (degrees C): %f');
        elseif (strfind(tline, '# Storage Temperature (degrees C): ') == 1)
            storageTemp = sscanf(tline, '# Storage Temperature (degrees C): %f');
        elseif (strfind(tline, '# Time per frame (s) = ') == 1)
            frameExposureTime = sscanf(tline, '# Time per frame (s) = %f');
        elseif (strfind(tline, '# Exposure time per frame: ') == 1)
            frameExposureTime = sscanf(tline, '# Exposure time per frame: %f');
        elseif (strfind(tline, '# DiodeCurr = ') == 1)
            diodeCurrent = sscanf(tline, '# DiodeCurr = %f');
        elseif (strfind(tline, '# MachCurr = ') == 1)
            machineCurrent = sscanf(tline, '# MachCurr = %f');
        elseif (strfind(tline, '# Frame ') == 1)
            tmp = sscanf(tline, '# Frame %d of %d');
            frameIndex = tmp(1);
            framesCount = tmp(2);
        elseif (strfind(tline, '# Number of frames collected: ') == 1)
            framesCount = sscanf(tline, '# Number of frames collected: %d');
            frameIndex = -1; % Average
        end
        
        tline = fgetl(f);
    end
    
    tline = fgetl(f);
    while ischar(tline)
        result  = textscan(tline, '  %f   %f   %f');
        data(end+1, :) = [result{:}];
        tline = fgetl(f);
    end
    
catch err
    display(err);
end

fclose(f);



end
