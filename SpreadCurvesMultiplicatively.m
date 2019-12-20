function [y, yErr] = SpreadCurvesMultiplicatively(x, y, yErr, by, ensureNoIntersection)

if (~exist('ensureNoIntersection', 'var') || isempty(ensureNoIntersection))
    ensureNoIntersection = 0;
end

factor = ones(1, numel(y));
for i = 2:numel(y)
    prevY = interp1(x{i-1}, y{i-1}, x{i});
    
    which = ~isnan(prevY) & (prevY > 0);
    currentY = y{i};
    
    if (ensureNoIntersection)
        %d = min(currentY(which) ./ prevY(which));
        ratios = sort(currentY(which) ./ prevY(which));
        d = ratios(1+floor(0.01 * end));
    else
        d = mean(currentY(which) ./ prevY(which));
    end
    
    factor(i) = by / d;
    y{i} = y{i} .* factor(i);
    yErr{i} = yErr{i} .* factor(i);
end


end
