function [y] = SpreadCurvesAdditively(x, y, by, ensureNoIntersection)

if (~exist('ensureNoIntersection', 'var') || isempty(ensureNoIntersection))
    ensureNoIntersection = 0;
end


offset = zeros(1, numel(y));
for i = 2:numel(y)
    prevY = interp1(x{i-1}, y{i-1}, x{i});
    %d = min(y{i} - nextY);
    
    which = ~isnan(prevY);
    currentY = y{i};
    if (ensureNoIntersection)
        %d = min(currentY(which) - prevY(which));
        diffs = sort(currentY(which) - prevY(which));
        d = diffs(1+floor(0.01 * end));
    else
        d = mean(currentY(which) - prevY(which));
    end
    offset(i) = by - d;
    y{i} = y{i} + offset(i);
end

end