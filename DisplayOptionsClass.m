classdef DisplayOptionsClass < handle
    
    % This class serves mainly for technical reasons, so that any code
    % modifying the properties would not need the "guidata" method to
    % propagate updates.
    
    properties
        AutoMaxIntensity = 1;
        IntensityRangeFor2d = [0 1];
        
        AutoRefresh = 0;
        AutoAddNewFiles = 0;
        Directory = cd();
        RecentFolders = {};
        SpreadCurvesBy = 0;
        SpreadCurvesMethod = 1;
        shouldFlipY = false;
        CurrentPlotType = 2;
        FilesFilter = '*.*';
        FilesSort = [];
        LastSeenFileTime = [];
        FileRefreshInterval = 3;
        ShouldSearchFilesRecursively = 0;
        ShouldSearchFilesUsingRegExp = 0;
        
        IsDisplayCleared = 1;
        
        Displayed1dScaleType = 1; % 1..5 : A^-1,nm^-1,A,nm,Degrees
        Displayed1dIntensityScaleType = 0; % 0 : normal, 1: divide by power law fit
        DisplayErrorBars = 1;
        
        Display2dLogarithmic = 0; % 0 - normal, 1 - logarithmic
        Display2dType = 0; % 0 - normal, 1 - gradient (of normal/log intensity), 2 - log of gradient
        
        Normalize2dImageOrientation = 0;
        
        % For each plot type
        DisplayXLogarithmic = [0 0 0 0 0 0];
        DisplayYLogarithmic = [0 0 0 0 0 0];
        
        ZoomInEachView = {};
        
        BackgroundCurve = [];
        ShouldSubtractBackground = false;
        CurveScalingRegion = [];
        
        ShouldApply1dPreprocessing = false;
        PreprocessingFunction = '';
        
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
        
        function [folder] = GetDirectory(obj)
            folder = strtrim(obj.Directory);
            if (~strcmp(folder(end), filesep))
                folder = [folder filesep];
            end
        end
    end
end
