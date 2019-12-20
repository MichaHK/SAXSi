function [controlPoints, conic, gof] = FitConicWithGradualSpreading(image, mask, x, y, profileAngle, peakSigma, options)

%% Handle input checks
if (nargin < 7)
    options = GenerateDefaultOptions();
    
    if (nargin < 6)
        if (nargout == 1)
            controlPoints = options; % Return the default options struct as the first output
            return;
        else
            load('FitConicWithGradualSpreading-state');
            %error('Bad number of inputs/outputs in call');
        end
    end
else
    save('FitConicWithGradualSpreading-state');
end

%%
if (1)
    figure(2);
    imagesc(log(image + 1));
end

%%

areaSize = [20 20];
r = min(areaSize);

tangent = profileAngle + pi / 2;
angles1 = linspace(tangent - pi / 3, tangent + pi / 3, 100);
angles2 = linspace(tangent + pi - pi / 3, tangent + pi + pi / 3, 100);

ValuesFunc = @(a)interp2(image, x + r .* cos(a), y + r .* sin(a));
values1 = arrayfun(ValuesFunc, angles1);
%figure(3); plot(radtodeg(unwrap(angles1)), values1)
values2 = arrayfun(ValuesFunc, angles2);
%figure(3); plot(radtodeg(unwrap(angles2)), values2)
[~, maxIndex1] = max(values1);
[~, maxIndex2] = max(values2);
a1 = angles1(maxIndex1);
a2 = angles2(maxIndex2);

a = [a1 a2];
hold on;
plot(x, y, '*g', 'MarkerSize', 16);
plot(x + r .* cos(a), y + r .* sin(a), '*y', 'MarkerSize', 16);
hold off;

1;

conic = ConicClass();
%conic.SetSolutionOf5Points();


%%
    function [options] = GenerateDefaultOptions()
        options = struct();
    end

end
