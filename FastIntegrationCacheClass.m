classdef FastIntegrationCacheClass < handle
    
    % This class serves mainly for technical reasons, so that any code
    % modifying the properties would not need the "guidata" method to
    % propagate updates.
    
    properties
        Params = struct();
        ImageSize = [0,0];
        
        ImageToQMatrix = [];
        QVector = [];
        
        ImageToXhiMatrix = [];
        XhiVector = [];
        
        Factor = 1;
        PrevFactor = 1;
        
        QImage;
        XhiImage;
    end
    
    methods
        function CopyFrom(obj, other)
            fields = fieldnames(obj);
            for i = 1:numel(fields)
                obj.(fields{i}) = other.(fields{i});
            end
        end
        
        function CopyParams(obj, CalibrationData, IntegrationParams)
            obj.Params.CalibrationData = CopyFieldsInto(struct(), CalibrationData);
            obj.Params.IntegrationParams = CopyFieldsInto(struct(), IntegrationParams);
        end
        
        function [f] = AnyParamsChanged(obj, CalibrationData, IntegrationParams)
            if (~isfield(obj.Params, 'CalibrationData')) % Not updated first time yet?
                f = 0;
                return;
            end
            
            f = ~AreFieldsEqual(obj.Params.CalibrationData, CalibrationData);
            f = f || ~AreFieldsEqual(obj.Params.IntegrationParams, IntegrationParams);
        end
        
        function [] = Clear(obj)
            obj.Params = struct();
            obj.ImageSize = [0,0];
            
            obj.ImageToQMatrix = [];
            obj.QVector = [];
            
            obj.ImageToXhiMatrix = [];
            obj.XhiVector = [];
            
            obj.Factor = 1;
            obj.PrevFactor = 1;
        end
    end
end
