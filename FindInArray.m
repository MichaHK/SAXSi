function [indexes] = FindInArray(a, k, afterIndex)
indexes = find(a);

if (exist('afterIndex', 'var') && isscalar(afterIndex))
    
    if (afterIndex < 0)
        indexes = indexes(indexes < -afterIndex);
        indexes = indexes(end:-1:1);
    else
        indexes = indexes(indexes > afterIndex);
    end
end

if (exist('k', 'var') && isscalar(k) && numel(indexes) > k)
    indexes = indexes(1:k);
end

end
