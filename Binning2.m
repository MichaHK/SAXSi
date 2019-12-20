function [y] = Binning2(x, b)

if (0) % Some test input
    %%
    b = [2 2];
    x = kron([1 2; 3 4], ones(3, 4));
end

if (0) % Some test input
    %%
    b = [2 2];
    x = magic(10);
end

if (any(mod(size(x), b) ~= 0))
    newSize = floor(size(x) ./ b) .* b;
    x = x(1:newSize(1), 1:newSize(2));
    
    warning('Input matrix has a size which is not an integer multiple of the binning size. Input matrix has been cropped to match.');
end

newSize = size(x) ./ b;

% r = 1:size(x, 1);
% c = 1:size(x, 2);
% 
% [R, C] = meshgrid(r, c)

k = ones(b);
y = conv2(x, k);
y = y(b(1):b(1):end, b(2):b(2):end);

end
