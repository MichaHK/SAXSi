function [folder] = sum2dimages(folder, shouldAverageInsteadOfSum)

if (~exist('folder', 'var') || isempty(folder))
    folder = cd();
end

if (~exist('shouldAverageInsteadOfSum', 'var') || isempty(shouldAverageInsteadOfSum))
    shouldAverageInsteadOfSum = 0;
end

[fileName, pathName, filterIndex] = uigetfile( ...
    {  '*.tif','Tiff Files (*.tif)'; ...
    '*.image','image Files(*.image)'; ...
    '*.*',  'All Files (*.*)'}, ...
    'Pick files to sum', folder, ...
    'MultiSelect', 'on');
if (isequal(fileName, 0))
    return;
end

folder = pathName;

try
    disp (['Summing... (at: ' pathName ')'])
    
    for i = 1:length(fileName)
        disp (fileName{i})
        
        readImage = double(read2D([pathName fileName{i}]));
        
        if (i == 1)
            im = zeros(size(readImage));
        end
        
        im = im + readImage;
    end
    
    if (shouldAverageInsteadOfSum)
        im = im ./ numel(fileName);
    else
    end
    
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


