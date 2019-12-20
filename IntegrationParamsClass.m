classdef IntegrationParamsClass < handle
    
    % This class serves mainly for technical reasons, so that any code
    % modifying the properties would not need the "guidata" method to
    % propagate updates.
    
    % This class along with the "CalibrationDataClass" should contain
    % everything required to for the integration code to run without GUI
    % (without other parameters)
    
    properties
        QStepsCount = 500;
        QMin = 1e-3;
        QMax = 3;
        shouldDoXhi = false;
        Threshold = 0;
        IntegrationMethod = 1;
        Blur = 0;
        
        % TODO: Elaborate comments about dezinger
        DezingerType = 0; % 0 - None, 1 - trimmean, 2 - poisson median filter
        DezingerPercentile = 0.3;

        % In rare cases, a portion of the detector gets a "hot" reading compared
        % to its surrounding blocks (an electric issue).
        % These readings should be discarded.
        UseHotBlockRejection = false;
        
        MaskBitmap = [];
    end
    
    methods
        function CopyFrom(obj, other)
            fields = fieldnames(other);
            for i = 1:numel(fields)
                if (isprop(obj, fields{i}))
                    obj.(fields{i}) = other.(fields{i});
                end
            end
        end
    end
end
