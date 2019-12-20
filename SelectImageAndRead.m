function [I] = SelectImageAndRead()

[FILENAME, PATHNAME] = uigetfile( ...
    {'*.tif;*.mat;*.image','Compatible Image Files (*.tif,*.image,*.mat)';
    '*.*',  'All Files (*.*)'}, ...
    'Choose Calibration Sample');

if (length(FILENAME) == 1 && FILENAME == 0)
    I = [];
    return;
end

I=read2D(strcat(PATHNAME,FILENAME));

end