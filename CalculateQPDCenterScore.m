function [score] = CalculateQPDCenterScore(curves)
%d21 = abs(curves(1).I - curves(2).I) ./ sqrt(curves(1).IErr.^2 + curves(2).IErr.^2);
%d43 = abs(curves(3).I - curves(4).I) ./ sqrt(curves(3).IErr.^2 + curves(4).IErr.^2);
d21 = abs(curves(1).I - curves(2).I);
d43 = abs(curves(3).I - curves(4).I);
score = max([mean(d21), mean(d43)]);
end
