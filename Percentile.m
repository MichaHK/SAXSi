function [value] = Percentile(data, percentile)

data = sort(data(:));
%value = round(percentile * numel(data))

if (percentile >= 1/numel(data))
    value = interp1(data, percentile * numel(data));
else
    if (numel(data) >= 10)
        p = polyfit([1:10]', data(1:10), 3);
        value = polyval(p, percentile);
    elseif (numel(data) >= 5)
        p = polyfit([1:5]', data(1:5), 2);
        value = polyval(p, percentile);
    elseif (numel(data) >= 2)
        p = polyfit([1:2]', data(1:2), 1);
        value = polyval(p, percentile);
    else
        value = data - eps;
    end
end

end
