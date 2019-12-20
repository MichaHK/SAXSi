function [data meta] = ReadP12Dat(filepath)

meta = struct();
meta.FirstLines = {};
meta.LastLines = {};
meta.Properties = dict();
%meta.Data = [];

if (0)
    NET.addAssembly('mscorlib');
    NET.addAssembly('System');
    fileInfo = System.IO.FileInfo(filepath);
    fileTime = fileInfo.LastWriteTimeUtc.AddHours(+1); % "+1" to adjust to Germany time
    timeVector = double([fileTime.Year fileTime.Month fileTime.Day fileTime.Hour fileTime.Minute fileTime.Second]);
    
    meta.FileTimeVector = timeVector;
    meta.FileTimeString = datestr(timeVector);
end


%% Read first lines and then the numbers
f = fopen(filepath);

try
    textBefore = {};
    textAfter = {};
    data = [];
    
    while ~feof(f) %ischar(tline)
        tline = fgetl(f);
        
        firstData = sscanf(tline, '%f');
        
        if (numel(firstData) >= 3)
            break;
        end
        
        textBefore{end+1} = tline;
    end
    
    data = fscanf(f, '%f');
    
    data = [firstData'; reshape(data, [numel(firstData) numel(data)/numel(firstData)])'];
    
    while ~feof(f) %ischar(tline)
        tline = fgetl(f);
        textAfter{end+1} = tline;
    end
    
catch err
    display(err);
end

fclose(f);

%%

meta.FirstLines = textBefore;
meta.LastLines = textAfter;

%% Parse properties
textLines = {meta.FirstLines{:}, meta.LastLines{:}};
for i = 1:numel(textLines)
    l = strtrim(textLines{i});
    
    if (isempty(l))
        continue;
    end
    
    if (l(1) == '#')
        l = strtrim(l(2:end));
    end
    
    [key, value] = strtok(l, ':');
    
    if (~isempty(key))
        key = strtrim(key);
        value = strtrim(value(2:end));
        meta.Properties(key) = value;
    end
end

[fields, values, structuredData] = P12TextLinesToStruct(textLines, true);
meta.Parsed = structuredData;


%
% %% Generate some useful fields
% meta.Description = meta.Properties('Description');
% meta.Sample = meta.Properties('Sample');
% meta.Code = meta.Properties('Code');
% meta.FrameNumber = meta.Properties('Frame Number');
% meta.ExposureTime = meta.Properties('Exposure time [s]');
% meta.ExposurePeriod = meta.Properties('Exposure period [s]');
% meta.MachineCurrent = meta.Properties('PETRA Current');
% meta.TransmittedBeam = meta.Properties('Transmitted Beam');
% meta.Vacuum = meta.Properties('Flytube Vacuum [mbar]');
% meta.TempOfCell = meta.Properties('Cell Temperature [C]');
% meta.TempOfStorage = meta.Properties('Storage Temperature [C]');
% meta.Concentration = meta.Properties('Concentration [mg/ml]');
% meta.RunNumber = str2double(meta.Properties('Run Number'));
% %meta.ChiValueThreshold = meta.Properties('Chi-value threshold');
% meta.ReferenceFrame = meta.Properties('Reference frame');
% meta.PinDiodeMean = meta.Properties('Pin diode (mean)');
% meta.ProcessedBy = meta.Properties('Processed by');


1;
end
