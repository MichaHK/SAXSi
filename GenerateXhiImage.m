function [xhiImage] = GenerateXhiImage(xScale, yScale, CalibrationData)

sizeOfImage = [numel(yScale) numel(xScale)];

xhiImage = zeros(sizeOfImage);

%% Calculate image

L = CalibrationData.SampleToDetDist;
pixsize = CalibrationData.PixelSize;
lamda = CalibrationData.Lambda;
alpha = CalibrationData.AlphaRadians;
beta = CalibrationData.BetaRadians;
%     flipY = .shouldFlipY;

d = L/pixsize;

[Xd,Yd]=find_Direct_Beam_conX(...
    CalibrationData.BeamCenterX,...
    CalibrationData.BeamCenterY, beta);

%     if flipY
%         lenIm = length(imagemat);
%         y0=lenIm-y0;
%     end

fourPiOverLamda = 12.56637061435917/lamda;
pixelsizeOverL = pixsize/L;

%%%%%% calculate matries %%%%%%%

[xx, yy] = meshgrid(xScale, yScale);

XX = Xd + xx*cos(beta) - yy*sin(beta);
YY = Yd - xx*sin(beta) - yy*cos(beta);

clear xx;
clear yy;

xx = YY*cos(alpha);
yy = -XX;

xhiImage = ceil(180 * atan2(yy, xx) / pi) + 180;

clear Dist

