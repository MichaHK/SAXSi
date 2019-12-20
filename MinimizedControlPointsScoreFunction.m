function [score] = MinimizedControlPointsScoreFunction(image, mask, coordinates)
conic = ConicClass();
conic.SetSolutionOf5Points(coordinates(1:2:end), coordinates(2:2:end));


if (1)
    DebugPlotImageWithConic(image ./ mask, coordinates, conic);
end

N = 1000;
[values, x, y] = GetValuesOnConic(image, conic, N);
maskValues = GetValuesOnConic(mask, conic, N);

remove = isnan(values) | isnan(maskValues) | maskValues < (1 - 1e-6);
values(remove) = [];
maskValues(remove) = [];
x(remove) = [];
y(remove) = [];

values = values ./ maskValues;

%% Experimental
[gradX, gradY] = gradient(image);
gradXValues = GetValuesOnConic(gradX, conic, N);
gradYValues = GetValuesOnConic(gradY, conic, N);
gradXValues(remove) = [];
gradYValues(remove) = [];

totalGrad = abs(gradXValues) + abs(gradYValues);
[~, steepestIndex] = max(totalGrad);
[x(steepestIndex) y(steepestIndex)]
figure(2);
hold on;
factor = 10;
every = 10;
quiver(x(1:every:end), y(1:every:end), gradXValues(1:every:end) .* factor, gradYValues(1:every:end) .* factor, 'Color', 'Yellow');
hold off;
1;

%%
%score = -mean(values); % TODO: Calculate the mean by dividing the sum by the integration on the mask
score = -sum(values);

%ginput(1);
