function [gaussian] = NonNormalized2dGaussian(rows, cols)

if (nargin < 2)
    if (numel(rows) == 2)
        cols = rows(2);
        rows = rows(1);
    else
        cols = rows;
    end
end

gaussian = kron(gausswin(rows), gausswin(cols)');
%gaussian = gaussian / sum(gaussian(:)); % Average with neighbors

end