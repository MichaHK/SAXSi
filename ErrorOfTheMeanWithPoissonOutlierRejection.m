function [result] = ErrorOfTheMeanWithPoissonOutlierRejection(values, outlierPercentile)
[~, result] = MeanWithPoissonOutlierRejection(values, outlierPercentile);
end
