function [folder] = subtract2dimages(folder)

if (~exist('folder', 'var') || isempty(folder))
    folder = cd();
end

[fileName, pathName, filterIndex] = uigetfile( ...
    {'*.tif','Tiff Files (*.tif)'; ...
    '*.image','image Files(*.image)'; ...
    '*.*',  'All Files (*.*)'}, ...
    'Pick file to subrtact from', folder, ...
    'MultiSelect', 'off');

if (isequal(fileName, 0))
    return;
end

folder = pathName;
fileName1 = fileName;
filePath1 = [pathName fileName];

[fileName, pathName, filterIndex] = uigetfile( ...
    {'*.tif','Tiff Files (*.tif)'; ...
    '*.image','image Files(*.image)'; ...
    '*.*',  'All Files (*.*)'}, ...
    'Pick file to be subtracted', folder, ...
    'MultiSelect', 'off');

if (isequal(fileName, 0))
    return;
end

fileName0 = fileName;
filePath0 = [pathName fileName];

try
    disp (['Subtracting...'])

    disp (filePath0);
    readImage0 = double(read2D(filePath0));

    disp (filePath1);
    readImage1 = double(read2D(filePath1));

    im = readImage1 - readImage0;
    
    [fileName, pathName, filterIndex] = uiputfile({ '*.tif;*.tiff','TIFF files'; ...
        '*.mat','MATLAB files' }, 'Pick output file name', folder);
    
    if (isempty(fileName))
        return;
    end
    
    switch (filterIndex)
        case 1
            t = Tiff([pathName fileName], 'w');
            tagstruct = struct();
            %tagstruct.Compression = Tiff.Compression.None; % no compression
            tagstruct.Compression = Tiff.Compression.LZW;
            %tagstruct.Compression = Tiff.Compression.Deflate;
            tagstruct.ExtraSamples = Tiff.ExtraSamples.Unspecified;
            tagstruct.BitsPerSample = 64;
            tagstruct.SamplesPerPixel = 1;
            tagstruct.Photometric = Tiff.Photometric.MinIsBlack;
            tagstruct.SampleFormat = Tiff.SampleFormat.IEEEFP;
            
            tagstruct.ImageLength = size(im, 1);
            tagstruct.ImageWidth = size(im, 2);
            
            tagstruct.RowsPerStrip = 16;
            tagstruct.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
            tagstruct.Software = 'MATLAB';
            
            t.setTag(tagstruct);
            
            t.write(im);
            t.close();
            
        case 2
            save ([pathName fileName], 'im', '-mat');
            
        otherwise
            error('');
    end
    
    % im2=read2D(FileName);
    % image(im2);
    % title (FileName');
catch err
    disp ('Something failed...');
    disp (err);
end


