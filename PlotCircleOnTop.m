function PlotCircleOnTop(at, r, color, lineWidth, N)

if (~exist('r', 'var') || isempty(r))
    r = 10;
end

if (~exist('color', 'var') || isempty(color))
    color = 'red';
end

if (~exist('lineWidth', 'var') || isempty(lineWidth))
    lineWidth = 2;
end

if (~exist('N', 'var') || isempty(N))
    N = 36*2;
end

hold on;
theta = linspace(0, 2 * pi, N + 1);
x = at(1) + r .* cos(theta);
y = at(2) + r .* sin(theta);
plot(x, y, '-', 'Color', color, 'LineWidth', lineWidth);
hold off;
end
