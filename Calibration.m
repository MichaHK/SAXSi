function [ok] = Calibration(CalibrationData, calibrationImage)

addpath('CONEX');
addpath('Conic');

ok = 0;

LINES = [];
%l=load('linesSaved.mat');LINES=l.LINES;
[LINES, beamWavelength, ~] = AddCalibrationSample_GUI_SAXSi(LINES, ...
    CalibrationData.Lambda, [], calibrationImage);

% save lines?
if ~isempty(LINES)
    Detector_position = FindDetectorPosition_GUI_SAXSi(LINES);
    %[n1,n2,alpha0, d0, Xd0 ,Yd0 ,beta0]=FindDetectorPosition_GUI_SAXSi(LINES);
    %par_0=[alpha0 d0 Xd0 Yd0 beta0];
    
    pxSzn = CalibrationData.PixelSize;
    
    par = Detector_position(3:7);
    xyc = find_Direct_Beam(par(3),par(4),par(5));
    
    CalibrationData.AlphaRadians = par(1);
    CalibrationData.AlphaDegrees = par(1)*180/pi;
    CalibrationData.BetaRadians = par(5);
    CalibrationData.BetaDegrees = par(5)*180/pi;
    CalibrationData.SampleToDetDist = par(2)*pxSzn;
    CalibrationData.BeamCenterX = xyc(1);
    CalibrationData.BeamCenterY = xyc(2);
    
    CalibrationData.Lambda = beamWavelength;
    
    ok = 1;
    
end

end
