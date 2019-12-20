classdef SAXSiClass < handle
    
    properties
        IntegrationOptions = IntegrationOptionsClass();
    end
    
    properties (GetAccess = public, SetAccess = private)
        internalCalibrationData;
        internalImageMask;
    end
    
    properties (Dependent = true, SetAccess = private)
        CalibrationData
        ImageMask
    end
    
    methods
        function [] = set.CalibrationData(obj, calData)
            obj.internalCalibrationData = calData;
        end

        function data = get.CalibrationData(obj)
            data = obj.internalCalibrationData;
        end
        
        function [] = set.ImageMask(obj, mask)
            obj.internalImageMask = mask;
        end

        function mask = get.ImageMask(obj)
            mask = obj.internalImageMask;
        end
        
    end % methods
    
    methods
    end
    
end
