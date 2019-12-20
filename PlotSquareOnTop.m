function PlotSquareOnTop(at, halfWidth, color, lineWidth)

if (~exist('r', 'var') || isempty(r))
    r = 10;
end

if (~exist('color', 'var') || isempty(color))
    color = 'red';
end

if (~exist('lineWidth', 'var') || isempty(lineWidth))
    lineWidth = 2;
end

hold on;
square = [-1 -1; 1 -1; 1 1; -1 1; -1 -1] .* halfWidth;
x = square(:, 1) + at(1);
y = square(:, 2) + at(2);
plot(x, y, '-', 'Color', color, 'LineWidth', lineWidth);
hold off;
end
