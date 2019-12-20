classdef CalibrationDataClass < handle
    
    % This class serves mainly for technical reasons, so that any code
    % modifying the properties would not need the "guidata" method to
    % propagate updates.
    
    properties (GetAccess = protected, SetAccess = protected)
        IsWithinSetter = 0;
    end
    
    properties
        AlphaRadians = 0;
        BetaRadians = 0;
        AlphaDegrees = 0;
        BetaDegrees = 0;

        SampleToDetDist = 1; % In the same units as pixel size (presumably "mm"?)
        BeamCenterX = 0;
        BeamCenterY = 0;
        
        Lambda = CopperKAlpha();
        PixelSize = 0.100;
    end
    
    methods
        function obj = set.AlphaRadians(obj,val)
            %display('set.AlphaRadians');
            obj.AlphaRadians = val;
            
            if (~obj.IsWithinSetter)
                obj.IsWithinSetter = 1;
                obj.AlphaDegrees = rad2deg(val);
                obj.IsWithinSetter = 0;
            end
        end
        
        function obj = set.AlphaDegrees(obj,val)
            %display('set.AlphaDegrees');
            obj.AlphaDegrees = val;
            
            if (~obj.IsWithinSetter)
                obj.IsWithinSetter = 1;
                obj.AlphaRadians = deg2rad(val);
                obj.IsWithinSetter = 0;
            end
        end
        
        function obj = set.BetaRadians(obj,val)
            %display('set.BetaRadians');
            obj.BetaRadians = val;
            
            if (~obj.IsWithinSetter)
                obj.IsWithinSetter = 1;
                obj.BetaDegrees = rad2deg(val);
                obj.IsWithinSetter = 0;
            end
        end
        
        function obj = set.BetaDegrees(obj,val)
            %display('set.BetaDegrees');
            obj.BetaDegrees = val;
            
            if (~obj.IsWithinSetter)
                obj.IsWithinSetter = 1;
                obj.BetaRadians = deg2rad(val);
                obj.IsWithinSetter = 0;
            end
        end
        
        function CopyFrom(obj, other)
            fields = fieldnames(other);
            for i = 1:numel(fields)
                if (isprop(obj, fields{i}))
                    obj.(fields{i}) = other.(fields{i});
                end
            end
        end
        
        function [] = UpdatePixelSize(obj, pixelSize)
            obj.SampleToDetDist = obj.SampleToDetDist * pixelSize / obj.PixelSize;
            obj.PixelSize = pixelSize;
        end
        
        function [twoTheta] = GetTwoThetaRadiansForXY(obj, x, y)
            if (nargin < 3)
                y = x(2);
                x = x(1);
            end
            
            d = obj.SampleToDetDist / obj.PixelSize;
            
            xyc = find_Direct_Beam(obj.BeamCenterX, obj.BeamCenterY, obj.BetaRadians);
            Xd = xyc(1);
            Yd = xyc(2);
            
            XX = Xd + x*cos(obj.BetaRadians) - y*sin(obj.BetaRadians);
            YY = Yd - x*sin(obj.BetaRadians) - y*cos(obj.BetaRadians);

            xx = YY*cos(obj.AlphaRadians);
            yy = -XX;
            zz = d/cos(obj.AlphaRadians)-YY*sin(obj.AlphaRadians);

            Dist = sqrt(xx.^2+yy.^2+zz.^2);
            twoTheta = acos(zz./Dist);
        end
        
        function [q] = GetQForXY(obj, x, y)
            if (nargin < 3)
                y = x(2);
                x = x(1);
            end
            
            twoTheta = obj.GetTwoThetaRadiansForXY(x, y);
            q = 4 * pi() * sin(twoTheta / 2) / obj.Lambda;
            1;
        end
        
        function [angles] = GetDegreesForQ(obj, q)
            inverseTwoK = obj.Lambda / (4 * pi());
            angles = rad2deg(asin(q .* inverseTwoK));
        end
        
        function [angles] = GetTwoThetaDegreesForQ(obj, q)
            angles = 2 * obj.GetDegreesForQ(q);
        end
    end
end
