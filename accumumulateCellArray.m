function [c] = accumumulateCellArray(subs, val, sz)

if (~exist('sz', 'var'))
    sz = [];
end

if (~isempty(sz))
    c = cell(sz);
else
    c = {};
end

switch (size(subs, 2))
    case 1
        arrayfun(@(row)Set1(subs(row), val(row)), 1:size(subs, 1));
        
    case 2
        arrayfun(@(row)Set2(subs(row, :), val(row)), 1:size(subs, 1));

    otherwise
        error('more than 2 dimensions are not supported');
end

1;

    function [v] = Set1(i, v)
        if (numel(c) < i)
            c{i} = [];
        end
        
        c{i}(end + 1) = v;
    end

    function [v] = Set2(i, v)
        if (any(size(c) < i))
            c{i(1), i(2)} = [];
        end
        
        c{i(1), i(2)}(end + 1) = v;
    end


end
