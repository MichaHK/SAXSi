function [curve, xhiCurve] = Integrate (...
    image, CalibrationData, IntegrationParams, ...
    FastIntegrationCache)

Thresholding = IntegrationParams.Threshold;
q = [];
I = [];

curve = struct('Q', [], 'I', [], 'IErr', []);
xhiCurve = struct('Angle', [1:360], 'I', [1:360] .* 0, 'IErr', [1:360] .* 0);

% Experimental. Should not actually be used
blur = IntegrationParams.Blur;
if (blur > 0)
    blurKernel = kron(gausswin(blur)', gausswin(blur));
    blurKernel = blurKernel ./ sum(blurKernel(:));
    image = conv2(double(image), blurKernel, 'same');
end


%Thresholding=0;
%disp('started intigrating.... please wait')

switch IntegrationParams.IntegrationMethod
    
    case 'LocalSlopes'
        %% First integrate using the fast method
        [integrated] = IntFast(image, ...
            CalibrationData, IntegrationParams, FastIntegrationCache);
        
        curve.Q = integrated.Q;
        curve.I = integrated.I;
        curve.IErr = integrated.IErr;
        
        xhiCurve.Angle = integrated.Xhi;
        xhiCurve.I = integrated.IXhi;
        xhiCurve.IErr = integrated.IXhiErr;
        
        %%
        1;
        
    case 'FastAndBunch'
        [integrated] = IntFast(image, ...
            CalibrationData, IntegrationParams, FastIntegrationCache);
        
        curve.Q = zeros(1, numel(integrated.Q));
        curve.I = zeros(1, numel(integrated.Q));
        curve.IErr = zeros(1, numel(integrated.Q));
        j = 1;
        joined = [];
        N = zeros(1, numel(integrated.Q));
        joinedCount = zeros(1, numel(integrated.Q));
        
        integrated.N = integrated.N(1:numel(integrated.Q));
        integrated.I = integrated.I .* integrated.N;
        integrated.IErr = (integrated.IErr .^ 2) .* integrated.N;
        
        for i = 1:numel(integrated.Q)
            curve.Q(j) = curve.Q(j) + integrated.Q(i);
            curve.I(j) = curve.I(j) + integrated.I(i);
            curve.IErr(j) = curve.IErr(j) + integrated.IErr(i);
            N(j) = N(j) + integrated.N(i);
            joinedCount(j) = joinedCount(j) + 1;
            joined(end + 1) = i;
            
            if (i == numel(integrated.Q))
                break;
            end
            
            relErr = sqrt(curve.IErr(j) * N(j)) / curve.I(j);
            nextRelErr = sqrt((curve.IErr(j) + integrated.IErr(i + 1)) * (N(j) + integrated.N(i + 1))) / (curve.I(j) + integrated.I(i + 1));
            if (joinedCount(j) == 10 || relErr < 0.01 || nextRelErr >= relErr)
                j = j + 1;
                joined = [];
            else
                1;
            end
        end
        
        curve.Q = curve.Q ./ joinedCount;
        curve.Q = curve.Q(1:j);
        curve.I = curve.I ./ N;
        curve.I = curve.I(1:j);
        curve.IErr = sqrt(curve.IErr ./ N);
        curve.IErr = curve.IErr(1:j);
        
        xhiCurve.Angle = integrated.Xhi;
        xhiCurve.I = integrated.IXhi;
        xhiCurve.IErr = integrated.IXhiErr;
        
    case 'Accurate'
        [q, I] = IntegrateAccurate(image, CalibrationData, IntegrationParams, 1);
        
        curve.Q = q;
        curve.I = I;
        curve.IErr = curve.I .* 0.05; % Arbitrary
        
    case 'Accurate2'
        [q, I] = IntegrateAccurate(image, CalibrationData, IntegrationParams, 3);
        
        curve.Q = q;
        curve.I = I;
        curve.IErr = curve.I .* 0.05; % Arbitrary
        
    case 'FastSum'
        [integrated] = IntFast(image, ...
            CalibrationData, IntegrationParams, FastIntegrationCache);
        
        curve.Q = integrated.Q;
        % TODO: Should multiply by a calculated theoretical area for the Q-ring instead
        curve.I = integrated.I .* integrated.N(1:end-1);
        curve.IErr = integrated.IErr .* integrated.N(1:end-1);
        
        xhiCurve.Angle = integrated.Xhi;
        xhiCurve.I = integrated.IXhi;
        xhiCurve.IErr = integrated.IXhiErr;
    otherwise % 'Fast'
        [integrated] = IntFast(image, ...
            CalibrationData, IntegrationParams, FastIntegrationCache);
        
        curve.Q = integrated.Q;
        curve.I = integrated.I;
        curve.IErr = integrated.IErr;
        
        xhiCurve.Angle = integrated.Xhi;
        xhiCurve.I = integrated.IXhi;
        xhiCurve.IErr = integrated.IXhiErr;
end

if (IntegrationParams.shouldDoXhi && ~strcmp(IntegrationParams.IntegrationMethod, 'Fast'))
    [integrated] = IntFast(image, ...
        CalibrationData, IntegrationParams, FastIntegrationCache);
    
    xhiCurve.Angle = integrated.Xhi;
    xhiCurve.I = integrated.IXhi;
    xhiCurve.IErr = integrated.IXhiErr;
end

%I=max(I-Thresholding,0);
curve.I(curve.I < Thresholding) = 0; % Modified by Ram Avinery
curve.QScale = 'A'; % All integrated results are reported in inverse Angstrom

if (0)
    if ~isempty(xhiCurve.I)
        mat2 = [xhiCurve.Angle, xhiCurve.I, xhiCurve.IErr];
        xhiCurveFilename = ReplaceFileExtension(filepath, '.fsx');
        save(xhiCurveFilename, 'mat2', '-ascii');
    end
end
end



