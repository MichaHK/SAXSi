function [y] = Binning(x, b)

if (0) % Some test input
    %%
    b = [3 4];
    x = kron([1 2; 3 4], ones(3, 4))
end

if (any(mod(size(x), b) ~= 0))
    newSize = floor(size(x) ./ b) .* b;
    x = x(1:newSize(1), 1:newSize(2));
    
    warning('Input matrix has a size which is not an integer multiple of the binning size. Input matrix has been cropped to match.');
end

newSize = size(x) ./ b;

y = SumRows(x, b(1));
y = SumCols(y, b(2));

    function [y] = SumRows(x, n)
        y = sum(reshape(x, [n numel(x)/n]), 1);
        y = reshape(y, size(x) ./ [n 1]);
    end

    function [y] = SumCols(x, n)
        y = SumRows(x', n)';
    end

end
