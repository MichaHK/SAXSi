function [result] = MaximalPoissonLikelihoodWithOutlierRejection(values, outlierPercentile)

m = median(values);
maxInclusiveValue = poissinv(1-outlierPercentile, m);
minInclusiveValue = poissinv(outlierPercentile, m);

which = (values >= minInclusiveValue & values <= maxInclusiveValue);
values = values(which);

% if (any(values < 0))
%     1;
% end
   

logPoissonPDF = @(l, x)(log(l).*x - gammaln(x + 1) - l);
likelihoodFunc = @(p)sum(-logPoissonPDF(p, values));

if (1)
    %m = MeanWithPoissonOutlierRejection(values, outlierPercentile);
    [result, fval, exitflag, output] = fminsearch(likelihoodFunc, m);
else
end

end
