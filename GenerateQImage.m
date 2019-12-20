function [qImage] = GenerateQImage(xScale, yScale, CalibrationData)

sizeOfImage = [numel(yScale) numel(xScale)];

qImage = zeros(sizeOfImage);

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
zz = d/cos(alpha) - YY*sin(alpha);

Dist = sqrt(xx.^2+yy.^2+zz.^2);
%  Theta=180*acos(zz./Dist)/pi;

%   q=4*pi*sin(0.5*atan(pixsize*rmin/L))/lamda
%  q=forpiOverLamda*sin(0.5.*acos(zz./Dist));
%maskin=maskin';

qImage = fourPiOverLamda*sin(0.5.*acos(zz./Dist));

clear Dist

