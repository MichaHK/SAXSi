function DebugPlotImageWithConic(image, coordinates, conic)

if (size(coordinates, 1) == 1 || size(coordinates, 2) == 1)
    coordinates = [coordinates(1:2:end), coordinates(2:2:end)];
    x = coordinates(1:2:end);
    y = coordinates(2:2:end);
elseif (size(coordinates, 1) == 2)
    x = coordinates(1, :);
    y = coordinates(2, :);
elseif (size(coordinates, 2) == 2)
    x = coordinates(:, 1);
    y = coordinates(:, 2);
else
    error('Bad coordinates matrix');
end

image(image < 0 | isnan(image)) = 0;
figure(2); imagesc(log(image + 1));

if (~exist('conic', 'var'))
    conic = ConicClass();
    conic.SetSolutionOf5Points(x, y);
end

hold on;
plot(x, y, '*y', 'MarkerSize', 16);
conic.DebugPlotInRect([1, 1, size(image, 2), size(image, 1)]);

if (size(image, 1) > 1000)
xlim([761.9  949.2]);
ylim([526.3 690.9]);
end
hold off;

N = 1000;
[values, x, y] = GetValuesOnConic(image, conic, N);

remove = isnan(values);

values(remove) = [];
x(remove) = [];
y(remove) = [];

%% Experimental
[gradX, gradY] = gradient(image);
gradXValues = GetValuesOnConic(gradX, conic, N);
gradYValues = GetValuesOnConic(gradY, conic, N);
gradXValues(remove) = [];
gradYValues(remove) = [];

totalGrad = abs(gradXValues) + abs(gradYValues);
[~, steepestIndex] = max(totalGrad);
%[x(steepestIndex) y(steepestIndex)]
figure(2);
hold on;
factor = 10;
every = 10;
quiver(x(1:every:end), y(1:every:end), gradXValues(1:every:end) .* factor, gradYValues(1:every:end) .* factor, 'Color', 'Yellow');
hold off;


drawnow();
end
