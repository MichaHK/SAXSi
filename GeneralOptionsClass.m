classdef GeneralOptionsClass < handle
    properties
        SaveIntegrationToDatFile = 0; % 0 - no, 1 - in A^-1 scale, 2 - in nm^-1 scale
        SaveIntegrationToFsiFile = 1; % 0 - no, 1 - yes
        ShouldLoadIntegratedFileInsteadOfIntegrating = 1;
        SaveIntegrationFsxFile = 0;
        
        ReintegrateTracesBackToImages = 1;
    end
    
    methods
        function CopyFrom(obj, other)
            fields = fieldnames(obj);
            for i = 1:numel(fields)
                obj.(fields{i}) = other.(fields{i});
            end
        end
    end
end
