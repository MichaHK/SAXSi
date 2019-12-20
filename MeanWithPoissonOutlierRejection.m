function [result, err, s, n, which] = MeanWithPoissonOutlierRejection(values, outlierPercentile)

m = trimmean(values, 1);
maxInclusiveValue = poissinv(1-outlierPercentile*0.01, m) + 1;
minInclusiveValue = poissinv(outlierPercentile*0.01, m) - 1;

which = (values >= minInclusiveValue & values <= maxInclusiveValue);
result = mean(values(which));

% if (isnan(result))
%     1;
% end

if (nargout >= 2)
    n = nnz(which);
    s = std(values(which));
    err = s / sqrt(n);
end

end
