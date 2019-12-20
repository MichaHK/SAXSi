function [bestGuessedCenter, centerGuesses] = GuessCenterFromAssuminglyRadialPoints(x, y)

xy = [x(:) y(:)];
meanXY = mean(xy, 1);

relXY = bsxfun(@minus, xy, meanXY);
relAngle = atan2(relXY(:, 2), relXY(:, 1));

[relAngle, angularOrder] = sort(relAngle);
relXY = relXY(angularOrder, :);

% Find median distance between points
stepSizes = sqrt(sum(diff(relXY, 1, 1) .^ 2, 2));
medianStepSize = median(stepSizes);

% Break down into groups with small steps
whereBreaks = stepSizes > medianStepSize*2;
groupAssignment = [0; cumsum(whereBreaks)] + 1;

pointGroups = arrayfun(@(i)xy(groupAssignment==i, :), 1:max(groupAssignment), 'UniformOutput', false);

centerGuesses = [];

for groupIndex = 1:numel(pointGroups)
   points =  pointGroups{groupIndex};
   
   if (size(points, 1) < 3)
       continue;
   end
   
   steps = diff(points, 1, 1);
   slopes = steps(:, 2) ./ steps(:, 1);
   
   whichOk = (~isnan(slopes) & ~isinf(slopes));
   slopes = slopes(whichOk);
   
   a = (-1) ./ slopes; % Turn into reciprocal slopes
   middlePoints = (points(1:end-1, :)+points(2:end, :))*0.5;
   middlePoints = middlePoints(whichOk, :);
   
   % y = ax+b => b = y-ax
   b = middlePoints(:, 2) - a .* middlePoints(:, 1);
   
   %%
   if (0)
       hold on;
       for i = 1:numel(a)
           %px = middlePoints(i, 1)+[-30 30];
           px = middlePoints(i, 1) + [-1 +1]*(80/2/sqrt(a(i)^2 + 1));
           py = a(i) * px + b(i);
           plot(px, py, '-g');
           pause(0.1);
       end
       hold off;
   end
   
   %%
   % a0x+b0 = a1x+b1 => x = (b1-b0)/(a0-a1)
   % Calculate intersection of each couple of neighboring lines
   intersectionX = -(diff(b)./diff(a));
   intersectionY = a(1:end-1) .* intersectionX + b(1:end-1);

   centerGuesses = [centerGuesses; [intersectionX intersectionY]];
    
end

bestGuessedCenter = [median(centerGuesses(:, 1)) median(centerGuesses(:, 2))];
1;

end


