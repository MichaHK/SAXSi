function testSegmentsOfIntegration(c, r, t, out, linespec)

if (nargin < 5)
    linespec = '*k';
end

integrationSegments = [];
if (numel(t) == 0) % Either entirely contained or no overlap at all
    [x0, y0] = c.GetPointsFromParametricForm(0);
    if (WithinRect(r, x0, y0))
        integrationSegments = [0, 2*pi];
    end
else
    % Look for consecutive in-out pairs (cyclic)
    which = ([diff(out) out(1)-out(end)] == 1);
    
    which = find(which);
    which = which(:);
    startAngle = which;
    endAngle = which + 1;
    if (endAngle(end) > numel(t)), endAngle(end) = 1; end;
    integrationSegments = t([startAngle, endAngle]);
    
    need2pi = integrationSegments(:, 1) > integrationSegments(:, 2);
    integrationSegments(need2pi, 2) = integrationSegments(need2pi, 2) + 2*pi;
end

for i = 1:size(integrationSegments, 1)
    [x, y] = c.GetPointsFromParametricForm(linspace(integrationSegments(i, 1), integrationSegments(i, 2), 10));
    hold on;
    plot(x, y, linespec);
    hold off;
end

end
