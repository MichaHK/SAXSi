
% Intended for transient information (not saved for next sessions)
classdef SAXSiStateClass < handle
    properties
        Image = [];
        DisplayedImage = [];
        
        FilePath = '';
        
        IsWithinLoadSettings = 0;
        
        IsFileMonitoringCurrentlyRunning = 0;
        FileMonitoringRefreshCounter = 0;
        PositionWhereMenuWasOpened = [0 0 0];
        LastPlotType = -1;
        ImageHandle;
        MaskHandle;
        QMinLineHandles = [];
        QMaxLineHandles = [];
        LastImageDimensions = [];
        
        QMarks;
        
        Curves = [];
        XhiCurves = [];
    end
end
