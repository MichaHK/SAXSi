function [y, yErr] = ScaleCurves(x, y, yErr, scalingRegion)

factor = ones(1, numel(y));

which = (x{1} >= scalingRegion(1)) & (x{1} <= scalingRegion(2));
x0 = x{1}(which);
y0 = y{1}(which);
y0err = yErr{1}(which);

for i = 2:numel(y)
    y_resampled = interp1(x{i}, y{i}, x0);
    yErr_resampled = interp1(x{i}, yErr{i}, x0);
    
    w = (y0err .^ 2 + yErr_resampled .^ 2).^(-0.5);
    w = w ./ sum(w);
    
    f = w' * (y0 ./ y_resampled);
    
    factor(i) = f;
    y{i} = y{i} .* factor(i);
    yErr{i} = yErr{i} .* factor(i);
end


end
